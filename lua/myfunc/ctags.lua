local M = {}
local nav_utils = require("tools.nav_utils")
local default_excludes = {
  ".git",
  ".hg",
  ".svn",
  ".idea",
  ".vscode",
  "build",
  "cmake-build-*",
  "out",
  "dist",
  "node_modules",
  "__pycache__",
  ".venv",
}
local refresh_group = vim.api.nvim_create_augroup("LocalCtags", { clear = true })
local refresh_timer = nil
local tag_preview_ns = vim.api.nvim_create_namespace("TagTelescopePreview")
local source_patterns = {
  "*.c",
  "*.cc",
  "*.cpp",
  "*.cxx",
  "*.h",
  "*.hpp",
  "*.hh",
  "*.lua",
  "*.py",
  "*.go",
  "*.rs",
  "*.java",
  "*.js",
  "*.ts",
}

nav_utils.ensure_preview_highlight("TagPreviewLine", { bg = "#7f1d1d", fg = "#ffffff", bold = true })

local function find_ctags()
  if vim.fn.executable("ctags") == 1 then
    return "ctags"
  end
  if vim.fn.executable("uctags") == 1 then
    return "uctags"
  end
  return nil
end

local function project_root()
  local markers = { ".git", ".hg", ".svn", "compile_commands.json", "Makefile", "tags" }
  local found = vim.fs.find(markers, { upward = true, stop = vim.loop.os_homedir(), path = vim.fn.expand("%:p:h") })[1]
  if found then
    return vim.fs.dirname(found)
  end
  return vim.loop.cwd()
end

local function tagfile(root)
  return root .. "/tags"
end

local function current_tagfile(root)
  return root .. "/.tags.current"
end

local function has_tagfile(root)
  return vim.fn.filereadable(tagfile(root)) == 1
end

local function ensure_tag_path(tags)
  local escaped = vim.fn.fnameescape(tags)
  if not vim.tbl_contains(vim.opt.tags:get(), tags) then
    vim.cmd("set tags^=" .. escaped)
  end
end

local function build_base_cmd(root)
  local ctags = find_ctags()
  if not ctags then
    return nil, "ctags 不在 PATH 中"
  end

  local cmd = {
    ctags,
    "--fields=+iaS",
    "--extras=+q",
    "-f",
    tagfile(root),
  }

  for _, pattern in ipairs(default_excludes) do
    table.insert(cmd, "--exclude=" .. pattern)
  end

  return cmd
end

local function run_system_ctags(cmd, target)
  vim.notify("Generating tags: " .. target, vim.log.levels.INFO)
  vim.system(cmd, { text = true }, function(result)
    vim.schedule(function()
      if result.code == 0 then
        ensure_tag_path(target)
        vim.notify("tags 已生成: " .. target, vim.log.levels.INFO)
      else
        local msg = result.stderr ~= "" and result.stderr or result.stdout
        vim.notify("ctags 生成失败\n" .. msg, vim.log.levels.ERROR)
      end
    end)
  end)
end

local function run_ctags()
  local root = project_root()
  local cmd, err = build_base_cmd(root)
  if not cmd then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  table.insert(cmd, "-R")
  table.insert(cmd, root)
  run_system_ctags(cmd, tagfile(root))
end

local function run_ctags_current()
  local file = vim.fn.expand("%:p")
  if file == "" then
    vim.notify("当前 buffer 没有对应文件", vim.log.levels.WARN)
    return
  end

  local root = project_root()
  local cmd, err = build_base_cmd(root)
  if not cmd then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  cmd[5] = current_tagfile(root)
  table.insert(cmd, file)
  run_system_ctags(cmd, current_tagfile(root))
end

local function detect_tags_for_current_buffer()
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then
    return
  end

  local dir = vim.fs.dirname(name)
  local found = vim.fs.find({ "tags", "TAGS" }, {
    upward = true,
    stop = vim.loop.os_homedir(),
    path = dir,
  })[1]

  if found then
    local tags = vim.fn.fnamemodify(found, ":p")
    ensure_tag_path(tags)
  end
end

local function schedule_refresh_current()
  local root = project_root()
  if not has_tagfile(root) then
    return
  end

  if refresh_timer then
    refresh_timer:stop()
    refresh_timer:close()
  end

  refresh_timer = vim.uv.new_timer()
  refresh_timer:start(150, 0, function()
    refresh_timer:stop()
    refresh_timer:close()
    refresh_timer = nil
    vim.schedule(run_ctags)
  end)
end

