return {
    {
        "mbbill/undotree",
        cond = not vim.g.vscode,
        keys = {
            { "<leader>uu", "<cmd>UndotreeToggle<cr>", desc = "切换撤销树" },
        },
    },
}
