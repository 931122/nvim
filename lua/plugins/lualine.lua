return {
  "nvim-lualine/lualine.nvim",
  config = function()
    local gitblame = {
      function() return vim.b.gitsigns_blame_line or "" end,
      cond = function() return vim.b.gitsigns_blame_line ~= nil end,
      icon = "",
      color = { fg = "#1f2335", bg = "#ff9e64", gui = "italic" },
      separator = { left = "" },
    }

    require("lualine").setup({
      options = {
        theme = "auto",
        section_separators = { left = "", right = "" },
        globalstatus = true,
      },

      sections = {
        lualine_a = {
          {
            "searchcount",
            color = { fg = "#1f2335", bg = "#7dcfff" },
            separator = { right = "" },
          },
          {
            "mode",
            color = { fg = "#1f2335", bg = "#7aa2f7" },
            separator = { right = "" },
          },
          {
            "branch",
            icon = "",
            color = { fg = "#1f2335", bg = "#9ece6a" },
            separator = { right = "" },
          },
        },

        lualine_b = {
          {
            "diff",
            symbols = {
              added    = " ",
              modified = " ",
              removed  = " ",
            },
            separator = { right = "" },
          },

          {
            'filesize',
            color = { fg = "#1f2335", bg = "#7dcfff" },
            separator = { right = "" },
          },
          {
            "filename", path = 1,
            color = { fg = "#c0caf5", bg = "#3b4261" },
          },
        },

        lualine_c = {},

        lualine_x = {
          gitblame,
          {
            "encoding",
            color = { fg = "#c0caf5", bg = "#414868" },
            separator = { left = "" },
          },
          {
            "fileformat",
            color = { fg = "#c0caf5", bg = "#414868" },
          },
          {
            "filetype",
            color = { fg = "#c0caf5", bg = "#414868" },
          },
        },

        lualine_y = {
          {
            "progress",
            color = { fg = "#1f2335", bg = "#e0af68" },
          },
        },

        lualine_z = {
          {
            "location",
            color = { fg = "#1f2335", bg = "#f7768e" },
          },
        },
      },
    })
  end,
}
