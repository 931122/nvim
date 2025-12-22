return {
	"nmac427/guess-indent.nvim",
	config = function()
		require("guess-indent").setup({
			auto_cmd = true,        -- 打开文件时自动猜测
			override_editorconfig = false,  -- 不覆盖 .editorconfig
			filetype_exclude = { "help", "markdown", "text" },  -- 不检测的文件类型
			buftype_exclude = { "terminal", "nofile", "help", "prompt" },         -- 不检测的 buffer 类型
		})
	end
}
