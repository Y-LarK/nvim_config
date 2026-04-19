return {
    {
        "sphamba/smear-cursor.nvim",
        lazy = false,
        opts = {
            cursor_color = "#d3ebe9",
            stiffness = 0.4,               -- 整体拉伸感
            trailing_stiffness = 0.3,      -- 减小此值可获得更长的拖尾
            distance_stop_animating = 0.1, -- 动画停止的阈值，防止微小抖动
            hide_target_hack = true,       -- 如果你发现有两个光标，请将此项设为 true
        },
    },
}
