return {
    {
        "nvim-telescope/telescope.nvim",
        cond = not vim.g.vscode,
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
                        "build/",              -- CMake 构建目录
                        "%.o$",                -- 目标文件
                        "%.a$",                -- 静态库
                        "%.so$",               -- 动态库
                        "%.out$",              -- 默认编译输出
                        "%.d$",                -- 依赖文件
                        "CMakeFiles/",         -- CMake 内部
                        "CMakeCache%.txt$",    -- CMake 缓存
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

                -- ui-select 扩展的主题（接管 vim.ui.select 时使用）
                extensions = {
                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown({}),
                    },
                },
            })

            pcall(telescope.load_extension, "fzf")
        end,
    },
    {
        -- 接管 vim.ui.select，让 cmake-tools 的目标列表等变成可模糊搜索的 telescope 列表。
        -- 放 VeryLazy：不阻塞启动，但保证首次按 <leader>ct 之前已经生效。
        "nvim-telescope/telescope-ui-select.nvim",
        cond = not vim.g.vscode,
        event = "VeryLazy",
        dependencies = { "nvim-telescope/telescope.nvim" },
        config = function()
            require("telescope").load_extension("ui-select")
        end,
    },
}
