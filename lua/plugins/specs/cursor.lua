return {
    {
        "sphamba/smear-cursor.nvim",
        cond = not vim.g.vscode,
        lazy = false,
        -- opts 惰性求值：本插件 lazy=false，setup 发生在 gradient-theme
        -- （priority 1000）之后，此时启动模式已检测完毕；直接写表会在
        -- spec 扫描期求值，模式永远读成 nil
        opts = function()
            return {
                -- 深色：德古拉紫原值；浅色：gruvbox purple。
                -- 运行中切模式由 gradient-theme 写 smear_cursor 模块并 clear_cache
                cursor_color = vim.g.gradient_theme_mode == "light" and "#8f3f71" or "#bd93f9",
                -- 稍微提高一点 stiffness 可以减少低端设备上的拖影计算开销
                stiffness = 0.8,
                trailing_stiffness = 0.5,
                distance_stop_animating = 0.5,
                hide_target_hack = false, -- 如果你的终端渲染没问题，建议设为 false 以减少渲染逻辑
            }
        end,
    },
}
