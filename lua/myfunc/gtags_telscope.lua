local M = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local conf = require("telescope.config").values

local function shorten_path(path)
	local cwd = vim.loop.cwd()
	local rel = vim.fn.fnamemodify(path, ":.")
	if rel ~= path then
		return rel
	end
	if path:sub(1, #cwd) == cwd then
		return path:sub(#cwd + 2)
	end
	return vim.fn.pathshorten(path)
end

-- 运行 global 命令
local function run_global_cmd(mode, word)
	if vim.fn.executable("global") ~= 1 then
		vim.notify("global 不在 PATH 中", vim.log.levels.ERROR)
		return {}
	end
	local handle = io.popen("global " .. mode .. " " .. vim.fn.shellescape(word))
	if not handle then return {} end
	local result = handle:read("*a")
	handle:close()
	return vim.split(result, "\n", { trimempty = true })
end

-- 提取文件路径与行号
local function parse_global_line(line)
	-- 去除行首的 '>' 和额外的空格
	line = line:gsub("^>%s*", "")

	local parts = vim.split(line, "%s+")
	if #parts < 2 then return nil, nil end
	local line_num, file = tonumber(parts[2]), parts[3]
	return file, line_num
end

-- 自动选择预览器：bat 或 cat
local function get_previewer_cmd(entry)
	local has_bat = vim.fn.executable("bat") == 1
	local lnum = tonumber(entry.lnum or 1)  -- 如果 lnum 是 nil，默认用 1

	local context = 15
	local start_line = math.max(lnum - context, 1)
	local end_line = lnum + context
	local filepath = entry.filename

	if has_bat then
		return {
			"bat",
			"--style=plain",
			"--color=always",
			"--highlight-line=" .. lnum,
			"--line-range=" .. start_line .. ":" .. end_line,
			filepath,
		}
	else
		return {
			"sh",
			"-c",
			string.format(
			"sed -n '%d,%dp' %s | nl -ba -nln -v %d",
			start_line,
			end_line,
			vim.fn.shellescape(filepath),
			start_line
			)
		}
	end
end

-- 核心 picker 函数
function M.gtags_picker(title, mode)
	local word = vim.fn.expand("<cword>")
	M.gtags_picker_for_word(title, mode, word)
end

function M.gtags_picker_for_word(title, mode, word)
	if not word or word == "" then
		return
	end
	local results = run_global_cmd(mode, word)

	if #results == 0 then
		vim.notify("Global: no results for '" .. word .. "'", vim.log.levels.INFO)
		return
	end

	pickers.new({}, {
		prompt_title = title .. " for '" .. word .. "'",
		finder = finders.new_table {
			results = results,
			entry_maker = function(entry)
				local file, lnum = parse_global_line(entry)
				local path = file and vim.fn.fnamemodify(file, ":p") or nil
				local short = path and shorten_path(path) or entry
				return {
					value = entry,
					display = string.format("%s:%d %s", short, lnum or 1, entry),
					ordinal = entry,
					filename = path,
					lnum = lnum or 1,
				}
			end,
		},
		previewer = previewers.new_termopen_previewer {
			get_command = get_previewer_cmd,
		},
		sorter = conf.generic_sorter({}),
		attach_mappings = function(_, map)
			map("i", "<CR>", function(prompt_bufnr)
				local actions = require("telescope.actions")
				local state = require("telescope.actions.state")
				local entry = state.get_selected_entry()
				actions.close(prompt_bufnr)

				if not entry or not entry.filename then return end
				vim.cmd("edit " .. entry.filename)

				vim.schedule(function()
					local bufnr = vim.api.nvim_get_current_buf()
					local total_lines = vim.api.nvim_buf_line_count(bufnr)
					local target_line = math.min(entry.lnum or 1, total_lines)
					vim.api.nvim_win_set_cursor(0, { target_line, 0 })
				end)
			end)
			return true
		end,
	}):find()
end

function M.jump_to_definition(word)
	if not word or word == "" then
		return false
	end

	local results = run_global_cmd("-x", word)
	if #results == 0 then
		return false
	end

	if #results == 1 then
		local file, lnum = parse_global_line(results[1])
		if not file then
			return false
		end
		local path = vim.fn.fnamemodify(file, ":p")
		vim.cmd("edit " .. vim.fn.fnameescape(path))
		vim.schedule(function()
			local total = vim.api.nvim_buf_line_count(0)
			vim.api.nvim_win_set_cursor(0, { math.min(lnum or 1, total), 0 })
			vim.cmd("normal! zz")
		end)
	else
		M.gtags_picker_for_word("Global Definitions", "-x", word)
	end

	return true
end

function M.build_database()
	if vim.fn.executable("gtags") ~= 1 then
		vim.notify("gtags 不在 PATH 中", vim.log.levels.ERROR)
		return
	end

	local root = vim.loop.cwd()
	vim.notify("Generating GTAGS: " .. root, vim.log.levels.INFO)
	vim.system({ "gtags" }, { cwd = root, text = true }, function(result)
		vim.schedule(function()
			if result.code == 0 then
				vim.notify("GTAGS 已生成: " .. root, vim.log.levels.INFO)
			else
				local msg = result.stderr ~= "" and result.stderr or result.stdout
				vim.notify("gtags 生成失败\n" .. msg, vim.log.levels.ERROR)
			end
		end)
	end)
end


-- 快捷键注册
function M.setup_keymaps()
	vim.keymap.set("n", "<leader>]", function()
		M.gtags_picker("Global Definitions", "-x")
	end, { desc = "Gtags: 查找定义" })

	vim.keymap.set("n", "<leader>r", function()
		M.gtags_picker("Global References", "-r")
	end, { desc = "Gtags: 查找引用" })

	vim.keymap.set("n", "<leader>gb", M.build_database, { desc = "Build GTAGS" })
end

-- 初始化（自动注册按键）
M.setup_keymaps()
return M

