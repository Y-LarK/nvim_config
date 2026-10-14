return {
  {
    "williamboman/mason.nvim",
    cond = not vim.g.vscode,
    build = ":MasonUpdate",
    lazy = false,
    opts = {
      ui = {
        border = "rounded",
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      -- clangd 刻意不用 mason 的：其 22.1.0 版本会 segfault，
      -- 改用系统 /usr/bin/clangd（见 lsp.lua 里的说明）
      ensure_installed = { "lua_ls", "marksman" },
    },
  },
}
