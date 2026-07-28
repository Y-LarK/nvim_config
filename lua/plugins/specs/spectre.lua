return {
    {
        "nvim-pack/nvim-spectre",
        cond = not vim.g.vscode,
        cmd = "Spectre",
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {
            open_cmd = "vnew",
            live_update = true,
        },
        keys = {
            { "<leader>sr", "<cmd>Spectre<cr>", desc = "全局搜索替换" },
        },
    },
}
