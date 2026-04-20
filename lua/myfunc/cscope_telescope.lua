local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local nav_utils = require("tools.nav_utils")
local telescope_utils = require("tools.telescope_utils")
local preview_ns = vim.api.nvim_create_namespace("CscopeTelescopePreview")
local M = {}

local function find_cscope_db()
  local start = vim.fn.expand("%:p:h")
  local found = vim.fs.find("cscope.out", {
    upward = true,
    stop = vim.loop.os_homedir(),
    path = start,
  })[1]
  return found and vim.fn.fnamemodify(found, ":p") or nil
end

local function run_cscope(mode, word)
  if vim.fn.executable("cscope") ~= 1 then
    vim.notify("cscope 不在 PATH 中", vim.log.levels.ERROR)
    return {}
  end

  local db = find_cscope_db()
  if not db then
    vim.notify("未找到 cscope.out", vim.log.levels.WARN)
    return {}
  end

  local result = vim.system({
    "cscope",
    "-d",
    "-f",
    db,
    "-L",
    "-" .. mode,
    word,
  }, { text = true }):wait()

  if result.code ~= 0 then
    local msg = result.stderr ~= "" and result.stderr or result.stdout
    if msg and msg ~= "" then
      vim.notify("cscope 执行失败\n" .. msg, vim.log.levels.ERROR)
    end
    return {}
  end
  return vim.split(result.stdout or "", "\n", { trimempty = true })
end

local function parse_cscope_line(line)
  local file, func, lnum, text = line:match("^(%S+)%s+(%S+)%s+(%d+)%s+(.*)$")
  if not file then
    return nil
  end
  return {
    filename = vim.fn.fnamemodify(file, ":p"),
    shortname = nav_utils.shorten_path(vim.fn.fnamemodify(file, ":p")),
    funcname = func,
    lnum = tonumber(lnum) or 1,
    text = text or "",
  }
end

local function open_picker(title, mode)
  local word = vim.fn.expand("<cword>")
  if word == nil or word == "" then
    return
  end

  local results = run_cscope(mode, word)
  if #results == 0 then
    telescope_utils.notify_no_results("cscope", word)
    return
  end

  pickers.new({}, {
    cache_picker = false,
    prompt_title = title .. " for '" .. word .. "'",
    finder = finders.new_table({
      results = results,
      entry_maker = function(entry)
        local item = parse_cscope_line(entry)
        if not item then
          return nil
        end
        local display = string.format("%s:%d [%s] %s", item.shortname, item.lnum, item.funcname, item.text)
        return {
          value = entry,
          display = display,
          ordinal = table.concat({ item.filename, item.funcname, item.text }, " "),
          filename = item.filename,
          lnum = item.lnum,
        }
      end,
    }),
    previewer = telescope_utils.make_file_previewer({
      title = "Call Preview",
      namespace = preview_ns,
      highlight = "CscopePreviewLine",
      resolve_line = function(entry)
        return entry.lnum or 1
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = telescope_utils.attach_open({ "i" }),
  }):find()
end

function M.find_callers()
  open_picker("Function Callers", "3")
end

function M.find_callees()
  open_picker("Function Callees", "2")
end

nav_utils.ensure_preview_highlight("CscopePreviewLine", { bg = "#7f1d1d", fg = "#ffffff", bold = true })
vim.keymap.set("n", "<leader>fc", M.find_callers, { desc = "Find function callers" })
vim.keymap.set("n", "<leader>fC", M.find_callees, { desc = "Find function callees" })

return M
