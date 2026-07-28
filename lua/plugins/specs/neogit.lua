return {
    {
        "NeogitOrg/neogit",
        cond = not vim.g.vscode,
        cmd = "Neogit",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "sindrets/diffview.nvim",
        },
        opts = {
            integrations = { diffview = true },
        },
        keys = {
            { "<leader>gg", "<cmd>Neogit<cr>", desc = "Neogit 状态面板" },
        },
    },
}
