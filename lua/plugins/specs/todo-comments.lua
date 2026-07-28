return {
    {
        "folke/todo-comments.nvim",
        cond = not vim.g.vscode,
        lazy = false,
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {
            signs = false,
            keywords = {
                FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
                TODO = { icon = " ", color = "info" },
                HACK = { icon = " ", color = "warning" },
                WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
                PERF = { icon = " ", color = "hint", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
                NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
                TEST = { icon = "⏣ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
            },
            highlight = {
                keyword = "wide",
                pattern = [[(KEYWORDS)\s*:?]],
            },
            search = { command = "rg", pattern = [[\b(KEYWORDS)\b]] },
        },
        keys = {
            { "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "查找 TODO" },
        },
    },
}
