return {
 "folke/noice.nvim",
 config = function()

  require("noice").setup({
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
