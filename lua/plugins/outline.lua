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
    vim.api.nvim_create_autocmd("BufReadPost", {
      group = vim.api.nvim_create_augroup("OutlineAutoOpen", { clear = true }),
      callback = function(args)
        local ft = vim.bo[args.buf].filetype
        local ignore = { "NvimTree", "TelescopePrompt", "help", "lazy", "terminal", "Outline" }

        if vim.tbl_contains(ignore, ft) then
          return
        end

        vim.defer_fn(function()
          require("outline")
          vim.cmd("silent! OutlineOpen")
        end, 10)
      end,
    })
  end,
  config = function()
    require("outline").setup({
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

    vim.api.nvim_create_autocmd("BufEnter", {
      group = augroup,
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
