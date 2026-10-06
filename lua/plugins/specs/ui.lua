return {
    -- 1. Nvim-Notify: 保持不变
    {
        "rcarriga/nvim-notify",
        cond = not vim.g.vscode,
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
        cond = not vim.g.vscode,
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
                hover = {
                    enabled = false,
                },
                signature = {
                    enabled = false,
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
        cond = not vim.g.vscode,
        version = "*",
        dependencies = "nvim-tree/nvim-web-devicons",
        -- 注意：不能用 cmd 懒加载。bufferline 靠 setup 时接管 tabline 来画标签栏，
        -- 用 cmd 会导致启动时插件未加载、顶部空白，直到手动执行切换命令才"冒出来"。
        event = "VeryLazy",
        opts = {
            options = {
                mode = "buffers",
                -- 不能用 "curve"：它不是合法值，源码 ui.lua:256 (sep_chars[style] or sep_chars.thin)
                -- 会静默降级成 thin，且不报错。合法值仅：
                -- thin | thick | slant | slope | padded_slant | padded_slope
                -- 用 thin：标签是规整矩形，不做斜角/三角造型。
                -- 配合下面 separator 的颜色 = 底色，视觉上标签之间只有间距、不出现竖线。
                separator_style = "thin",
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
            -- 目标是 VSCode 风格的标签栏，并与终端「半透明 + 模糊」的背景融合。
            -- 关键约束：nvim 的高亮没有 alpha 通道，背景只有「实色」与「NONE（全透明）」两种状态，
            -- 不存在半透明。所以这里所有背景一律 NONE，让终端的模糊背景透出来；
            -- 选中与否只靠文字颜色 + 左侧指示竖条区分。
            -- 代价：VSCode 那种「当前标签盖一层淡底色」无法还原，那是半透明才有的效果。
            highlights = {
                -- 整条不画底，露出终端背景
                fill = {
                    bg = "NONE",
                },
                -- 未选中标签：灰字
                background = {
                    fg = "#8f97b0",
                    bg = "NONE",
                },
                -- 分屏中可见但非当前的标签
                buffer_visible = {
                    fg = "#b8c0d8",
                    bg = "NONE",
                },
                -- 当前标签：纯白加粗（VSCode 的当前标签文字最亮）
                buffer_selected = {
                    fg = "#ffffff",
                    bg = "NONE",
                    bold = true,
                },
                -- 标签之间的分隔线：VSCode 有淡竖线，用 thin 的细竖线 + 暗色模拟
                separator = {
                    fg = "#3a3d4e",
                    bg = "NONE",
                },
                separator_visible = {
                    fg = "#3a3d4e",
                    bg = "NONE",
                },
                -- thin 模式下分隔符统一走 BufferLineSeparator 组，这组实际不生效，留着以防改回 slant
                separator_selected = {
                    fg = "NONE",
                    bg = "NONE",
                },
                -- 未保存标记与关闭按钮
                -- （当前 show_buffer_close_icons = false 用不到 close_button）
                modified = {
                    fg = "#ffc880",
                    bg = "NONE",
                },
                modified_selected = {
                    fg = "#ffc880",
                    bg = "NONE",
                },
                close_button = {
                    fg = "#8f97b0",
                    bg = "NONE",
                },
                close_button_selected = {
                    fg = "#ffffff",
                    bg = "NONE",
                },
                -- 当前标签左侧的指示竖条：近似 VSCode 当前标签的高亮线（位置不同，在左侧）
                indicator_selected = {
                    fg = "#cfacff",
                    bg = "NONE",
                },
                -- 诊断：未选中标签只留图标色，当前标签用主题诊断色
                error = {
                    bg = "NONE",
                },
                error_selected = {
                    fg = "#ff6b6b",
                    bg = "NONE",
                    bold = true,
                },
                warning = {
                    bg = "NONE",
                },
                warning_selected = {
                    fg = "#ffc880",
                    bg = "NONE",
                    bold = true,
                },
                info = {
                    bg = "NONE",
                },
                info_selected = {
                    fg = "#a4f4ff",
                    bg = "NONE",
                    bold = true,
                },
                hint = {
                    bg = "NONE",
                },
                hint_selected = {
                    fg = "#8296d4",
                    bg = "NONE",
                    bold = true,
                },
            },
        },
        config = function(_, opts)
            require("bufferline").setup(opts)
            -- 只把 BufferLine* 组的 bg 设成 NONE 还不够：渲染 tabline 时，背景为 NONE
            -- 的单元格会落到兜底高亮 TabLineFill 上。它 link 到 TabLine -> StatusLineNC，
            -- 而本机主题给 StatusLineNC 设了 #1e2030 的实色底，于是整条被染回实心色带，
            -- 遮住终端的半透明模糊背景。这里把兜底也设为透明（已实测：设完底色消失）。
            vim.api.nvim_set_hl(0, "TabLineFill", { bg = "NONE" })
        end,
    },
}
