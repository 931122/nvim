local function CompileRunGccInTerminal()
	vim.cmd("write") -- 保存当前文件

	local ft = vim.bo.filetype
	local filename = vim.fn.expand("%")
	local filename_no_ext = vim.fn.expand("%:r")

	-- 构造命令
	local cmd = ""
	if ft == "c" then
		cmd = string.format(
			[[echo "▶ gcc %s -o %s"; gcc %s -o %s && echo "▶ ./%s"; ./%s]],
			filename, filename_no_ext, filename, filename_no_ext, filename_no_ext, filename_no_ext
		)
	elseif ft == "cpp" then
		cmd = string.format(
			[[echo "▶ g++ %s -o %s --std=c++11"; g++ %s -o %s --std=c++11 && echo "▶ ./%s"; ./%s]],
			filename, filename_no_ext, filename, filename_no_ext, filename_no_ext, filename_no_ext
		)
	elseif ft == "sh" then
		cmd = string.format(
			[[echo "▶ ./%s"; chmod +x %s; ./%s]],
			filename, filename, filename
		)
	else
		vim.notify("不支持的文件类型: " .. ft, vim.log.levels.WARN)
		return
	end

	-- 保存当前窗口编号（代码窗口）
	local code_win = vim.api.nvim_get_current_win()

	-- 在底部新建一个 terminal buffer
	vim.cmd("botright new")           -- 打开新空窗口
	vim.cmd("resize 15")              -- 设置高度
	local term_buf = vim.api.nvim_create_buf(false, true) -- 创建不可写的临时 buffer
	vim.api.nvim_win_set_buf(0, term_buf)                 -- 设置 buffer 到新窗口

	-- 启动终端
	vim.fn.termopen({ "/bin/bash", "-c", cmd })

	-- 回到原来的代码窗口
	vim.api.nvim_set_current_win(code_win)
end

vim.keymap.set("n", "<leader><F5>", CompileRunGccInTerminal, { noremap = true, silent = true })
