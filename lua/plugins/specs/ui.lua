-- bufferline 标签栏高亮双轨：深色与历史值逐字一致，浅色取 gruvbox 浅色板。
-- 整条不画底露出终端背景；选中与否只靠文字颜色 + 左侧指示竖条区分
-- （nvim 高亮无 alpha 通道，不存在半透明底，「当前标签盖淡底」的 VSCode
-- 效果做不了）。诊断未选中标签只留图标色，当前标签用主题诊断色。
local function bufferline_highlights()
    local is_light = vim.g.gradient_theme_mode == "light"
    local hls = {
        fill = { bg = "NONE" },
        background = { fg = is_light and "#7c6f64" or "#8f97b0", bg = "NONE" },
        buffer_visible = { fg = is_light and "#665c54" or "#b8c0d8", bg = "NONE" },
        buffer_selected = { fg = is_light and "#3c3836" or "#ffffff", bg = "NONE", bold = true },
        -- 分隔线颜色 = 底色系，视觉上只有间距不出现竖线（配合 thin separator_style）
        separator = { fg = is_light and "#d5c4a1" or "#3a3d4e", bg = "NONE" },
        separator_visible = { fg = is_light and "#d5c4a1" or "#3a3d4e", bg = "NONE" },
        -- thin 模式下分隔符统一走 BufferLineSeparator 组，这组实际不生效，留着以防改回 slant
        separator_selected = { fg = "NONE", bg = "NONE" },
        modified = { fg = is_light and "#b57614" or "#ffc880", bg = "NONE" },
        modified_selected = { fg = is_light and "#b57614" or "#ffc880", bg = "NONE" },
        close_button = { fg = is_light and "#7c6f64" or "#8f97b0", bg = "NONE" },
        close_button_selected = { fg = is_light and "#3c3836" or "#ffffff", bg = "NONE" },
        -- 当前标签左侧的指示竖条
        indicator_selected = { fg = is_light and "#8f3f71" or "#cfacff", bg = "NONE" },
        error = { bg = "NONE" },
        error_selected = { fg = is_light and "#9d0006" or "#ff6b6b", bg = "NONE", bold = true },
        warning = { bg = "NONE" },
        warning_selected = { fg = is_light and "#b57614" or "#ffc880", bg = "NONE", bold = true },
        info = { bg = "NONE" },
        info_selected = { fg = is_light and "#427b58" or "#a4f4ff", bg = "NONE", bold = true },
        hint = { bg = "NONE" },
        hint_selected = { fg = is_light and "#076678" or "#8296d4", bg = "NONE", bold = true },
    }
    -- bufferline 默认以 default=true 写入组（themable），对已定义的组不生效；
    -- 主题切换重挂时必须显式 default=false 才能覆盖旧色。
    -- 注意：这里要为每一项都加，且 M.set 用 if_nil 读取，false 会被保留。
    for _, hl in pairs(hls) do
        hl.default = false
    end
    return hls
end

