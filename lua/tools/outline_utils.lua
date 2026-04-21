local uv = vim.uv or vim.loop

local M = {}

function M.is_stale_outline_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end

  local name = vim.api.nvim_buf_get_name(buf)
  local basename = vim.fn.fnamemodify(name, ":t")

  if not basename:match("^OUTLINE_%d+$") then
    return false
  end

  if vim.bo[buf].filetype == "Outline" or vim.bo[buf].buftype ~= "" then
    return false
  end

  return name ~= "" and uv.fs_stat(name) == nil
end

function M.cleanup_stale_outline_buffers()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if M.is_stale_outline_buffer(buf) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end
end

return M
