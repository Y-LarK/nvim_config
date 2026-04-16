return {
    {
        name = "gradient-theme",
        dir = vim.fn.stdpath("config") .. "/lua/plugins/local/gradient-theme",
        lazy = false,
        priority = 1000,
        config = function()
            require("gradient_theme").setup()
        end,
    },
}
