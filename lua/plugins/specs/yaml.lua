return {
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "yaml" })
        end,
    },

    {
        "williamboman/mason.nvim",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "yaml-language-server", "prettier" })
        end,
    },
    -- YAML 的格式化器统一在 conform.lua 的 formatters_by_ft 里配置，
    -- 这里不再重复写一份，避免只改一边造成两处不一致。
}
