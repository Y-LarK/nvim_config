return {
    {
        "nvim-telescope/telescope.nvim",
        branch = "0.1.x",
        cmd = "Telescope",
        dependencies = {
            "nvim-lua/plenary.nvim",
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
        },
        config = function()
            local telescope = require("telescope")

            telescope.setup({
                defaults = {
                    preview = {
                        treesitter = false,
                    },
                    layout_strategy = "horizontal",
                    layout_config = {
                        horizontal = { preview_width = 0.55 },
                        width = 0.9,
                    },
                    file_ignore_patterns = {
                        "node_modules/",
                        "%.git/",
                        "build/",
                        "dist/",
                    },
                },

                -- ✔ 必须放这里
                pickers = {
                    find_files = {
                        hidden = true,
                        no_ignore = true,
                    },
                },
            })

            pcall(telescope.load_extension, "fzf")
        end,
    },
}
