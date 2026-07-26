return {
    {
        "HakonHarnes/img-clip.nvim",
        cond = not vim.g.vscode,
        ft = { "markdown" },
        opts = {
            default = {
                dir_path = vim.fn.getcwd() .. "/assets", -- 图片保存目录
                file_name = "%Y%m%d-%H%M%S",              -- 时间戳命名: 20260726-153000.png
                prompt_for_file_name = true,              -- 粘贴时确认文件名
                use_absolute_path = false,                -- 使用相对路径
                insert_mode = true,                       -- 插入模式下也能粘贴
            },
        },
        keys = {
            { "<leader>pi", "<cmd>PasteImage<cr>", mode = { "n" }, desc = "粘贴剪贴板图片" },
        },
    },
}
