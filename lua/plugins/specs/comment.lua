return {
    {
        "numToStr/Comment.nvim",
        cond = not vim.g.vscode,
        lazy = false,
        opts = {
            mappings = {
                basic = true,  -- gcc / gc / gb
                extra = true,  -- gy / gY（向下/向上注释）
            },
        },
    },
}
