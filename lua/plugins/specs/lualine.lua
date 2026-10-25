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
        -- dark 与旧版固定主题逐值一致；light 取自 gradient-theme 浅色板：
        --   - 芯片(a/z)字用白色；command 芯片反转为深底浅字（浅色下白底白字不可见）
        --   - b/y 背景 #c9d2e0 比 c/x 正文 #dde3ee 略深，对应深色版
        --     gray_bg(#3a3d4e) 比 dim_bg(#252838) 略亮的层次关系
        --   - inactive 背景 #eceff4 对应深色版 #1e2030（statusline_nc_bg 语义）
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
                normal   = { a = { fg = "#ffffff", bg = "#904deb" }, b = { fg = "#904deb", bg = "#c9d2e0" }, c = { fg = "#5d6b85", bg = "#dde3ee" }, x = { fg = "#5d6b85", bg = "#dde3ee" }, y = { fg = "#904deb", bg = "#c9d2e0" }, z = { fg = "#ffffff", bg = "#904deb" } },
                insert   = { a = { fg = "#ffffff", bg = "#466bde" }, b = { fg = "#466bde", bg = "#c9d2e0" }, c = { fg = "#5d6b85", bg = "#dde3ee" }, x = { fg = "#5d6b85", bg = "#dde3ee" }, y = { fg = "#466bde", bg = "#c9d2e0" }, z = { fg = "#ffffff", bg = "#466bde" } },
                visual   = { a = { fg = "#ffffff", bg = "#a6640d" }, b = { fg = "#a6640d", bg = "#c9d2e0" }, c = { fg = "#5d6b85", bg = "#dde3ee" }, x = { fg = "#5d6b85", bg = "#dde3ee" }, y = { fg = "#a6640d", bg = "#c9d2e0" }, z = { fg = "#ffffff", bg = "#a6640d" } },
                replace  = { a = { fg = "#ffffff", bg = "#e02424" }, b = { fg = "#e02424", bg = "#c9d2e0" }, c = { fg = "#5d6b85", bg = "#dde3ee" }, x = { fg = "#5d6b85", bg = "#dde3ee" }, y = { fg = "#e02424", bg = "#c9d2e0" }, z = { fg = "#ffffff", bg = "#e02424" } },
                command  = { a = { fg = "#fbf9fb", bg = "#2e3440" }, b = { fg = "#2e3440", bg = "#c9d2e0" }, c = { fg = "#5d6b85", bg = "#dde3ee" }, x = { fg = "#5d6b85", bg = "#dde3ee" }, y = { fg = "#2e3440", bg = "#c9d2e0" }, z = { fg = "#fbf9fb", bg = "#2e3440" } },
                inactive = { a = { fg = "#5d6b85", bg = "#eceff4" }, b = { fg = "#5d6b85", bg = "#eceff4" }, c = { fg = "#5d6b85", bg = "#eceff4" }, x = { fg = "#5d6b85", bg = "#eceff4" }, y = { fg = "#5d6b85", bg = "#eceff4" }, z = { fg = "#5d6b85", bg = "#eceff4" } },
            },
        }

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
                        function()
                            local wc = vim.fn.wordcount()
                            return "W:" .. wc.words .. " C:" .. wc.chars
                        end,
                        cond = function() return vim.bo.filetype == "markdown" end,
                    },
                    {
                        function()
                            local bt = cmake.get_build_type() or "Debug"
                            local lt = cmake.get_launch_target() or "N/A"
                            return " " .. bt .. " 󰄛 " .. lt
                        end,
                        cond = function() return ok_cmake and cmake.is_cmake_project() end,
                        -- color 用函数：lualine 每次绘制时求值，深浅切换后无需重建组件
                        color = function()
                            local t = vim.g.gradient_theme_mode == "light" and themes.light or themes.dark
                            -- 两套色板里绿色都等于 insert 芯片的底色，直接取同一来源
                            return { fg = t.insert.a.bg }
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
