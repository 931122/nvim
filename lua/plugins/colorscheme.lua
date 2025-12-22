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
        if vim.bo.buftype ~= "" then
          return
        end
        vim.cmd([[match ExtraWhitespace /\s\+$/]])
      end

      vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("HighlightTrailingWhitespace", { clear = true }),
        callback = highlight_trailing_whitespace,
      })

      vim.api.nvim_create_autocmd("TermOpen", {
        group = vim.api.nvim_create_augroup("NoWhitespaceInTerminal", { clear = true }),
        callback = function()
          vim.cmd("match none")
        end,
      })
    end,
  },
}
