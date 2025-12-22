-- 在 lazy.nvim 中配置 telescope 和 ui-select 扩展
return {
	"nvim-telescope/telescope.nvim",
	dependencies = {
		"nvim-telescope/telescope-ui-select.nvim",
	},
	config = function()
		require("telescope").setup {
			extensions = {
				["ui-select"] = {
					require("telescope.themes").get_dropdown {
					}
				}
			},
			defaults = {
				mappings = {
					i = {
						["<esc>"] = "close",  -- 关闭窗口
					},
					n = {
						["<esc>"] = "close",  -- 关闭窗口
					}
				},
			},
			pickers = {
				find_files = {
					-- theme = "ivy",
					hidden = true,  -- 显示隐藏文件
				},
				live_grep = {
					-- theme = "ivy",
				},
			},

		}
		require("telescope").load_extension("ui-select")
	end,
}
