return {
    {
        "MeanderingProgrammer/render-markdown.nvim",
        cond = not vim.g.vscode,
        ft = { "markdown" },
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons",
        },
        opts = {
            restart_highlighter = true,
            render_modes = { "n", "c" },
            anti_conceal = {
                enabled = false, -- 关闭"光标行显示源码"的行为
            },
            file_types = { "markdown" },
            latex = {
                enabled = false,
                converter = "latex2text", -- 默认值,依赖 pylatexenc
                -- 也可以设为其他你自己实现的转换器
                position = "above",       -- 公式渲染在原文上方还是替换原位置("inline")
                top_pad = 0,
                bottom_pad = 0,
            },
            heading = {
                enabled = true,
                icons = { "", "", "", "", "", "" },
                position = "inline",
                backgrounds = { "", "", "", "", "", "" },
                sign = true,
                signs = { "①", "②", "③", "④", "⑤", "⑥" },
                left_pad = 0,  -- 左侧缩进，0 = 顶格
                right_pad = 0, -- 右侧填充
            },
            code = {
                enabled = true,
                sign = false,
                width = "block",
                right_pad = 1,
            },
            bullet = {
                enabled = true,
                icons = { "●", "○", "◆", "◇" },
            },
            checkbox = {
                enabled = true,
                unchecked = { icon = "󰄱 " },
                checked = { icon = "󰱒 " },
            },
        },
    },
}
