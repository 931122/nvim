return {
  {
    "folke/persistence.nvim",
    init = function()
      local outline_utils = require("tools.outline_utils")
      local group = vim.api.nvim_create_augroup("PersistenceOutlineFix", { clear = true })

      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "PersistenceSavePre",
        callback = function()
          pcall(vim.cmd, "silent! OutlineClose")
          outline_utils.cleanup_stale_outline_buffers()
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "PersistenceLoadPost",
        callback = function()
          vim.schedule(outline_utils.cleanup_stale_outline_buffers)
        end,
      })
    end,
  },
}
