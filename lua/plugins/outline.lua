return {
  "hedyhli/outline.nvim",
  event = "VeryLazy",
  dependencies = {
    "epheien/outline-treesitter-provider.nvim",
  },
  cmd = { "Outline", "OutlineOpen", "OutlineClose" },
  keys = {
    { "<leader>t", "<cmd>silent! Outline<CR>", desc = "Toggle Outline" },
  },
  init = function()
    local auto_open_group = vim.api.nvim_create_augroup("OutlineAutoOpen", { clear = true })
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
      group = auto_open_group,
      callback = function(args)
        if not vim.api.nvim_buf_is_valid(args.buf) or args.buf ~= vim.api.nvim_get_current_buf() then
          return
        end

        if vim.bo[args.buf].buftype ~= "" then
          return
        end

        local ft = vim.bo[args.buf].filetype
        local ignore = { "NvimTree", "TelescopePrompt", "help", "lazy", "terminal", "Outline" }

        if vim.tbl_contains(ignore, ft) then
          return
        end

        vim.schedule(function()
          if not vim.api.nvim_buf_is_valid(args.buf) or args.buf ~= vim.api.nvim_get_current_buf() then
            return
          end
          pcall(vim.cmd, "silent! OutlineOpen!")
        end)
      end,
    })
  end,
  config = function()
    local outline = require("outline")
    local auto_close_group = vim.api.nvim_create_augroup("OutlineAutoClose", { clear = true })
    local outline_keys_group = vim.api.nvim_create_augroup("OutlineCustomKeys", { clear = true })

    outline.setup({
      outline_window = {
        position = "left",
        width = 15,
        focus_on_open = false,
      },
      preview_window = {
        auto_preview = true,
      },
      symbols = {
        icon = false,
        kind_icons = {},
      },
      providers = {
        priority = { "lsp", "treesitter", "markdown", "norg" },
      },
    })

    vim.api.nvim_create_autocmd("FileType", {
      group = outline_keys_group,
      pattern = "Outline",
      callback = function(args)
        vim.keymap.set("n", "<Esc>", function()
          outline.focus_code()
        end, { buffer = args.buf, silent = true, desc = "Outline: Focus code" })
      end,
    })

    vim.api.nvim_create_autocmd("BufEnter", {
      group = auto_close_group,
      callback = function()
        -- 统计非 floating 的普通窗口数量
        local function count_normal_windows()
          local count = 0
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local cfg = vim.api.nvim_win_get_config(win)
            if cfg.relative == "" then
              count = count + 1
            end
          end
          return count
        end

        if vim.bo.filetype == "Outline" and count_normal_windows() == 1 then
          vim.cmd("q")
        end
      end,
    })

  end,
}
