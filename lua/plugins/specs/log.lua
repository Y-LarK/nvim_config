return {
    {
        "mtdl9/vim-log-highlighting",
        -- 指定在打开以下类型文件时才加载插件，提高启动速度
        ft = { "log", "text" },

        config = function()
            -- 1. 自动识别更多后缀的文件为 'log' 类型
            -- 有些日志文件以 .out, .txt 结尾，或者根本没有后缀
            vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
                pattern = { "*.log", "*.out", "*/logs/*.log", "messages" },
                callback = function()
                    vim.bo.filetype = "log"
                end,
            })

            -- 2. 自定义高亮微调 (可选)
            -- 如果你觉得插件默认的某种颜色不好看，可以在这里修改
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "log",
                callback = function()
                    -- 示例：让时间戳颜色变淡一点（灰色）
                    vim.cmd([[ highlight default link logDate Comment ]])

                    -- 示例：让 'Critical' 关键字显示为白底红字
                    vim.fn.matchadd("ErrorMsg", [[CRITICAL]])
                end,
            })
        end,
    },
}
