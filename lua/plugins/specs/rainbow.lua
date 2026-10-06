return {
    "HiPhish/rainbow-delimiters.nvim",
    cond = not vim.g.vscode,
    lazy = false,
    submodules = false, -- 顶层字段（lazy 只读 plugin.submodules）：子模组只有 .luals 类型定义与 busted 测试 shim，运行无关
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
        require("config.rainbow_level").setup()
        require("config.inline_bracket_guides").setup()
    end,
}
