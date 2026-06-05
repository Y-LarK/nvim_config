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
      ensure_installed = { "clangd", "lua_ls", "marksman" },
    },
  },
}
