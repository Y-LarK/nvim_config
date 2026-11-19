return {
    "windwp/nvim-autopairs",

    cond = not vim.g.vscode,
    event = "InsertEnter",               -- 仅在进入插入模式时加载，极致性能
    opts = {
        check_ts = true,                 -- 开启 Treesitter 支持
        ts_config = {
            lua = { "string" },          -- lua 字符串内不补全
            javascript = { "template_string" },
            cpp = { "string", "comment" }, -- C++ 的字符串和注释里不补全
            cuda = { "string", "comment" }, -- CUDA 同理
        },
        disable_filetype = { "TelescopePrompt", "spectre_panel" },
        -- 光标夹在一对空括号中间时，默认的退格会把左右两个括号一起删掉
        -- （实测 `foo(bar(|));` 按一次 BS -> `foo(bar);`）。关闭后退格永远只删
        -- 光标左侧一个字符，嵌套括号里不会再连带删掉右侧的 ')'。
        map_bs = false,
        fast_wrap = {
            map = "<M-e>", -- 快捷键 Alt+e，可以将括号快速包裹住后面的词
        },
    },
    config = function(_, opts)
        local autopairs = require("nvim-autopairs")
        autopairs.setup(opts)

        -- 补全后自动补括号由 blink.cmp 的 completion.accept.auto_brackets 内置提供，
        -- 原先与 nvim-cmp 的集成不再需要
    end,
}
