-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

map("n", "q", ":q<ENTER>")
map("n", "Q", ":q<ENTER>")
map("n", "wq", ":wq<ENTER>")
-- keymap.set("n", "<C-k>", "<C-w>k")
-- keymap.set("n", "<C-j>", "<C-w>j")
-- keymap.set("n", "<C-h>", "<C-w>h")
-- keymap.set("n", "<C-l>", "<C-w>l")

--#region
map("i", "<C-a>", "<Home>")
map("i", "<C-e>", "<End>")
map("i", "<C-b>", "<Left>")
map("i", "<C-f>", "<Right>")
map("i", "<C-n>", "<Down>")
map("i", "<C-p>", "<Up>")

map("n", "<C-n>", ":bnext<CR>")
map("n", "<C-p>", ":bprevious<CR>")
map("n", "<leader>N", ":NvimTreeToggle<CR>")

map('n', '<leader>fw',
  function()
		local word = vim.fn.expand("<cword>")
		require('telescope.builtin').live_grep({ default_text = word })
  end,
{ noremap = true, silent = true, desc = "Telescope live_grep" })
-- 删除行尾空格和 \r
map("n", "<F12>", function()
  local search_backup = vim.fn.getreg("/")         -- 保存当前搜索内容
  vim.cmd([[%s/\s\+\r\?$//e]])                      -- 删除行尾空格 + 可选 \r
  vim.fn.setreg("/", search_backup)                -- 恢复搜索内容
  vim.cmd("nohlsearch")                            -- 取消搜索高亮
end, { silent = true, desc = "del space \\r" })

map("n", "<leader>fm", function()
  local word = vim.fn.expand("<cword>")
  vim.cmd("Man " .. word)
end, { desc = "Open man page for word under cursor" })


















-- del keymaps
