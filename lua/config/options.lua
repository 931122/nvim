-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.number = true           -- 显示行号
vim.opt.relativenumber = false  -- 相对行号
vim.opt.autoindent = true       -- 自动缩进
vim.opt.mouse = ''              -- 启用鼠标支持
vim.opt.ignorecase = true       -- 搜索忽略大小写
vim.opt.smartcase = true        -- 智能大小写搜索
vim.opt.termguicolors = true    -- 启用真彩色
vim.opt.wrap = false            -- 不自动换行
vim.opt.cursorline = true       -- 光标行
vim.opt.colorcolumn = "120"     -- 右侧边界线

vim.b.autoformat = false
vim.opt.expandtab = false
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.g.lazyvim_picker = "telescope"

vim.g.mapleader = ","
vim.g.maplocalleader = ","
vim.opt.relativenumber = false
vim.g.autoformat = false
vim.opt.undofile = false
vim.opt.list = false
vim.opt.hidden = true
