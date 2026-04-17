return {
    "karb94/neoscroll.nvim",

    config = function()
        require('neoscroll').setup({
            hide_cursor = true,           -- 滚动时隐藏光标
            stop_eof = true,              -- 滚动到文件末尾停止
            respect_scrolloff = false,    -- 考虑 scrolloff 设置
            cursor_scrolls_alone = true,  -- 仅滚动光标而不滚动窗口
            easing_function = "quadratic" -- 动画曲线：quadratic, cubic, quartic, quintic, circular, sine
        })
    end
}
