return {
  "neovim/nvim-lspconfig",

  config = function(_, opts)

    vim.lsp.config.clangd = {
      cmd = {
        "clangd",
        "--clang-tidy",
        "--background-index",
        "--offset-encoding=utf-8",
        "--completion-style=detailed",
        "--function-arg-placeholders=0",
        "--fallback-style=llvm",
        "--cross-file-rename",
        "--header-insertion=never",
      },
    },

    -- require("mason").setup()
    -- require("mason-lspconfig").setup({
    --   ensure_installed = { "jdtls" }, -- Java LSP
    -- })
    -- require("lspconfig").jdtls.setup{
    --   cmd = {"jdtls"},
    --   root_dir = require("lspconfig.util").root_pattern(".git", "mvnw", "gradlew"),
    -- }

    require("lspconfig").clangd.setup {
      cmd = {
        "clangd",
        "--header-insertion=never",
        "--header-insertion-decorators=0",
      }
    }

    -- dts
    vim.api.nvim_create_autocmd('FileType', {
      pattern = "dts",
      callback = function (ev)
        vim.lsp.start({
          name = 'dts-lsp',
          cmd = {'dts-lsp'},
          root_dir = vim.fs.dirname(vim.fs.find({'.git'}, { upward = true })[1]),
        })
      end
    })

    -- disable lsp diagnostic
    vim.diagnostic.disable()

  end,
}
