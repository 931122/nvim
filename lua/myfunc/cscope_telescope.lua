local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local putils = require("telescope.previewers.utils")
local conf = require("telescope.config").values
local nav_utils = require("tools.nav_utils")
local preview_ns = vim.api.nvim_create_namespace("CscopeTelescopePreview")
local M = {}

local function find_cscope_db()
  local start = vim.fn.expand("%:p:h")
  local found = vim.fs.find("cscope.out", {
    upward = true,
    stop = vim.loop.os_homedir(),
    path = start,
  })[1]
  return found and vim.fn.fnamemodify(found, ":p") or nil
end

local function run_cscope(mode, word)
  if vim.fn.executable("cscope") ~= 1 then
    vim.notify("cscope 不在 PATH 中", vim.log.levels.ERROR)
    return {}
  end

  local db = find_cscope_db()
  if not db then
    vim.notify("未找到 cscope.out", vim.log.levels.WARN)
    return {}
  end

  local result = vim.system({
    "cscope",
    "-d",
    "-f",
    db,
    "-L",
    "-" .. mode,
    word,
  }, { text = true }):wait()

  if result.code ~= 0 then
    local msg = result.stderr ~= "" and result.stderr or result.stdout
    if msg and msg ~= "" then
      vim.notify("cscope 执行失败\n" .. msg, vim.log.levels.ERROR)
    end
    return {}
  end
  return vim.split(result.stdout or "", "\n", { trimempty = true })
end

local function parse_cscope_line(line)
  local file, func, lnum, text = line:match("^(%S+)%s+(%S+)%s+(%d+)%s+(.*)$")
  if not file then
    return nil
  end
  return {
    filename = vim.fn.fnamemodify(file, ":p"),
    shortname = nav_utils.shorten_path(vim.fn.fnamemodify(file, ":p")),
    funcname = func,
    lnum = tonumber(lnum) or 1,
    text = text or "",
  }
end

local function open_picker(title, mode)
  local word = vim.fn.expand("<cword>")
  if word == nil or word == "" then
    return
  end

  local results = run_cscope(mode, word)
  if #results == 0 then
    vim.notify("cscope: no results for '" .. word .. "'", vim.log.levels.INFO)
    return
  end

  pickers.new({}, {
    prompt_title = title .. " for '" .. word .. "'",
    finder = finders.new_table({
      results = results,
      entry_maker = function(entry)
        local item = parse_cscope_line(entry)
        if not item then
          return nil
        end
        local display = string.format("%s:%d [%s] %s", item.shortname, item.lnum, item.funcname, item.text)
        return {
          value = entry,
          display = display,
          ordinal = table.concat({ item.filename, item.funcname, item.text }, " "),
          filename = item.filename,
          lnum = item.lnum,
        }
      end,
    }),
    previewer = previewers.new_buffer_previewer({
      title = "Call Preview",
      define_preview = function(self, entry)
        if not entry or not entry.filename then
          return
        end

        local bufnr = self.state.bufnr
        local filepath = entry.filename
        local ft = vim.filetype.match({ filename = filepath }) or ""
        conf.buffer_previewer_maker(filepath, bufnr, {
          bufname = self.state.bufname,
          winid = self.state.winid,
          callback = function(preview_bufnr)
            nav_utils.configure_preview_buffer(preview_bufnr, ft)
            putils.highlighter(preview_bufnr, ft)

            local line_count = math.max(vim.api.nvim_buf_line_count(preview_bufnr), 1)
            local target = math.min(math.max(entry.lnum or 1, 1), line_count)
            nav_utils.focus_preview_line(self.state.winid, preview_bufnr, preview_ns, "CscopePreviewLine", target)
          end,
        })
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(_, map)
      map("i", "<CR>", function(prompt_bufnr)
        local actions = require("telescope.actions")
        local state = require("telescope.actions.state")
        local entry = state.get_selected_entry()
        actions.close(prompt_bufnr)

        if not entry or not entry.filename then
          return
        end

        vim.cmd("edit " .. vim.fn.fnameescape(entry.filename))
        vim.schedule(function()
          local total = vim.api.nvim_buf_line_count(0)
          vim.api.nvim_win_set_cursor(0, { math.min(entry.lnum or 1, total), 0 })
          vim.cmd("normal! zz")
        end)
      end)
      return true
    end,
  }):find()
end

function M.find_callers()
  open_picker("Function Callers", "3")
end

function M.find_callees()
  open_picker("Function Callees", "2")
end

nav_utils.ensure_preview_highlight("CscopePreviewLine", { bg = "#7f1d1d", fg = "#ffffff", bold = true })
vim.keymap.set("n", "<leader>fc", M.find_callers, { desc = "Find function callers" })
vim.keymap.set("n", "<leader>fC", M.find_callees, { desc = "Find function callees" })

return M
