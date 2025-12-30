-- logcat.lua
local M = {}

-- ==============================
-- 1️⃣ 高亮逻辑
-- ==============================
local function setup_logcat_highlight()
  -- 清理旧匹配
  if vim.b.logcat_matches then
    for _, id in ipairs(vim.b.logcat_matches) do
      vim.fn.matchdelete(id)
    end
  end
  vim.b.logcat_matches = {}

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- 高亮组
  hi("LogcatLevelE", { fg="#ffffff", bg="#f44747", bold=true })
  hi("LogcatLevelW", { fg="#000000", bg="#ffcc66", bold=true })
  hi("LogcatLevelI", { fg="#98c379", bold=true })
  hi("LogcatLevelD", { fg="#61afef" })
  hi("LogcatLevelV", { fg="#7f848e" })
  hi("LogcatLevelF", { fg="#ffffff", bg="#ff007c", bold=true })
  hi("LogcatErrorWord", { fg="#ffffff", bg="#f44747", bold=true })
  hi("LogcatTag", { fg="#c678dd", bold=true })
  hi("LogcatTime", { fg="#5c6370" })
  hi("LogcatPidTid", { fg="#61afef" })

  local function add(group, pat)
    table.insert(vim.b.logcat_matches, vim.fn.matchadd(group, pat))
  end

  -- 日志等级整行高亮
  add("LogcatLevelE", [[\v^\d\d-\d\d.*\sE\s.*$]])
  add("LogcatLevelW", [[\v^\d\d-\d\d.*\sW\s.*$]])
  add("LogcatLevelI", [[\v^\d\d-\d\d.*\sI\s.*$]])
  add("LogcatLevelD", [[\v^\d\d-\d\d.*\sD\s.*$]])
  add("LogcatLevelV", [[\v^\d\d-\d\d.*\sV\s.*$]])
  add("LogcatLevelF", [[\v^\d\d-\d\d.*\sF\s.*$]])

  -- 高频错误关键字
  add("LogcatErrorWord", [[\v<(error|crash|fail|exception|fatal|wtf|terriblefailure|sigsegv|anr)>]])

  -- Tag
  add("LogcatTag", [[\v\s[VDIWEF]\s\w+:]])

  -- 时间戳 & PID/TID
  add("LogcatTime", [[\v^\d\d-\d\d \d\d:\d\d:\d\d\.\d\d\d]])
  add("LogcatPidTid", [[\v^\d\d-\d\d.*\s\d+\s+\d+\s+\d+]])
end

-- ==============================
-- 2️⃣ 自动启用 logcat 高亮
-- ==============================
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  pattern = { "*.logcat", "*logcat*.log", "*logcat*.txt" },
  callback = setup_logcat_highlight,
})

-- ==============================
-- 3️⃣ 折叠同等级日志
-- ==============================
vim.api.nvim_create_autocmd("FileType", {
  pattern = "logcat",
  callback = function()
    vim.opt_local.foldmethod = "expr"
    vim.opt_local.foldexpr = [[getline(v:lnum)=~'^\d\d-\d\d.*\s[VDIWEF]\s' ? 1 : 0]]
    vim.opt_local.foldlevel = 99
  end
})

-- ==============================
-- 4️⃣ 日志过滤命令
-- ==============================
local function filter_logcat(level)
  level = level:upper()
  if not level:match("^[VDIWEF]$") then
    print("过滤失败：Level 必须是 V/D/I/W/E/F")
    return
  end
  -- 删除不匹配行
  vim.cmd(string.format([[silent! v/\v^\d\d-\d\d.*\s%s\s/d]], level))
end

vim.api.nvim_create_user_command("LogcatError", function() filter_logcat("E") end, {desc="只保留 E/ 日志"})
vim.api.nvim_create_user_command("LogcatWarn", function() filter_logcat("W") end, {desc="只保留 W/ 日志"})
vim.api.nvim_create_user_command("LogcatInfo", function() filter_logcat("I") end, {desc="只保留 I/ 日志"})
vim.api.nvim_create_user_command("LogcatDebug", function() filter_logcat("D") end, {desc="只保留 D/ 日志"})
vim.api.nvim_create_user_command("LogcatVerbose", function() filter_logcat("V") end, {desc="只保留 V/ 日志"})
vim.api.nvim_create_user_command("LogcatFatal", function() filter_logcat("F") end, {desc="只保留 F/ 日志"})

-- 恢复原始内容
vim.api.nvim_create_user_command("LogcatClearFilter", function()
  vim.cmd("edit!")
  print("过滤已清除")
end, {desc="重载文件清除过滤"})

-- ==============================
-- 5️⃣ 实时 adb logcat 流式显示
-- ==============================
vim.api.nvim_create_user_command("AdbLogcat", function()
  -- 新建垂直窗口
  vim.cmd("vnew")
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  vim.bo.filetype = "logcat"

  local buf = vim.api.nvim_get_current_buf()
  local stdout = vim.loop.new_pipe(false)
  local handle
  handle = vim.loop.spawn("adb", {
    args = {"logcat"},
    stdio = {nil, stdout, nil},
  }, function()
    stdout:close()
    handle:close()
  end)

  local lines = {}
  stdout:read_start(function(err, data)
    assert(not err, err)
    if data then
      for s in data:gmatch("[^\r\n]+") do
        table.insert(lines, s)
      end
      vim.schedule(function()
        local row = vim.api.nvim_buf_line_count(buf)
        vim.api.nvim_buf_set_lines(buf, row, -1, false, lines)
        lines = {}
        setup_logcat_highlight() -- 保持实时高亮
      end)
    end
  end)
end, {desc="实时显示 adb logcat"})

return M
