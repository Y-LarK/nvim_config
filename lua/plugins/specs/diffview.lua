return {
    {
        "sindrets/diffview.nvim",
        cond = not vim.g.vscode,
        cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
        opts = {
            enhanced_diff_hl = true,
            view = {
                merge_tool = {
                    layout = "diff3_mixed",
                },
            },
        },
        keys = {
            { "<leader>gv", "<cmd>DiffviewOpen<cr>",          desc = "DiffView 当前修改" },
            { "<leader>gh", "<cmd>DiffviewFileHistory<cr>",   desc = "文件历史" },
            { "<leader>gH", "<cmd>DiffviewFileHistory %<cr>", desc = "当前文件历史" },
        },
    },
}
