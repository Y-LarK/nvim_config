return {

    "nvim-lualine/lualine.nvim",
    cond = not vim.g.vscode,
    lazy = false,

    dependencies = {
        "nvim-tree/nvim-web-devicons",
        "SmiteshP/nvim-navic",
    },

    config = function()
        local ok_navic, navic = pcall(require, "nvim-navic")
        local ok_cmake, cmake = pcall(require, "cmake-tools")

        -- 双模式主题，跟随 gradient-theme 的深浅切换。模式信号读
        -- vim.g.gradient_theme_mode（由 gradient-theme 的 watcher /
        -- ThemeLight / ThemeDark 维护）；lualine 在 OptionSet background
        -- 时会重新 setup 并重新调用 options.theme 函数，而
        -- gradient-theme.apply() 每次都重设 background，故模式切换后
        -- 这里取到的就是新模式的表，无需本插件再监听任何事件。
        -- dark 与旧版固定主题逐值一致；light 取自 gruvbox 浅色板
        -- （gradient-theme 浅色轨已切 gruvbox，faded 语法色 + bg0-4 中性色）：
        --   - 芯片(a/z)字用 light0 #fbf1c7；command 芯片反转为 fg1 深底
        --   - b/y 背景 bg2 #d5c4a1 比 c/x 正文 bg1 #ebdbb2 略深，对应
        --     深色版 gray_bg 比 dim_bg 略亮的层次关系
        --   - inactive 背景 light0_soft #f2e5bc（最不显眼的浅底）
        local themes = {
            dark = {
                normal   = { a = { fg = "#1e2030", bg = "#cfacff" }, b = { fg = "#cfacff", bg = "#3a3d4e" }, c = { fg = "#b8c0d8", bg = "#252838" }, x = { fg = "#b8c0d8", bg = "#252838" }, y = { fg = "#cfacff", bg = "#3a3d4e" }, z = { fg = "#1e2030", bg = "#cfacff" } },
                insert   = { a = { fg = "#1e2030", bg = "#8296d4" }, b = { fg = "#8296d4", bg = "#3a3d4e" }, c = { fg = "#b8c0d8", bg = "#252838" }, x = { fg = "#b8c0d8", bg = "#252838" }, y = { fg = "#8296d4", bg = "#3a3d4e" }, z = { fg = "#1e2030", bg = "#8296d4" } },
                visual   = { a = { fg = "#1e2030", bg = "#ffc880" }, b = { fg = "#ffc880", bg = "#3a3d4e" }, c = { fg = "#b8c0d8", bg = "#252838" }, x = { fg = "#b8c0d8", bg = "#252838" }, y = { fg = "#ffc880", bg = "#3a3d4e" }, z = { fg = "#1e2030", bg = "#ffc880" } },
                replace  = { a = { fg = "#1e2030", bg = "#ff6b6b" }, b = { fg = "#ff6b6b", bg = "#3a3d4e" }, c = { fg = "#b8c0d8", bg = "#252838" }, x = { fg = "#b8c0d8", bg = "#252838" }, y = { fg = "#ff6b6b", bg = "#3a3d4e" }, z = { fg = "#1e2030", bg = "#ff6b6b" } },
                command  = { a = { fg = "#1e2030", bg = "#ffffff" }, b = { fg = "#ffffff", bg = "#3a3d4e" }, c = { fg = "#b8c0d8", bg = "#252838" }, x = { fg = "#b8c0d8", bg = "#252838" }, y = { fg = "#ffffff", bg = "#3a3d4e" }, z = { fg = "#1e2030", bg = "#ffffff" } },
                inactive = { a = { fg = "#b8c0d8", bg = "#1e2030" }, b = { fg = "#b8c0d8", bg = "#1e2030" }, c = { fg = "#b8c0d8", bg = "#1e2030" }, x = { fg = "#b8c0d8", bg = "#1e2030" }, y = { fg = "#b8c0d8", bg = "#1e2030" }, z = { fg = "#b8c0d8", bg = "#1e2030" } },
            },
            light = {
                normal   = { a = { fg = "#fbf1c7", bg = "#8f3f71" }, b = { fg = "#8f3f71", bg = "#d5c4a1" }, c = { fg = "#665c54", bg = "#ebdbb2" }, x = { fg = "#665c54", bg = "#ebdbb2" }, y = { fg = "#8f3f71", bg = "#d5c4a1" }, z = { fg = "#fbf1c7", bg = "#8f3f71" } },
                insert   = { a = { fg = "#fbf1c7", bg = "#076678" }, b = { fg = "#076678", bg = "#d5c4a1" }, c = { fg = "#665c54", bg = "#ebdbb2" }, x = { fg = "#665c54", bg = "#ebdbb2" }, y = { fg = "#076678", bg = "#d5c4a1" }, z = { fg = "#fbf1c7", bg = "#076678" } },
                visual   = { a = { fg = "#fbf1c7", bg = "#b57614" }, b = { fg = "#b57614", bg = "#d5c4a1" }, c = { fg = "#665c54", bg = "#ebdbb2" }, x = { fg = "#665c54", bg = "#ebdbb2" }, y = { fg = "#b57614", bg = "#d5c4a1" }, z = { fg = "#fbf1c7", bg = "#b57614" } },
                replace  = { a = { fg = "#fbf1c7", bg = "#9d0006" }, b = { fg = "#9d0006", bg = "#d5c4a1" }, c = { fg = "#665c54", bg = "#ebdbb2" }, x = { fg = "#665c54", bg = "#ebdbb2" }, y = { fg = "#9d0006", bg = "#d5c4a1" }, z = { fg = "#fbf1c7", bg = "#9d0006" } },
                command  = { a = { fg = "#f9f5d7", bg = "#3c3836" }, b = { fg = "#3c3836", bg = "#d5c4a1" }, c = { fg = "#665c54", bg = "#ebdbb2" }, x = { fg = "#665c54", bg = "#ebdbb2" }, y = { fg = "#3c3836", bg = "#d5c4a1" }, z = { fg = "#f9f5d7", bg = "#3c3836" } },
                inactive = { a = { fg = "#a89984", bg = "#f2e5bc" }, b = { fg = "#a89984", bg = "#f2e5bc" }, c = { fg = "#a89984", bg = "#f2e5bc" }, x = { fg = "#a89984", bg = "#f2e5bc" }, y = { fg = "#a89984", bg = "#f2e5bc" }, z = { fg = "#a89984", bg = "#f2e5bc" } },
            },
        }

        -- 按 Typora 口径统计字数：CJK 每字符计 1，其余按 ASCII 单词计 1；
        -- 标点、空格和 Markdown 符号不计。结果按 bufnr + changedtick 缓存，
        -- 避免大 md 文件每次状态栏重绘都全量扫描。
        local function isCjkChar(cp)
            return (cp >= 0x3400 and cp <= 0x4DBF)   -- 扩展 A
                or (cp >= 0x4E00 and cp <= 0x9FFF)   -- 基本汉字
                or (cp >= 0xF900 and cp <= 0xFAFF)   -- 兼容汉字
                or (cp >= 0x3040 and cp <= 0x30FF)   -- 日文假名
                or (cp >= 0xAC00 and cp <= 0xD7AF)   -- 谚文音节
        end

        local function isAsciiWordChar(cp)
            return (cp >= 48 and cp <= 57)    -- 0-9
                or (cp >= 65 and cp <= 90)    -- A-Z
                or (cp >= 97 and cp <= 122)   -- a-z
                or cp == 95                   -- _
        end

        local wordCountCache = { bufnr = -1, tick = -1, value = 0 }
        local function typoraWordCount()
            local bufnr = vim.api.nvim_get_current_buf()
            local tick = vim.api.nvim_buf_get_changedtick(bufnr)
            if wordCountCache.bufnr == bufnr and wordCountCache.tick == tick then
                return wordCountCache.value
            end

            local text = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
            -- 用码点遍历而非正则：Vim 的 \%uXXXX 在字符类中不可靠。
            local cjkChars, latinWords, inWord = 0, 0, false
            for _, cp in ipairs(vim.fn.str2list(text)) do
                if isCjkChar(cp) then
                    cjkChars = cjkChars + 1
                    inWord = false
                elseif isAsciiWordChar(cp) then
                    if not inWord then latinWords = latinWords + 1 end
                    inWord = true
                else
                    inWord = false
                end
            end

            wordCountCache = { bufnr = bufnr, tick = tick, value = cjkChars + latinWords }
            return wordCountCache.value
        end

        require("lualine").setup({
            options = {
                theme                = function()
                    return vim.g.gradient_theme_mode == "light" and themes.light or themes.dark
                end,
                component_separators = { left = "", right = "" },
                section_separators   = { left = "", right = "" },
                globalstatus         = true,
                disabled_filetypes   = { statusline = { "dashboard", "alpha", "NvimTree" } },
            },

            sections = {
                lualine_a = {
                    { "mode", fmt = function(str) return str:sub(1, 1) end },
                },
                lualine_b = {
                    "branch",
                    { "diff", symbols = { added = " ", modified = " ", removed = " " } },
                },
                lualine_c = {
                    { "filename", path = 1, symbols = { modified = " ●", readonly = " 🔒", unnamed = "[No Name]" } },
                    {
                        function() return navic.get_location() end,
                        cond = function() return ok_navic and navic.is_available() and navic.get_location() ~= "" end,
                        -- 不指定 color：继承所在 c 段的模式配色，
                        -- 路径里的图标/分隔符色由 gradient-theme 的 NavicIcons/NavicSeparator 管
                    },
                },
                lualine_x = {
                    {
                        function() return "字: " .. typoraWordCount() end,
                        cond = function() return vim.bo.filetype == "markdown" end,
                    },
                    {
                        function()
                            local bt = cmake.get_build_type() or "Debug"
                            local lt = cmake.get_launch_target() or "N/A"
                            return " " .. bt .. " 󰄛 " .. lt
                        end,
                        cond = function() return ok_cmake and cmake.is_cmake_project() end,
                        -- color 用函数：lualine 每次绘制时求值，深浅切换后无需重建组件。
                        -- themes 表不能塞 mode 之外的多余键（lualine 会把它当模式遍历），
                        -- 绿色单独放一张小映射
                        color = function()
                            local green = { dark = "#66ff8d", light = "#79740e" }
                            return { fg = vim.g.gradient_theme_mode == "light" and green.light or green.dark }
                        end,
                    },
                    { "diagnostics", sources = { "nvim_diagnostic" }, symbols = { error = " ", warn = " ", info = " ", hint = "󰛩 " } },
                    "filesize",
                    "filetype",
                },
                lualine_y = { "progress" },
                lualine_z = {
                    { "location", left_padding = 1, right_padding = 1 },
                },
            },

            inactive_sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_c = { "filename" },
                lualine_x = { "location" },
                lualine_y = {},
                lualine_z = {},
            },
        })
    end,
}
