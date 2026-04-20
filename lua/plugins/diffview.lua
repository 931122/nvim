local function toggle_diffview()
  local lib = require("diffview.lib")
  if lib.get_current_view() then
    vim.cmd("DiffviewClose")
    return
  end
  vim.cmd("DiffviewOpen")
end

return {
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewFileHistory",
      "DiffviewRefresh",
    },
    keys = {
      { "<F10>", toggle_diffview, desc = "Diffview Toggle" },
      -- { "<leader>gD", "<cmd>DiffviewClose<cr>", desc = "Diffview Close" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview History" },
      { "<leader>gF", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview File History" },
    },
    opts = {},
  },
}
