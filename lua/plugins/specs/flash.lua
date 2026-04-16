return {
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        opts = {
            labels = "asdfghjklqwertyuiopzxcvbnm", -- 自定义标签顺序，建议用最顺手的键
            search = {
                mode = "exact",                    -- 精确匹配，减少干扰
            },
            jump = {
                autojump = false, -- 建议设为 false，多输入一个字符确认比跳错要滑顺
            },
            label = {
                uppercase = false,            -- 标签不使用大写，保护视力
                rainbow = { enabled = true }, -- 让不同位置的标签颜色不同，更容易区分
            },
        },
    },
}
