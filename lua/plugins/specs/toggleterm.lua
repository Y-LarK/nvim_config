return {
    {
        "akinsho/toggleterm.nvim",
        cond = not vim.g.vscode,
        version = "*",
        event = "VeryLazy",
        opts = {
            size = function(term)
                if term.direction == "horizontal" then
                    return 15
                elseif term.direction == "vertical" then
                    return vim.o.columns * 0.4
                end
            end,
            open_mapping = [[<C-\>]],
            direction = "float",
            float_opts = {
                border = "curved",
                width = math.floor(vim.o.columns * 0.8),
                height = math.floor(vim.o.lines * 0.8),
            },
            on_open = function(term)
                -- <C-g> 从终端模式退回 normal 模式
                vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<C-g>", [[<C-\><C-n>]], { noremap = true, silent = true })
            end,
        },
    },
}
