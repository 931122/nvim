local is_windows = vim.fn.has("win32") == 1

local build_cmd = is_windows
    and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
  or "make"

local behaviour = {
  enable_fastapply = false,
  enable_cursor_planning_mode = true,
  auto_suggestions = false,
  auto_approve_tool_permissions = false,
}

local dependencies = {
  "nvim-lua/plenary.nvim",
  "MunifTanjim/nui.nvim",

  -- Optional selectors / inputs
  "nvim-mini/mini.pick",
  "nvim-telescope/telescope.nvim",
  "ibhagwan/fzf-lua",
  "stevearc/dressing.nvim",
  "folke/snacks.nvim",

  -- Completion / icons / alternate providers
  "hrsh7th/nvim-cmp",
  "nvim-tree/nvim-web-devicons",
  "zbirenbaum/copilot.lua",

  {
    "HakonHarnes/img-clip.nvim",
    event = "VeryLazy",
    opts = {
      default = {
        embed_image_as_base64 = false,
        prompt_for_file_name = false,
        drag_and_drop = {
          insert_mode = true,
        },
        use_absolute_path = true,
      },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "Avante" },
    opts = {
      file_types = { "markdown", "Avante" },
    },
  },
}

return {
  "yetone/avante.nvim",
  enabled = true,
  event = "VeryLazy",
  build = build_cmd,
  ---@module "avante"
  ---@type avante.Config
  opts = {
    provider = "codex",
    cursor_applying_provider = "llamacpp_local_gptoss20b",
    behaviour = behaviour,
    acp_providers = {
      codex = {
        command = "npx",
        args = { "@zed-industries/codex-acp" },
        env = {
          NODE_NO_WARNINGS = "1",
          OPENAI_API_KEY = os.getenv("OPENAI_API_KEY"),
        },
      },
    },
    web_search_engine = {
      -- Requires GOOGLE_SEARCH_API_KEY and GOOGLE_SEARCH_ENGINE_ID.
      provider = "google",
    },
  },
  dependencies = dependencies,
}
