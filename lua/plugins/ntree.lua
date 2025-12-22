return {
	{
		"nvim-tree/nvim-tree.lua",
		dependencies = { "nvim-tree/nvim-web-devicons" }, -- 图标支持
		config = function()
			-- 禁用 netrw
			vim.g.loaded_netrw = 1
			vim.g.loaded_netrwPlugin = 1

			local nvim_tree = require("nvim-tree")

			nvim_tree.setup({
				git = {
					enable = true,
				},
				sort = {
					sorter = "case_sensitive",
				},
				view = {
					side = "right",
					width = 30,
				},
				renderer = {
					group_empty = true,
				},
				filters = {
					dotfiles = true,
				},
				on_attach = function(bufnr)
					local api = require("nvim-tree.api")

					local function opts(desc)
						return {
							desc = "nvim-tree: " .. desc,
							buffer = bufnr,
							noremap = true,
							silent = true,
							nowait = true,
						}
					end

					-- 默认快捷键
					api.config.mappings.default_on_attach(bufnr)

					-- 自定义快捷键
					vim.keymap.set('n', 's', api.node.open.horizontal_no_picker, opts('Open: Horizontal Split'))
					vim.keymap.set('n', 'v', api.node.open.vertical_no_picker, opts('Open: Vertical Split'))
					vim.keymap.set('n', '<CR>', api.node.open.edit, opts('Open: Edit'))

					vim.keymap.set("n", "<leader>N", ":NvimTreeToggle<CR>")
				end,
			})
		end,
	},
}

