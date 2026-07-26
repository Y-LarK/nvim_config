return {
    {
        "Thiago4532/mdmath.nvim",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        build = ":MdMath build",
        ft = { "markdown" },
        opts = {
            filetypes = { "markdown" },
            foreground = "Normal",
            anticonceal = false,
            hide_on_insert = true,
            dynamic = true,
            update_interval = 400,
        },
    },
}
