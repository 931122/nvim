-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "c", "cpp", "md", "txt", "c.snippets", "cpp.snippets" },
	callback = function()
		vim.b.autoformat = false
		vim.opt_local.expandtab = false
		vim.opt_local.tabstop = 6
		vim.opt_local.shiftwidth = 6
		vim.opt_local.softtabstop = 6
	end,
})

-- format code
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	pattern = { "*.c", "*.cc", "*.cpp", "*.h", "*.hpp" },
	callback = function()
		vim.keymap.set('n', '<F4>', function()
			local filepath = vim.fn.expand('%:p')
			vim.cmd('write')
			vim.fn.system({ 'astyle',
			'--style=linux', '-p','--indent=tab', '--break-blocks=all',
			'--indent-switches', '--pad-oper', '--pad-comma', '--pad-header',
			'--suffix=none', '--align-pointer=name',
			'--align-reference=name', '--break-one-line-headers',
			'--attach-return-type', '--attach-return-type-decl', filepath })
			vim.cmd('edit')
		end, { buffer = true, desc = 'Format with astyle (F4)' })
	end,
})
