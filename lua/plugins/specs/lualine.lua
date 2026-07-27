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

        -- 固定主题，所有文件类型一致
        local colors = {
            purple  = "#cfacff",
            green   = "#66ff8d",
            orange  = "#ffc880",
            red     = "#ff6b6b",
            blue    = "#8296d4",
            dark    = "#1e2030",
            white   = "#ffffff",
            comment = "#b8c0d8",
            gray_bg = "#3a3d4e",
            dim_bg  = "#252838",
        }

        local theme = {
            normal   = { a = { fg = colors.dark, bg = colors.purple }, b = { fg = colors.purple, bg = colors.gray_bg }, c = { fg = colors.comment, bg = colors.dim_bg }, x = { fg = colors.comment, bg = colors.dim_bg }, y = { fg = colors.purple, bg = colors.gray_bg }, z = { fg = colors.dark, bg = colors.purple } },
            insert   = { a = { fg = colors.dark, bg = colors.blue }, b = { fg = colors.blue, bg = colors.gray_bg }, c = { fg = colors.comment, bg = colors.dim_bg }, x = { fg = colors.comment, bg = colors.dim_bg }, y = { fg = colors.blue, bg = colors.gray_bg }, z = { fg = colors.dark, bg = colors.blue } },
            visual   = { a = { fg = colors.dark, bg = colors.orange }, b = { fg = colors.orange, bg = colors.gray_bg }, c = { fg = colors.comment, bg = colors.dim_bg }, x = { fg = colors.comment, bg = colors.dim_bg }, y = { fg = colors.orange, bg = colors.gray_bg }, z = { fg = colors.dark, bg = colors.orange } },
            replace  = { a = { fg = colors.dark, bg = colors.red }, b = { fg = colors.red, bg = colors.gray_bg }, c = { fg = colors.comment, bg = colors.dim_bg }, x = { fg = colors.comment, bg = colors.dim_bg }, y = { fg = colors.red, bg = colors.gray_bg }, z = { fg = colors.dark, bg = colors.red } },
            command  = { a = { fg = colors.dark, bg = colors.white }, b = { fg = colors.white, bg = colors.gray_bg }, c = { fg = colors.comment, bg = colors.dim_bg }, x = { fg = colors.comment, bg = colors.dim_bg }, y = { fg = colors.white, bg = colors.gray_bg }, z = { fg = colors.dark, bg = colors.white } },
            inactive = { a = { fg = colors.comment, bg = colors.dark }, b = { fg = colors.comment, bg = colors.dark }, c = { fg = colors.comment, bg = colors.dark }, x = { fg = colors.comment, bg = colors.dark }, y = { fg = colors.comment, bg = colors.dark }, z = { fg = colors.comment, bg = colors.dark } },
        }

        require("lualine").setup({
            options = {
                theme                = theme,
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
                        color = { fg = colors.comment, bg = colors.dim_bg },
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
                        color = { fg = colors.green },
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
