return {
    -- 1. Nvim-Notify: 保持不变
    {
        "rcarriga/nvim-notify",
        opts = {
            timeout = 3000,
            stages = "fade",
            background_colour = "#282a36",
            render = "compact",
        },
        config = function(_, opts)
            local notify = require("notify")
            notify.setup(opts)
            vim.notify = notify
        end,
    },

    -- 2. Noice.nvim: 深度美化视图
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        dependencies = {
            "MunifTanjim/nui.nvim",
            "rcarriga/nvim-notify",
        },
        opts = {
            lsp = {
                override = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    ["vim.lsp.util.stylize_markdown"] = true,
                    ["cmp.entry.get_documentation"] = true,
                },
            },
            presets = {
                bottom_search = false,  -- 搜索栏在中间
                command_palette = true, -- 命令行在中间
                long_message_to_split = true,
                lsp_doc_border = true,  -- 给文档弹窗（K键）加边框
            },
            -- --- 新增：深度自定义视图样式 ---
            views = {
                -- 针对命令行弹出框的美化
                cmdline_popup = {
                    border = {
                        style = "rounded",
                        padding = { 0, 1 },
                    },
                    win_options = {
                        winhighlight = {
                            Normal = "Normal",
                            FloatBorder = "FloatBorder",
                        },
                    },
                    position = {
                        row = "40%", -- 稍微偏上一点，视觉更舒适
                        col = "50%",
                    },
                    size = {
                        width = 60,
                        height = "auto",
                    },
                },
                -- 针对提示信息（如保存提醒、通知等）的边框
                popupmenu = {
                    relative = "editor",
                    position = {
                        row = 8,
                        col = "50%",
                    },
                    size = {
                        width = 60,
                        height = 10,
                    },
                    border = {
                        style = "rounded",
                        padding = { 0, 1 },
                    },
                    win_options = {
                        winhighlight = { Normal = "Normal", FloatBorder = "FloatBorder" },
                    },
                },
                cmdline_popupmenu = {
                    relative = "editor",
                    position = {
                        row = 8,
                        col = "50%",
                    },
                    size = {
                        width = 60,
                        height = 10,
                    },
                    border = {
                        style = "single",
                        padding = { 0, 1 },
                    },
                    win_options = {
                        winhighlight = {
                            Normal = "Normal",
                            FloatBorder = "NoiceCmdlinePopupBorder",
                        },
                    },
                },
            },
            routes = {
                {
                    filter = { event = "msg_show", find = "written" },
                    opts = { skip = true },
                },
            },
        },
    },


    -- 3. Bufferline: 顶部标签栏
    {
        "akinsho/bufferline.nvim",
        version = "*",
        dependencies = "nvim-tree/nvim-web-devicons",
        cmd = {
            "BufferLineCyclePrev",
            "BufferLineCycleNext",
        },
        opts = {
            options = {
                mode = "buffers",
                separator_style = "curve",
                always_show_bufferline = true,
                show_buffer_close_icons = false,
                show_close_icon = false,
                -- 【新增】诊断集成：文件报错时，标签栏会有提示
                diagnostics = "nvim_lsp",
                diagnostics_indicator = function(count, level)
                    local icon = level:match("error") and " " or " "
                    return "(" .. icon .. count .. ")"
                end,
                -- 鼠标左键点击切换，右键点击关闭，符合 Windows/Linux 逻辑
                right_mouse_command = "bdelete!",
                show_buffer_icons = true, -- 显示文件类型图标 (需 Nerd Font)
                modified_icon = "●", -- 文件被修改但未保存时的图标
            },
            highlights = {
                fill = {
                    bg = "#1e1e2e", -- 整个标签栏的背景色（空隙处）
                },
                background = {
                    fg = "#6c7086",
                    bg = "#1e1e2e",
                },
                buffer_selected = {
                    fg = "#89b4fa", -- 选中文件的文字颜色
                    bg = "#313244", -- 选中文件的背景色
                    bold = true,
                    italic = true,
                },
                separator_selected = {
                    fg = "#1e1e2e", -- 选中标签两侧分隔符的颜色
                },
                -- 1. 未选中的标签背景下的诊断信息
                warning = {
                    bg = "#1e1e2e", -- 这里填你未选中标签的背景色
                },
                error = {
                    bg = "#1e1e2e",
                },
                info = {
                    bg = "#1e1e2e",
                },
                hint = {
                    bg = "#1e1e2e",
                },
                -- 2. 选中状态下的标签背景下的诊断信息 (最关键，因为图片中 ui.lua 是选中的)
                warning_selected = {
                    fg = "#eab308", -- 图标颜色
                    bg = "#313244", -- 这里填你【选中标签】的背景色
                    bold = true,
                    italic = true,
                },
                error_selected = {
                    fg = "#f87171",
                    bg = "#313244",
                    bold = true,
                },
            },
        },
    },
}
