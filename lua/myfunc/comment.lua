-- 可扩展单行行尾注释快捷键，行尾加 Tab 缩进
local comment_map = {
	c = "/*  */",
	cpp = "/*  */",
	python = "# ",
	sh = "# ",
	bash = "# ",
	zsh = "# ",
	lua = "--",
	go = "// ",
	rust = "// ",
}

-- 判断行是否已有注释
local function has_comment(line, comment_str)
	comment_str = vim.pesc(comment_str:match("%S+")) -- 只匹配非空字符
	return line:match(comment_str .. "$") ~= nil
end

-- 行尾追加注释（带 Tab 缩进）
local function add_line_comment()
	local ft = vim.bo.filetype
	local line = vim.api.nvim_get_current_line()
	local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
	local comment = comment_map[ft]

	if comment then
		if comment:match("/%*.-%*/") then
			-- C/C++ 风格 /* */
			if not line:match("/%*.-%*/") then
				local new = line .. "\t" .. comment
				vim.api.nvim_set_current_line(new)
				vim.api.nvim_win_set_cursor(0, { row, #line + 4 })
				vim.cmd("startinsert")
			end
		else
			-- 单行注释
			if not has_comment(line, comment) then
				local new = line .. "\t" .. comment .. ' '
				vim.api.nvim_set_current_line(new)
				vim.api.nvim_win_set_cursor(0, { row, #line + #comment + 2 })
				vim.cmd("startinsert!")
			end
		end
	else
		-- fallback 使用 commentstring
		local cs = vim.bo.commentstring or "// %s"
		cs = cs:gsub("%%s", "")
		if not has_comment(line, cs) then
			local new = line .. "\t" .. cs
			vim.api.nvim_set_current_line(new)
			vim.api.nvim_win_set_cursor(0, { row, #line + #cs + 1 })
			vim.cmd("startinsert")
		end
	end
end

-- 在当前行上方插入注释行（缩进与当前行一致）
local function insert_comment_above()
	local ft = vim.bo.filetype
	local comment = comment_map[ft] or vim.bo.commentstring or "// %s"
	comment = comment:gsub("%%s", "")

	local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
	local current_line = vim.api.nvim_get_current_line()
	-- 获取当前行缩进
	local indent = current_line:match("^%s*") or ""
	local new_line = indent .. comment
	if ft ~= "c" and ft ~= "cpp" then
		new_line = indent .. comment .. " "

	end
	vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, { new_line })
	local col = #new_line
	if ft == "c" or ft == "cpp" then
		col = col -3
	end
	vim.api.nvim_win_set_cursor(0, { row, col }) -- 光标放到注释符后
	vim.cmd("startinsert")
end

-- 快捷键绑定
vim.keymap.set("n", "<leader>;", add_line_comment, { noremap = true, silent = true, desc = "行尾追加注释" })
vim.keymap.set("n", "<leader>O", insert_comment_above, { noremap = true, silent = true, desc = "在当前行上方插入注释" })
