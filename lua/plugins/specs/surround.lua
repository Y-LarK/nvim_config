return {
    {
        "kylechui/nvim-surround",
        cond = not vim.g.vscode,
        version = "*",
        event = "VeryLazy",
        opts = {},
    },
}
