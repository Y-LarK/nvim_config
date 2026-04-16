return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        -- 这里的配置可以留空，使用默认设置就很棒
        preset = "classic", -- 或者 "modern", "helix"
        delay = 300,      -- 按下按键后多久弹出提示窗口 (单位: ms)
        win = {
            border = "rounded", -- 保持和你 noice 一样的圆角风格
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
