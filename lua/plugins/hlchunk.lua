return {
  -- hlchunk.nvim 插件
  {
    "shellRaining/hlchunk.nvim",
    config = function()
      require("hlchunk").setup({
        chunk = {
          enable = false,
          notify = false,
          use_treesitter = false,
          chars = {
            horizontal_line = "─",
            vertical_line = "│",
            left_top = "╭",
            left_bottom = "╰",
            right_arrow = "▶",
          },
          style = {
            { fg = "#D19A66" },
          },
          support_filetypes = { "*" },
        },
        indent = {
          enable = true,
          use_treesitter = false,
          chars = {
            "│",
            "¦",
            "┆",
            "┊",
          },
          style = {
            { fg = "#6f3f3f" }, -- 红
            { fg = "#7a7345" }, -- 黄
            { fg = "#5f7358" }, -- 绿
            { fg = "#456f73" }, -- 青
            { fg = "#45637a" }, -- 蓝
            { fg = "#6a4f73" }, -- 紫
          },
        },
        blank = {
          enable = false,
        },
        line_num = {
          enable = false,
        },
      })
      vim.g.hlindent = true

      local function set_inlay_hints(enabled)
        if not vim.lsp.inlay_hint then
          return
        end

        vim.g.inlay_hints_enabled = enabled
        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buftype == "" then
            local ok = pcall(vim.lsp.inlay_hint.enable, enabled, { bufnr = bufnr })
            if not ok then
              pcall(vim.lsp.inlay_hint.enable, bufnr, enabled)
            end
          end
        end
      end

      local function toggle_inlay_hints()
        if not vim.lsp.inlay_hint then
          return
        end

        local enabled = vim.g.inlay_hints_enabled
        if enabled == nil then
          local ok, current = pcall(vim.lsp.inlay_hint.is_enabled, { bufnr = 0 })
          enabled = ok and current or true
        end
        set_inlay_hints(not enabled)
      end

      vim.keymap.set("n", "<F7>", function()
        if vim.g.hlindent then
          vim.cmd("DisableHLIndent")
          vim.g.hlindent = false
        else
          vim.cmd("EnableHLIndent")
          vim.g.hlindent = true
        end
        toggle_inlay_hints()
      end, { desc = "Toggle indent and inlay hints" })

    end,
  },
}
