return {
    {
        "sphamba/smear-cursor.nvim",
        cond = not vim.g.vscode,
        lazy = false,
        opts = {
            cursor_color = "#bd93f9",
            -- 稍微提高一点 stiffness 可以减少低端设备上的拖影计算开销
            stiffness = 0.8,
            trailing_stiffness = 0.5,
            distance_stop_animating = 0.5,
            hide_target_hack = false, -- 如果你的终端渲染没问题，建议设为 false 以减少渲染逻辑
        },
    },
}
