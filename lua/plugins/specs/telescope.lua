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
                        "dist/",
                        "%.o$",   -- 目标文件
                        "%.a$",   -- 静态库
                        "%.so$",  -- 动态库
                        "%.out$", -- 默认编译输出
                    },
                },

                -- ✔ 必须放这里
                pickers = {
                    find_files = {
                        -- 使用 fd 代替默认搜索
                        find_command = {
                            "fd",
                            "--type", "f", -- 只找文件 (file)
                            "--hidden",    -- 搜索隐藏文件 (如 .env)
                            "--no-ignore-vcs",
                        },
                    },
                },
            })

            pcall(telescope.load_extension, "fzf")
        end,
    },
}
