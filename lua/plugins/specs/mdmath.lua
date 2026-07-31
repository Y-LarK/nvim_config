return {
    {
        "Thiago4532/mdmath.nvim",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        build = ":MdMath build",
        event = { "BufReadPre *.md", "BufNewFile *.md" },
        opts = {
            enabled = true,
            filetypes = { "markdown" },
            foreground = "Normal",
            anticonceal = true,
            hide_on_insert = false,
            dynamic = true,
            update_interval = 400,
        },
    },
}
