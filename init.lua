-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
for _, file in ipairs(vim.fn.glob(vim.fn.stdpath("config").."/lua/myfunc/*.lua", 0, 1)) do
  local mod = file:match("lua/(.+)%.lua$")
  require(mod)
end
vim.cmd('source ~/.config/nvim/vimrc.vim')