return {
    -- 1. Nvim-Notify: 保持不变
    {
        "rcarriga/nvim-notify",
        cond = not vim.g.vscode,
        opts = {
            timeout = 3000,
            stages = "fade",
            -- fade 动画需要一个实色做混底；用函数按模式动态取
            -- （nvim-notify 文档明确支持 "a function returning an RGB code
            -- for dynamic values"）。浅色取 kitty matugen 的 surface 白。
            background_colour = function()
                return vim.g.gradient_theme_mode == "light" and "#fbf9fb" or "#282a36"
            end,
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
        -- opts 必须惰性求值（VeryLazy setup 时刻才展开）：此时 gradient-theme
        -- 已完成启��检测，vim.g.gradient_theme_mode 可靠。直接写表会在 spec
        -- 扫描期求值（早于主题初始化），模式永远读成 nil。
        opts = function()
            return {
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
            highlights = bufferline_highlights(),
            }
        end,
        config = function(_, opts)
            require("bufferline").setup(opts)
            -- 只把 BufferLine* 组的 bg 设成 NONE 还不够：渲染 tabline 时，背景为 NONE
            -- 的单元格会落到兜底高亮 TabLineFill 上。它 link 到 TabLine -> StatusLineNC，
            -- 而本机主题给 StatusLineNC 设了 #1e2030 的实色底，于是整条被染回实心色带，
            -- 遮住终端的半透明模糊背景。这里把兜底也设为透明（已实测：设完底色消失）。
            vim.api.nvim_set_hl(0, "TabLineFill", { bg = "NONE" })

            -- 期望版式：标签栏 -> 下划线 -> 空白 -> 编辑区。
            -- 线必须画在 tabline 这一行内部（贴其底部），因为 nvim 的 tabline 与 winbar
            -- 都只有一行（实测塞换行符不会换行），没法在两者之间再插一行。
            -- 所以：underline 挂在标签栏各组上，winbar 则专门留作那行空白。
            -- 给某个 BufferLine* 组补上下划线。不做「已有 underline 就跳过」的
            -- 早退：主题切换后要重刷线色（sp 随模式变），无条件重设才是幂等的
            local function add_underline(name)
                -- 线色取主题色板中间档：深色 #3a3d4e > #2c2f3c > [#252838] > #1e2030；
                -- 浅色用 gruvbox bg3 #bdae93
                local sp = vim.g.gradient_theme_mode == "light" and "#bdae93" or "#252838"
                -- 关键：bufferline 建的组都带 default = true 标记。若把它原样 set 回去，
                -- nvim 会当成「默认定义」，只在组未定义时生效，于是不会覆盖已有高亮，
                -- underline 白加（这一点是实测踩出来的，读回值纹丝不动）。
                -- update = true：nvim_set_hl 默认整体替换组定义，必须显式合并，
                -- 否则 fg/bg 会被清空（见 nvim api.txt nvim_set_hl）。
                vim.api.nvim_set_hl(0, name, { underline = true, sp = sp, default = false, update = true })
            end

            -- 不能只列举主要组：图标（devicon）用的是各自独立��高亮组
            -- （BufferLine*Icon*），漏掉它们下划线就会在图标处断开。
            local function add_underline_all()
                for _, name in ipairs(vim.fn.getcompletion("BufferLine", "highlight")) do
                    add_underline(name)
                end
            end
            add_underline_all()

            -- 图标组是 bufferline 首次渲染时懒创建并缓存（icon_hl_cache）的，
            -- setup 那一刻根本不存在，靠 autocmd 补会晚一拍 —— 表现为
            -- 「刚打开时线是断的，按 Alt+,/Alt+. 切一次标签后才连上」。
            -- 所以直接包住它的创建函数：哪一组刚建出来就立刻补上。
            -- 注意：此处依赖 bufferline 内部 API，插件升级后需要重测。
            -- 守卫只包一层：主题切换重入 setup 时不再叠包，否则包装层越叠越深。
            local bl_highlights = require("bufferline.highlights")
            if not bl_highlights.__gradient_underline_wrapped then
                bl_highlights.__gradient_underline_wrapped = true
                local orig_set_icon_highlight = bl_highlights.set_icon_highlight
                bl_highlights.set_icon_highlight = function(...)
                    local icon_hl = orig_set_icon_highlight(...)
                    if type(icon_hl) == "string" then add_underline(icon_hl) end
                    return icon_hl
                end
            end

            -- 主题切换（gradient-theme apply 完成后发 User 事件）：bufferline
            -- 自己的 ColorScheme 回调会先把 user config 里的旧色表刷回来，
            -- 这里在其后重挂新模式的高亮并重刷下划线
            vim.api.nvim_create_autocmd("User", {
                group = vim.api.nvim_create_augroup("BufferLineGradientTheme", { clear = true }),
                pattern = "GradientThemeApplied",
                callback = function()
                    require("bufferline").setup(
                        vim.tbl_deep_extend("force", opts, { highlights = bufferline_highlights() })
                    )
                    add_underline_all()
                end,
            })

            -- 标签栏与编辑区之间空一行。winbar 是窗口局部选项，用 autocmd 按 buftype
            -- 决定是否显示，避免 telescope / 文件树 / 终端浮窗里也冒出一行空白。
            -- 注意：高亮前缀必须写在 winbar 字符串最外层 —— 写成 "%{表达式返回 '%#Group#'}"
            -- 不生效，求值结果不会被二次解析成高亮切换（已实测）。
            vim.api.nvim_set_hl(0, "TabLineSpacer", { bg = "NONE" })

            local function apply_tabline_spacer()
                if vim.bo.buftype == "" then
                    -- %= 用空格填满剩余宽度且沿用当前高亮组，不必手算列数
                    vim.wo.winbar = "%#TabLineSpacer#%="
                else
                    vim.wo.winbar = ""
                end
            end

            vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "FileType" }, {
                group = vim.api.nvim_create_augroup("TabLineSpacer", { clear = true }),
                callback = apply_tabline_spacer,
            })
            apply_tabline_spacer()
        end,
    },
}