local function tag_fallback_lnum(tag)
  local ex_cmd = tag.cmd
  if type(ex_cmd) == "number" then
    return ex_cmd
  end
  if type(ex_cmd) ~= "string" then
    return 1
  end

  local trimmed = ex_cmd:gsub("^/", ""):gsub("/;\"?$", "")
  local num = tonumber(trimmed:match("^(%d+)$"))
  if num then
    return num
  end
  return 1
end

local function locate_tag_in_window(tag, winid, fallback)
  local ex_cmd = tag and tag.cmd
  if type(ex_cmd) == "number" then
    return ex_cmd
  end
  if type(ex_cmd) == "string" and ex_cmd ~= "" then
    local pattern = ex_cmd:match("^/(.*)/;\"$")
    if pattern and pattern ~= "" then
      pattern = pattern:gsub("\\/", "/")
      pattern = pattern:gsub("^%^", "")
      pattern = pattern:gsub("%$$", "")
      pattern = pattern:gsub("\\\\", "\\")

      local literal = vim.fn.escape(pattern, [[\]])
      literal = [[\V]] .. literal

      local ok, found = pcall(vim.api.nvim_win_call, winid, function()
        vim.fn.cursor(1, 1)
        return vim.fn.search(literal, "nW")
      end)

      if ok and type(found) == "number" and found > 0 then
        return found
      end
    end
  end

  local name = tag and tag.name or ""
  if name == "" then
    return fallback
  end

  local patterns = {}
  local escaped_name = vim.fn.escape(name, [[\]])
  local kind = tag.kind or ""
  if kind == "f" then
    patterns = {
      [[\C^\s*.*\<]] .. escaped_name .. [[\>\s*(]],
      [[\C\<]] .. escaped_name .. [[\>\s*(]],
    }
  elseif kind == "d" then
    patterns = {
      [[\C^\s*#\s*define\s\+]] .. escaped_name .. [[\>]],
      [[\C\<]] .. escaped_name .. [[\>]],
    }
  else
    patterns = {
      [[\C\<]] .. escaped_name .. [[\>]],
    }
  end

  for _, pattern in ipairs(patterns) do
    local ok, found = pcall(vim.api.nvim_win_call, winid, function()
      vim.fn.cursor(1, 1)
      return vim.fn.search(pattern, "nW")
    end)
    if ok and type(found) == "number" and found > 0 then
      return found
    end
  end

  return fallback
end

local function locate_tag_position(tag, filename, winid)
  local line_count = math.max(vim.api.nvim_buf_line_count(winid == 0 and 0 or vim.api.nvim_win_get_buf(winid)), 1)
  local fallback = math.min(math.max(tag_fallback_lnum(tag), 1), line_count)
  return math.min(math.max(locate_tag_in_window(tag, winid, fallback), 1), line_count)
end

local function telescope_select_tag()
  local ok, pickers = pcall(require, "telescope.pickers")
  local ok_finders, finders = pcall(require, "telescope.finders")
  local ok_conf, conf = pcall(require, "telescope.config")
  local ok_previewers, previewers = pcall(require, "telescope.previewers")
  local ok_putils, putils = pcall(require, "telescope.previewers.utils")
  local ok_actions, actions = pcall(require, "telescope.actions")
  local ok_state, action_state = pcall(require, "telescope.actions.state")
  if not (ok and ok_finders and ok_conf and ok_previewers and ok_putils and ok_actions and ok_state) then
    return select_tag()
  end

  local word = vim.fn.expand("<cword>")
  if word == nil or word == "" then
    return
  end

  local tags = vim.fn.taglist(word)
  if not tags or vim.tbl_isempty(tags) then
    vim.notify("没有找到 tag: " .. word, vim.log.levels.INFO)
    return
  end

  pickers.new({}, {
    prompt_title = "Tags: " .. word,
    finder = finders.new_table({
      results = tags,
      entry_maker = function(tag)
        local filename = vim.fn.fnamemodify(tag.filename or "", ":p")
        local shortname = nav_utils.shorten_path(filename)
        local lnum = tag_fallback_lnum(tag)
        local kind = tag.kind or ""
        local scope = tag.class or tag.struct or tag.namespace or tag.enum or ""
        local text = string.format("%s [%s] %s", tag.name or word, kind ~= "" and kind or "-", shortname)
        if scope ~= "" then
          text = text .. " :: " .. scope
        end
        return {
          value = tag,
          ordinal = table.concat({
            tag.name or "",
            filename,
            kind,
            scope,
          }, " "),
          display = text,
          filename = filename,
          lnum = lnum,
        }
      end,
    }),
    previewer = previewers.new_buffer_previewer({
      title = "Tag Preview",
      define_preview = function(self, entry)
        if entry.filename == "" then
          return
        end
        local bufnr = self.state.bufnr
        local filepath = entry.filename
        local ft = vim.filetype.match({ filename = filepath }) or ""
        conf.values.buffer_previewer_maker(filepath, bufnr, {
          bufname = self.state.bufname,
          winid = self.state.winid,
          callback = function(preview_bufnr)
            nav_utils.configure_preview_buffer(preview_bufnr, ft)
            putils.highlighter(preview_bufnr, ft)

            local target = locate_tag_position(entry.value, filepath, self.state.winid)
            nav_utils.focus_preview_line(self.state.winid, preview_bufnr, tag_preview_ns, "TagPreviewLine", target)
          end,
        })
      end,
    }),
    sorter = conf.values.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      local function open_tag()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if not entry or entry.filename == "" then
          return
        end
        vim.cmd("edit " .. vim.fn.fnameescape(entry.filename))
        local target = locate_tag_position(entry.value, entry.filename, 0)
        vim.api.nvim_win_set_cursor(0, { target, 0 })
        vim.cmd("normal! zz")
      end

      map("i", "<CR>", open_tag)
      map("n", "<CR>", open_tag)
      return true
    end,
  }):find()
end

local function select_tag()
  local word = vim.fn.expand("<cword>")
  if word == nil or word == "" then
    return
  end
  vim.cmd("tselect " .. vim.fn.fnameescape(word))
end

local function jump_tag()
  local word = vim.fn.expand("<cword>")
  if word == nil or word == "" then
    return
  end

  local tags = vim.fn.taglist(word)
  if tags and not vim.tbl_isempty(tags) then
    if #tags > 1 then
      telescope_select_tag()
      return
    end

    local ok = pcall(vim.cmd, "tag " .. vim.fn.fnameescape(word))
    if not ok then
      vim.cmd("tjump " .. vim.fn.fnameescape(word))
    end
    return
  end

  local ok, gtags = pcall(require, "myfunc.gtags_telscope")
  if ok and gtags.jump_to_definition and gtags.jump_to_definition(word) then
    return
  end

  vim.notify("没有找到 tag: " .. word, vim.log.levels.WARN)
end

local function inspect_tag()
  local word = vim.fn.expand("<cword>")
  if word == nil or word == "" then
    return
  end

  local tags = vim.fn.taglist(word)
  if not tags or vim.tbl_isempty(tags) then
    vim.notify("当前 tags 里没有: " .. word, vim.log.levels.INFO)
    return
  end

  local lines = {}
  for _, tag in ipairs(tags) do
    table.insert(lines, string.format("%s -> %s", tag.name or word, tag.filename or ""))
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Tag Inspect" })
end

vim.opt.tags:prepend({ "./tags;", "./TAGS;" })
vim.opt.tags:append({ "tags", "TAGS" })

vim.api.nvim_create_user_command("TagsBuild", run_ctags, {
  desc = "Generate project tags with ctags",
})

vim.api.nvim_create_user_command("TagsBuildCurrent", run_ctags_current, {
  desc = "Generate tags for current file",
})

vim.api.nvim_create_user_command("TagsSelect", select_tag, {
  desc = "Select tag matches for word under cursor",
})

vim.api.nvim_create_user_command("TagsPicker", telescope_select_tag, {
  desc = "Select tag with Telescope",
})

vim.api.nvim_create_user_command("TagsInspect", inspect_tag, {
  desc = "Inspect current word in tag files",
})

vim.keymap.set("n", "<leader>tb", run_ctags, { desc = "Build tags" })
vim.keymap.set("n", "<leader>tf", run_ctags_current, { desc = "Build tags for current file" })
vim.keymap.set("n", "<leader>ts", telescope_select_tag, { desc = "Select tag" })
vim.keymap.set("n", "<C-]>", jump_tag, { desc = "Jump tag" })
vim.keymap.set("n", "<leader>tn", "<cmd>tnext<CR>", { desc = "Next tag" })
vim.keymap.set("n", "<leader>tp", "<cmd>tprevious<CR>", { desc = "Previous tag" })

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  group = refresh_group,
  callback = detect_tags_for_current_buffer,
})

vim.api.nvim_create_autocmd("BufWritePost", {
  group = refresh_group,
  pattern = source_patterns,
  callback = schedule_refresh_current,
})

return M
