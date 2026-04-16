return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false,
    priority = 1000,
    config = function()
      local ts_group = vim.api.nvim_create_augroup("UserTreesitterStart", { clear = true })
      vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
        group = ts_group,
        pattern = {
          "c",
          "cpp",
          "lua",
          "vim",
          "markdown",
          "markdown_inline",
          "cmake",
          "json",
          "yaml",
          "bash",
          "html",
          "css",
          "javascript",
          "typescript",
        },
        callback = function(args)
          local ok_start = pcall(vim.treesitter.start, args.buf, vim.bo[args.buf].filetype)
          if ok_start then
            vim.bo[args.buf].syntax = "off"
          end
        end,
      })

      local ok, configs = pcall(require, "nvim-treesitter.configs")
      if not ok then
        return
      end

      configs.setup({
        ensure_installed = {
          "c",
          "cpp",
          "lua",
          "vim",
          "vimdoc",
          "markdown",
          "markdown_inline",
          "cmake",
          "json",
          "yaml",
          "bash",
          "html",
          "css",
          "javascript",
          "typescript",
        },
        auto_install = true,
        sync_install = false,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = false,
        },
        playground = {
          enable = false,
        },
      })
    end,
  },
}
