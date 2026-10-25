return {
    "goolord/alpha-nvim",
    cond = not vim.g.vscode,
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },

    config = function()
        local alpha = require("alpha")
        local dashboard = require("alpha.themes.dashboard")

        -- =========================
        -- Highlights（关键：独立出来，且随主题双轨）
        -- =========================
        -- 深色轨：德古拉系原值；浅色轨：gruvbox（gradient-theme 浅色已切
        -- gruvbox）。ColorScheme 事件在 gruvbox 应用后触发本函数重跑，
        -- 光标行链接到 AlphaButtonSelected，所以浅色选中底取 gruvbox 的
        -- bg1 #ebdbb2（与 CursorLine 色系一致，链接过去不冲突）。
        local function set_alpha_hl()
            if vim.g.gradient_theme_mode == "light" then
                vim.cmd([[
                    highlight AlphaHeader   guifg=#8f3f71 gui=bold
                    highlight AlphaButtons  guifg=#3c3836
                    highlight AlphaShortcut guifg=#79740e gui=bold
                    highlight AlphaFooter   guifg=#928374

                    highlight AlphaButtonSelected guibg=#ebdbb2 guifg=#3c3836
                    highlight link CursorLine AlphaButtonSelected
                ]])
            else
                vim.cmd([[
                    highlight AlphaHeader   guifg=#bd93f9 gui=bold
                    highlight AlphaButtons  guifg=#f8f8f2
                    highlight AlphaShortcut guifg=#50fa7b gui=bold
                    highlight AlphaFooter   guifg=#6272a4

                    highlight AlphaButtonSelected guibg=#44475a guifg=#f8f8f2
                    highlight link CursorLine AlphaButtonSelected
                ]])
            end
        end

        set_alpha_hl()

        -- 防止 colorscheme 覆盖（重点）；浅色轨 colorscheme gruvbox 后靠它恢复浅色值
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
                    -- 回调经 schedule_wrap 延迟执行，事件循环停顿（如按 ENTER 消息页）期间
                    -- 会排入多个回调；第一个已 stop+close 后，余下的再 close 同一 handle
                    -- 会报 "handle is already closing"，故先查 is_closing
                    if not timer:is_closing() then
                        timer:stop()
                        timer:close()
                    end
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
