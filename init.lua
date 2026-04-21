-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
for _, file in ipairs(vim.fn.sort(vim.fn.globpath(vim.fn.stdpath("config") .. "/vimrc", "**/*.vim", false, true))) do
  vim.cmd.source(vim.fn.fnameescape(file))
end
