return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight-night",
    },
  },
  {
    "folke/tokyonight.nvim",
    dependencies = {
      "yorumicolors/yorumi.nvim",
    },
    config = function()
      vim.api.nvim_set_hl(0, "ExtraWhitespace", {
        bg = "#FF7777",
      })

      local function highlight_trailing_whitespace()
        if vim.bo.buftype ~= ""
          or vim.bo.filetype == "snacks_dashboard"
          or vim.bo.filetype == "snacks_terminal" then
          return
        end
        vim.cmd([[match ExtraWhitespace /\s\+$/]])
      end

      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          vim.schedule(function()
            highlight_trailing_whitespace()
          end)
        end,
      })
    end,
  },
}
