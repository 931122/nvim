-- =========================
-- Compile & Run (data-driven)
-- =========================

local runners = {
  c = {
    cmd = [[echo "▶ gcc %s -o %s" && gcc %s -o %s && echo "▶ ./%s" && ./%s]],
    args = { "file", "out", "file_p|esc", "out|esc", "out_name", "out_name" },
  },

  cpp = {
    cmd = [[echo "▶ g++ %s -o %s -std=c++11" && g++ %s -o %s -std=c++11 && echo "▶ ./%s" && ./%s]],
    args = { "file", "out", "file_p|esc", "out|esc", "out_name", "out_name" },
  },

  python = {
    cmd = [[echo "▶ python %s" && python %s]],
    args = { "file", "file_p|esc" },
  },

  lua = {
    cmd = [[echo "▶ lua %s" && lua %s]],
    args = { "file", "file_p|esc" },
  },

  sh = {
    cmd = [[chmod +x %s && echo "▶ ./%s" && ./%s]],
    args = { "file_p|esc", "file", "file" },
  },

  rust = {
    cmd = [[echo "▶ rustc %s -o %s" && rustc %s -o %s && echo "▶ ./%s" && ./%s]],
    args = { "file", "out", "file_p|esc", "out|esc", "out_name", "out_name" },
  },

  go = {
    cmd = [[echo "▶ go run %s" && go run %s]],
    args = { "file", "file_p|esc" },
  },

  java = {
    cmd = [[echo "▶ javac %s" && javac %s && echo "▶ java %s" && java %s]],
    args = { "file", "file_p|esc", "out_name", "out_name" },
  },
}

-- ---------- argument builder ----------
local function build_args(ctx, specs)
  local args = {}

  for _, spec in ipairs(specs) do
    local key, op = spec:match("([^|]+)|?(.*)")
    local val = ctx[key]

    if not val then
      error("invalid ctx key: " .. key)
    end

    if op == "esc" then
      val = ctx.esc(val)
    end

    table.insert(args, val)
  end

  return args
end

-- ---------- main entry ----------
local function CompileRun()
  vim.cmd("write")

  local ft = vim.bo.filetype
  local r = runners[ft]

  if not r then
    vim.notify("不支持的文件类型: " .. ft, vim.log.levels.WARN)
    return
  end

  local ctx = {
    file      = vim.fn.expand("%"),
    file_p    = vim.fn.expand("%:p"),
    out       = vim.fn.expand("%:r"),
    out_name  = vim.fn.expand("%:t:r"),
    esc       = vim.fn.shellescape,
  }

  local args = build_args(ctx, r.args)
  local final_cmd = string.format(r.cmd, unpack(args))

  local code_win = vim.api.nvim_get_current_win()
  vim.cmd("botright new")
  vim.cmd("resize 15")

  vim.fn.termopen({ "/bin/bash", "-c", final_cmd })
  vim.cmd("startinsert")
  vim.api.nvim_set_current_win(code_win)
end

vim.keymap.set("n", "<leader><F5>", CompileRun, { silent = true, noremap = true })
