local nav_utils = require("tools.nav_utils")

local M = {}

function M.push_tagstack(tagname)
  local from = { vim.fn.bufnr("%"), vim.fn.line("."), vim.fn.col("."), 0 }
  local items = { { tagname = tagname or vim.fn.expand("<cword>"), from = from } }
  local stack = vim.fn.gettagstack()
  local last = stack.items[stack.curidx - 1]

  if last and last.tagname == items[1].tagname and last.from[1] == from[1] and last.from[2] == from[2] then
    return
  end

  vim.fn.settagstack(vim.fn.win_getid(), { items = items }, "t")
end

function M.notify_no_results(source, word)
  vim.notify(source .. ": no results for '" .. word .. "'", vim.log.levels.INFO)
end

function M.make_file_previewer(opts)
  local previewers = require("telescope.previewers")
  local putils = require("telescope.previewers.utils")
  local conf = require("telescope.config").values

  return previewers.new_buffer_previewer({
    title = opts.title,
    define_preview = function(self, entry)
      if not entry or not entry.filename or entry.filename == "" then
        return
      end

      local filepath = entry.filename
      local ft = vim.filetype.match({ filename = filepath }) or ""
      conf.buffer_previewer_maker(filepath, self.state.bufnr, {
        bufname = self.state.bufname,
        winid = self.state.winid,
        callback = function(preview_bufnr)
          nav_utils.configure_preview_buffer(preview_bufnr, ft)
          putils.highlighter(preview_bufnr, ft)

          local target = opts.resolve_line and opts.resolve_line(entry, self.state.winid, preview_bufnr, filepath) or entry.lnum or 1
          nav_utils.focus_preview_line(self.state.winid, preview_bufnr, opts.namespace, opts.highlight, target)
        end,
      })
    end,
  })
end

function M.open_entry(entry, opts)
  if not entry or not entry.filename or entry.filename == "" then
    return
  end

  local target_file = vim.fn.fnamemodify(entry.filename, ":p")
  local current_file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p")

  if opts and opts.push_tagstack then
    local tagname = type(opts.tagname) == "function" and opts.tagname(entry) or opts.tagname
    M.push_tagstack(tagname)
  end

  if current_file ~= target_file then
    vim.cmd("edit " .. vim.fn.fnameescape(target_file))
  end
  vim.schedule(function()
    local target = opts and opts.resolve_line and opts.resolve_line(entry) or entry.lnum or 1
    local total = math.max(vim.api.nvim_buf_line_count(0), 1)
    target = math.min(math.max(target, 1), total)
    vim.api.nvim_win_set_cursor(0, { target, 0 })
    vim.cmd("normal! zz")
  end)
end

function M.attach_open(modes, opts)
  return function(prompt_bufnr, map)
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")

    local function open()
      local entry = state.get_selected_entry()
      actions.close(prompt_bufnr)
      M.open_entry(entry, opts)
    end

    for _, mode in ipairs(modes or { "i" }) do
      map(mode, "<CR>", open)
    end
    return true
  end
end

return M
