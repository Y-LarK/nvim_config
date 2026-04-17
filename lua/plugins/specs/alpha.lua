return {
    "goolord/alpha-nvim",
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },

    config = function()
        local alpha = require("alpha")
        local dashboard = require("alpha.themes.dashboard")

        -- =========================
        -- Dracula Highlights（关键：独立出来）
        -- =========================
        local function set_alpha_hl()
            vim.cmd([[
                highlight AlphaHeader   guifg=#bd93f9 gui=bold
                highlight AlphaButtons  guifg=#f8f8f2
                highlight AlphaShortcut guifg=#50fa7b gui=bold
                highlight AlphaFooter   guifg=#6272a4

                highlight AlphaButtonSelected guibg=#44475a guifg=#f8f8f2
                highlight link CursorLine AlphaButtonSelected
            ]])
        end

        set_alpha_hl()

        -- 防止 colorscheme 覆盖（重点）
        vim.api.nvim_create_autocmd("ColorScheme", {
            callback = set_alpha_hl,
        })

        -- =========================
        -- Header
        -- =========================
        dashboard.section.header.val = {
            [[                                                           ]],
            [[   ███╗   ██╗ ███████╗  ██████╗  ██╗   ██╗ ██╗ ███╗   ███╗ ]],
            [[   ████╗  ██║ ██╔════╝ ██╔═══██╗ ██║   ██║ ██║ ████╗ ████║ ]],
            [[   ██╔██╗ ██║ █████╗   ██║   ██║ ██║   ██║ ██║ ██╔████╔██║ ]],
            [[   ██║╚██╗██║ ██╔══╝   ██║   ██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║ ]],
            [[   ██║ ╚████║ ███████╗ ╚██████╔╝  ╚████╔╝  ██║ ██║ ╚═╝ ██║ ]],
            [[   ╚═╝  ╚═══╝ ╚══════╝  ╚═════╝    ╚═══╝   ╚═╝ ╚═╝     ╚═╝ ]],
            [[                                                           ]],
        }

        -- =========================
        -- Buttons
        -- =========================
        dashboard.section.buttons.val = {
            dashboard.button("f", "  Find File", "<cmd>Telescope find_files<CR>"),
            dashboard.button("n", "  New File", "<cmd>ene <CR>"),
            dashboard.button("w", "󰈬  Search Text", "<cmd>Telescope live_grep<CR>"),

            dashboard.button("r", "󰄉  Recent Files", "<cmd>Telescope oldfiles<CR>"),
            dashboard.button("p", "  Projects", "<cmd>Telescope projects<CR>"),

            dashboard.button("e", "󰙅  Explorer", "<cmd>NvimTreeToggle<CR>"),

            dashboard.button("c", "  Config", "<cmd>e $MYVIMRC<CR>"),
            dashboard.button("l", "󰒲  Lazy", "<cmd>Lazy<CR>"),

            dashboard.button("q", "󰅚  Quit", "<cmd>qa<CR>"),
        }

        -- 防止闪烁
        dashboard.opts.opts.noautocmd = true

        -- =========================
        -- Footer
        -- =========================
        local function footer()
            local stats = require("lazy").stats()
            local datetime = os.date(" %Y-%m-%d   %H:%M:%S")
            local version = vim.version()

            return string.format(
                "%s  v%d.%d.%d   %d plugins in %.2fms",
                datetime,
                version.major,
                version.minor,
                version.patch,
                stats.count,
                stats.startuptime
            )
        end
        local timer = vim.loop.new_timer()

        timer:start(
            0,
            1000, -- 每 1 秒刷新一次
            vim.schedule_wrap(function()
                if vim.bo.filetype == "alpha" then
                    dashboard.section.footer.val = footer()
                    pcall(vim.cmd, "AlphaRedraw")
                else
                    timer:stop()
                    timer:close()
                end
            end)
        )
        dashboard.section.footer.val = footer()
        dashboard.opts.opts.noautocmd = true
        -- =========================
        -- Layout
        -- =========================
        dashboard.config.layout = {
            { type = "padding", val = 4 },
            dashboard.section.header,
            { type = "padding", val = 2 },
            dashboard.section.buttons,
            { type = "padding", val = 2 },
            dashboard.section.footer,
        }

        -- =========================
        -- Button HL
        -- =========================
        for _, button in ipairs(dashboard.section.buttons.val) do
            button.opts.hl = "AlphaButtons"
            button.opts.hl_shortcut = "AlphaShortcut"
        end

        dashboard.section.header.opts.hl = "AlphaHeader"
        dashboard.section.footer.opts.hl = "AlphaFooter"

        alpha.setup(dashboard.opts)
    end,
}
