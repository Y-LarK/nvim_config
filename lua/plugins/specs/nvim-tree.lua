return {
    "nvim-tree/nvim-tree.lua",
    dependencies = "nvim-tree/nvim-web-devicons",
    lazy = false,

    config = function()
        require("nvim-tree").setup({

            -- 🌳 1. 视图（更现代）
            view = {
                width = 32,
                side = "left",
                preserve_window_proportions = true,
            },

            -- 🎨 2. 渲染（核心美化）
            renderer = {
                group_empty = true,
                highlight_git = true,
                highlight_diagnostics = true,
                highlight_opened_files = "name",

                root_folder_label = function(path)
                    return " " .. vim.fn.fnamemodify(path, ":t")
                end,

                indent_markers = {
                    enable = true,
                    inline_arrows = true,
                    icons = {
                        corner = "└ ",
                        edge = "│ ",
                        item = "│ ",
                        none = "  ",
                    },
                },

                icons = {
                    webdev_colors = true,

                    glyphs = {
                        default = "󰈚",
                        symlink = "",

                        folder = {
                            arrow_closed = "",
                            arrow_open = "",

                            default = "",
                            open = "",

                            empty = "",
                            empty_open = "",
                        },

                        git = {
                            unstaged = "●",
                            staged = "✔",
                            unmerged = "",
                            renamed = "➜",
                            untracked = "★",
                            deleted = "✖",
                            ignored = "◌",
                        },
                    },
                },
            },

            -- 🔍 3. 过滤（更干净）
            filters = {
                dotfiles = false,
                git_ignored = true,
            },

            -- ⚡ 4. Git 状态（必须开）
            git = {
                enable = true,
                ignore = false,
            },

            -- 🧠 5. 诊断（非常关键）
            diagnostics = {
                enable = true,
                show_on_dirs = true,
                icons = {
                    hint = "",
                    info = "",
                    warning = "",
                    error = "",
                },
            },

            -- 🖱️ 6. 行为优化
            actions = {
                open_file = {
                    quit_on_open = false,
                    resize_window = true,
                },
            },

            -- ✨ 7. 更新跟随当前文件
            update_focused_file = {
                enable = true,
                update_root = false,
            },

        })
    end,
}
