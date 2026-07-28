return {
    {
        "lewis6991/gitsigns.nvim",
        cond = not vim.g.vscode,
        lazy = false,
        opts = {
            signs = {
                add          = { text = "│" },
                change       = { text = "│" },
                delete       = { text = "▁" },
                topdelete    = { text = "▔" },
                changedelete = { text = "~" },
                untracked    = { text = "┆" },
            },
            signcolumn = true,
            numhl = false,
            linehl = false,
            word_diff = false,
            watch_gitdir = { interval = 1000 },
            attach_to_untracked = true,
            current_line_blame = false,
            current_line_blame_opts = { delay = 1000 },
            on_attach = function(bufnr)
                local gs = package.loaded.gitsigns
                vim.keymap.set("n", "]h", gs.next_hunk, { buffer = bufnr, desc = "下一处改动" })
                vim.keymap.set("n", "[h", gs.prev_hunk, { buffer = bufnr, desc = "上一处改动" })
                vim.keymap.set("n", "<leader>hs", gs.stage_hunk, { buffer = bufnr, desc = "暂存当前块" })
                vim.keymap.set("n", "<leader>hr", gs.reset_hunk, { buffer = bufnr, desc = "撤销当前块" })
                vim.keymap.set("v", "<leader>hs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { buffer = bufnr, desc = "暂存选中块" })
                vim.keymap.set("v", "<leader>hr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { buffer = bufnr, desc = "撤销选中块" })
                vim.keymap.set("n", "<leader>hS", gs.stage_buffer, { buffer = bufnr, desc = "暂存全部" })
                vim.keymap.set("n", "<leader>hb", function() gs.blame_line({ full = true }) end, { buffer = bufnr, desc = "行 Blame" })
                vim.keymap.set("n", "<leader>hp", gs.preview_hunk_inline, { buffer = bufnr, desc = "预览改动" })
            end,
        },
    },
}
