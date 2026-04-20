local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local nav_utils = require("tools.nav_utils")
local telescope_utils = require("tools.telescope_utils")
local conf = require("telescope.config")
local preview_ns = vim.api.nvim_create_namespace("GtagsTelescopePreview")
local M = {}

-- 运行 global 命令
local function run_global_cmd(mode, word)
	if vim.fn.executable("global") ~= 1 then
		vim.notify("global 不在 PATH 中", vim.log.levels.ERROR)
		return {}
	end
	local result = vim.system({ "global", mode, word }, { text = true }):wait()
	if result.code ~= 0 then
		local msg = result.stderr ~= "" and result.stderr or result.stdout
		if msg and msg ~= "" then
			vim.notify("global 执行失败\n" .. msg, vim.log.levels.ERROR)
		end
		return {}
	end
	return vim.split(result.stdout or "", "\n", { trimempty = true })
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
		telescope_utils.notify_no_results("Global", word)
		return
	end

	pickers.new({}, {
		cache_picker = false,
		prompt_title = title .. " for '" .. word .. "'",
		finder = finders.new_table {
			results = results,
			entry_maker = function(entry)
				local file, lnum = parse_global_line(entry)
				local path = file and vim.fn.fnamemodify(file, ":p") or nil
				local short = path and nav_utils.shorten_path(path) or entry
				return {
					value = entry,
					display = string.format("%s:%d %s", short, lnum or 1, entry),
					ordinal = entry,
					filename = path,
					lnum = lnum or 1,
				}
			end,
		},
		previewer = telescope_utils.make_file_previewer({
			title = "Global Preview",
			namespace = preview_ns,
			highlight = "GtagsPreviewLine",
			resolve_line = function(entry)
				return entry.lnum or 1
			end,
		}),
		sorter = conf.values.generic_sorter({}),
		attach_mappings = telescope_utils.attach_open({ "i" }, {
			push_tagstack = mode == "-x",
			tagname = word,
		}),
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
		telescope_utils.open_entry({
			filename = path,
			lnum = lnum or 1,
		}, {
			push_tagstack = true,
			tagname = word,
		})
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


nav_utils.ensure_preview_highlight("GtagsPreviewLine", { bg = "#7f1d1d", fg = "#ffffff", bold = true })

vim.keymap.set("n", "<leader>]", function()
	M.gtags_picker("Global Definitions", "-x")
end, { desc = "Gtags: 查找定义" })

vim.keymap.set("n", "<leader>r", function()
	M.gtags_picker("Global References", "-r")
end, { desc = "Gtags: 查找引用" })

vim.keymap.set("n", "<leader>gT", M.build_database, { desc = "Build GTAGS" })

return M
