return {
    "windwp/nvim-autopairs",

    cond = not vim.g.vscode,
    event = "InsertEnter",               -- 仅在进入插入模式时加载，极致性能
    dependencies = { "hrsh7th/nvim-cmp" }, -- 配合补全插件实现回车确认
    opts = {
        check_ts = true,                 -- 开启 Treesitter 支持
        ts_config = {
            lua = { "string" },          -- lua 字符串内不补全
            javascript = { "template_string" },
            cpp = { "string", "comment" }, -- C++ 的字符串和注释里不补全
            cuda = { "string", "comment" }, -- CUDA 同理
        },
        disable_filetype = { "TelescopePrompt", "spectre_panel" },
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
