return {
  "neovim/nvim-lspconfig",
  init = function()
    vim.diagnostic.enable(false)

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("local_lsp_nonfile_uri_guard", { clear = true }),
      callback = function(args)
        local name = vim.api.nvim_buf_get_name(args.buf)
        if not name:match("^diffview://") then
          return
        end

        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(args.buf) then
            pcall(vim.lsp.buf_detach_client, args.buf, args.data.client_id)
          end
        end)
      end,
    })

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("local_dts_lsp", { clear = true }),
      pattern = "dts",
      callback = function()
        local git_dir = vim.fs.find(".git", { upward = true })[1]
        local root_dir = git_dir and vim.fs.dirname(git_dir) or vim.loop.cwd()
        vim.lsp.start({
          name = "dts-lsp",
          cmd = { "dts-lsp" },
          root_dir = root_dir,
        })
      end,
    })
  end,
  opts = function(_, opts)
    opts.servers = opts.servers or {}
    opts.servers.clangd = vim.tbl_deep_extend("force", opts.servers.clangd or {}, {
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
        "--header-insertion-decorators=0",
      },
    })
  end,
}
