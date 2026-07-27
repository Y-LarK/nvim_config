return {
    {
        "stevearc/aerial.nvim",
        cond = not vim.g.vscode,
        lazy = false,
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons",
        },
        opts = {
            backends = { "treesitter", "lsp", "markdown" },
            layout = {
                max_width = { 40, 0.2 },
                min_width = 20,
                placement = "edge",
                default_direction = "left",
                preserve_equality = false,
            },
            filter_kind = false,
            highlight_on_jump = 300,
            close_automatic_events = {},
            keymaps = {
                ["<CR>"] = "actions.jump",
                ["o"] = "actions.jump",
                ["<Tab>"] = "actions.toggle",
            },
        },
        keys = {
            { "<leader>to", "<cmd>AerialToggle<cr>", desc = "切换大纲侧边栏" },
        },
    },
}
