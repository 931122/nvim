return {
  "folke/noice.nvim",
  config = function()

    require("noice").setup({
      presets = {
        bottom_search = false, -- use a classic bottom cmdline for search
        command_palette = true, -- position the cmdline and popupmenu together
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = true, -- enables an input dialog for inc-rename.nvim
      },
      routes = {
        {
          filter = {
            event = "msg_show",
            kind = "search_count",
          },
          opts = { skip = true },
        },
      },
      views = {
        cmdline_popup = {
          position = {
            row = 40,
            col = "60%",
          },
          size = {
            width = 50,
            height = "auto",
          },
        },
        popupmenu = {
          relative = "editor",
          position = {
            row = 10,
            col = "20%",
          },
          size = {
            width = 60,
            height = 20,
          },
          border = {
            style = "rounded",
            padding = { 0, 1 },
          },
          win_options = {
            winhighlight = { Normal = "Normal", FloatBorder = "DiagnosticInfo" },
          },
        },
      },
    })
  end
}
