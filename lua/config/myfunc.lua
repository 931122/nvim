local function module_name(path)
  return path:match("lua/(.+)%.lua$")
end

local files = vim.fn.glob(vim.fn.stdpath("config") .. "/lua/myfunc/*.lua", false, true)
table.sort(files)

for _, file in ipairs(files) do
  local mod = module_name(file)
  if mod then
    local ok, err = pcall(require, mod)
    if not ok then
      vim.notify("加载模块失败: " .. mod .. "\n" .. err, vim.log.levels.ERROR)
    end
  end
end
