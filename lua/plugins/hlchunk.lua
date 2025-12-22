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
      vim.keymap.set("n", "<F7>", function()
        if vim.g.hlindent then
          vim.cmd("DisableHLIndent")
          vim.g.hlindent = false
        else
          vim.cmd("EnableHLIndent")
          vim.g.hlindent = true
        end
      end, { desc = "toggle git hl" })

    end,
  },
}
