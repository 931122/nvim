return {
  {
    "3rd/image.nvim",
    ft = { "markdown" },
    enabled = true,
    build = false,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      backend = "kitty",
      processor = "magick_cli",
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = true,
          only_render_image_at_cursor_mode = "inline",
          floating_windows = false,
          filetypes = { "markdown" },
        },
      },
      max_width_window_percentage = 100,
      max_height_window_percentage = 50,
      window_overlap_clear_enabled = false,
      editor_only_render_when_focused = true,
      hijack_file_patterns = {},
    },
    config = function(_, opts)
      local image = require("image")
      image.setup(opts)
    end,
  },
}
