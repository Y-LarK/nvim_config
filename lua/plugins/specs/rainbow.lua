return {
    "HiPhish/rainbow-delimiters.nvim",
    cond = not vim.g.vscode,
    lazy = false,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
        local rb = require("rainbow-delimiters")
        vim.g.rainbow_delimiters = {
            strategy = {
                [""] = rb.strategy.global,
                vim = rb.strategy["local"],
            },
            query = {
                [""] = "rainbow-delimiters",
                lua = "rainbow-blocks",
            },
            highlight = {
                "RainbowDelimiterRed",
                "RainbowDelimiterYellow",
                "RainbowDelimiterBlue",
                "RainbowDelimiterOrange",
                "RainbowDelimiterGreen",
                "RainbowDelimiterViolet",
                "RainbowDelimiterCyan",
            },
        }
    end,
}
