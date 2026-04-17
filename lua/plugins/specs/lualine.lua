return {

    "nvim-lualine/lualine.nvim",

    lazy = false, -- 状态栏建议不开启懒加载，确保启动即显示

    dependencies = {

        "nvim-tree/nvim-web-devicons",

        "SmiteshP/nvim-navic",

    },

    config = function()
        -- 安全导入插件

        local ok_navic, navic = pcall(require, "nvim-navic")

        local ok_cmake, cmake = pcall(require, "cmake-tools")



        require("lualine").setup({

            options = {

                theme                = "auto",

                -- 【修改点】设置三角分割符

                component_separators = { left = "", right = "" },

                section_separators   = { left = "", right = "" },

                globalstatus         = true, -- 开启全局状态栏，所有窗口共用一个底部栏

                disabled_filetypes   = { statusline = { "dashboard", "alpha", "NvimTree" } },

            },

            sections = {

                -- 左侧：模式 (只显示首字母)

                lualine_a = {

                    { "mode", fmt = function(str) return str:sub(1, 1) end },

                },



                -- 左侧：Git 信息

                lualine_b = {

                    "branch",

                    {

                        "diff",

                        symbols = { added = " ", modified = " ", removed = " " },

                    },

                },



                -- 中间：文件名 + Navic 代码层级导航

                lualine_c = {

                    {

                        "filename",

                        path = 1, -- 1 为显示相对路径，更能看清文件位置

                        symbols = { modified = " ●", readonly = " 🔒", unnamed = "[No Name]" },

                    },

                    {

                        function()
                            return navic.get_location()
                        end,

                        cond = function()
                            return ok_navic and navic.is_available() and navic.get_location() ~= ""
                        end,

                        color = { fg = "#abb2bf" }, -- 稍微淡化颜色，突出文件名

                    },

                },



                -- 右侧：CMake 状态 + 诊断信息 + 类型

                lualine_x = {

                    -- CMake-Tools 状态集成

                    {

                        function()
                            local bt = cmake.get_build_type() or "Debug"

                            local lt = cmake.get_launch_target() or "N/A"

                            return " " .. bt .. " 󰄛 " .. lt
                        end,

                        cond = function()
                            return ok_cmake and cmake.is_cmake_project()
                        end,

                        color = { fg = "#98c379" }, -- 成功色

                    },

                    -- 诊断信息

                    {

                        "diagnostics",

                        sources = { "nvim_diagnostic" },

                        symbols = { error = " ", warn = " ", info = " ", hint = "󰛩 " },

                    },

                    "filesize",

                    "filetype",

                },



                -- 右侧：进度百分比

                lualine_y = { "progress" },



                -- 右侧：行列位置

                lualine_z = {

                    { "location", separator = { right = "" }, left_padding = 2 },

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
