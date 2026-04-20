local M = {}

function M.shorten_path(path)
  local cwd = vim.loop.cwd()
  local rel = vim.fn.fnamemodify(path, ":.")
  if rel ~= path then
    return rel
  end
  if path:sub(1, #cwd) == cwd then
    return path:sub(#cwd + 2)
  end
  return vim.fn.pathshorten(path)
end

function M.ensure_preview_highlight(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

function M.configure_preview_buffer(bufnr, ft)
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].syntax = ft
end

function M.focus_preview_line(winid, bufnr, ns, hl_group, target)
  local line_count = math.max(vim.api.nvim_buf_line_count(bufnr), 1)
  local line = math.min(math.max(target or 1, 1), line_count)

  vim.wo[winid].cursorline = true
  vim.wo[winid].wrap = false
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
    line_hl_group = hl_group,
  })

  vim.api.nvim_win_call(winid, function()
    pcall(vim.api.nvim_win_set_cursor, 0, { line, 0 })
    vim.cmd("silent! normal! zz")
  end)
end

return M
