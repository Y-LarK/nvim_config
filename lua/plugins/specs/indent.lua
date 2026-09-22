local rainbow_highlights = {
    "RainbowDelimiterRed",
    "RainbowDelimiterYellow",
    "RainbowDelimiterBlue",
    "RainbowDelimiterOrange",
    "RainbowDelimiterGreen",
    "RainbowDelimiterViolet",
    "RainbowDelimiterCyan",
}

return {
    {
        "lukas-reineke/indent-blankline.nvim",
        cond = not vim.g.vscode,
        event = { "BufReadPost", "BufNewFile" },
        main = "ibl",                                         -- 新版本需要指定入口
        dependencies = { "nvim-treesitter/nvim-treesitter" }, -- 必须依赖 TS
        opts = {
            -- 1. 缩进线基础配置
            indent = {
                char = "│", -- 连线字符，也可以用 "╎" 或 "┆"
                tab_char = "│",
            },
            -- 2. 核心：括号作用域连线 (Scope)
            scope = {
                enabled = true,
                show_start = true,
                show_end = true,
                injected_languages = true,
                highlight = rainbow_highlights,
                priority = 500,
            },
            -- 3. 排除规则
            exclude = {
                filetypes = {
                    "help",
                    "dashboard",
                    "lazy",
                    "mason",
                    "notify",
                    "toggleterm",
                },
            },
        },
        config = function(_, opts)
            local hooks = require("ibl.hooks")
            require("ibl").setup(opts)

            -- 不用内置的 scope_highlight_from_extmark：它靠读 rainbow 画好的 extmark
            -- 反推层级，而 rainbow 在补全菜单可见时会跳过更新且不补刷，于是连线会抄到
            -- 过期颜色（接受补全后 dd 就能复现括号红、连线黄）。改为直接从语法树算。
            local rainbow_level = require("config.rainbow_level")
            hooks.register(hooks.type.SCOPE_HIGHLIGHT, function(_, bufnr, scope, scope_index)
                return rainbow_level.level_of(bufnr, scope) or scope_index
            end)
        end,
    },
}
