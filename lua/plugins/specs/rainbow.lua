return {
    "HiPhish/rainbow-delimiters.nvim",
    cond = not vim.g.vscode,
    lazy = false,
    git = { submodules = false }, -- 禁用 gitlab 子模块（仅测试用）
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
        require("config.inline_bracket_guides").setup()
    end,
}
