return {
    "folke/which-key.nvim",
    cond = not vim.g.vscode,
    event = "VeryLazy",
    opts = {
        preset = "classic",
        delay = 300,
        win = vim.g.vscode and {
            type = "split",
            position = "bottom",
            height = 10,
        } or {
            border = "rounded",
        },
    },
    keys = {
        {
            "<leader>?",
            function()
                require("which-key").show({ global = false })
            end,
            desc = "显示当前文件快捷键",
        },
    },
}
