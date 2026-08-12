return {
    {
        "hrsh7th/nvim-cmp",
        cond = not vim.g.vscode,
        event = { "InsertEnter", "CmdlineEnter" },
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
            "onsails/lspkind.nvim", -- 必须包含图标库
        },
        config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")
            local lspkind = require("lspkind")

            -- --- 统一补全逻辑函数 ---
            local tab_confirm = function(fallback)
                if cmp.visible() then
                    cmp.confirm({ select = true })
                elseif luasnip.expand_or_jumpable() then
                    luasnip.expand_or_jump()
                else
                    fallback()
                end
            end

            local select_next = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select })
            local select_prev = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select })

            -- --- 核心配置 ---
            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                experimental = { ghost_text = { hl_group = "CmpGhostText" } },
                preselect = cmp.PreselectMode.None,
                completion = {
                    completeopt = "menu,menuone,noselect",
                    keyword_length = 2, -- 减少过早触发，避免噪音补全
                },
                sorting = {
                    priority_weight = 2,
                    comparators = {
                        cmp.config.compare.recently_used,
                        cmp.config.compare.score,
                        cmp.config.compare.offset,
                        cmp.config.compare.exact,
                        cmp.config.compare.kind,
                        cmp.config.compare.sort_text,
                    },
                },

                -- 1. 窗口美化：圆角边框 + 颜色映射
                window = {
                    completion = cmp.config.window.bordered({
                        border = "rounded", -- 改为圆角
                        max_height = 10, -- 限制补全窗口高度，超出自动滚动
                        winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
                    }),
                    documentation = cmp.config.window.bordered({
                        border = "rounded",
                        winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
                    }),
                },

                -- 2. 格式化：增加图标和来源说明
                formatting = {
                    fields = { "kind", "abbr", "menu" }, -- 调整顺序：图标 | 名称 | 来源
                    format = lspkind.cmp_format({
                        mode = "symbol_text",  -- 图标 + 文本
                        maxwidth = 50,
                        ellipsis_char = "...",
                        before = function(entry, vim_item)
                            vim_item.menu = ({
                                nvim_lsp = "[LSP]",
                                luasnip  = "[Snippet]",
                                buffer   = "[Buffer]",
                                path     = "[Path]",
                            })[entry.source.name]
                            return vim_item
                        end,
                    }),
                },

                mapping = cmp.mapping.preset.insert({
                    ["<Down>"] = select_next,
                    ["<Up>"] = select_prev,
                    ["<Tab>"] = cmp.mapping(tab_confirm, { "i", "s" }),
                    ["<CR>"] = cmp.mapping.confirm({ select = false }),
                    ["<C-e>"] = cmp.mapping.abort(),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp", priority = 1000, max_item_count = 10 },
                    { name = "luasnip",  priority = 750,  max_item_count = 10 },
                    { name = "buffer",   priority = 500,  max_item_count = 8 },
                    { name = "path",     priority = 250,  max_item_count = 5 },
                }),
            })

            -- C/C++ 等强类型语言：禁用 buffer 源，避免模糊补全干扰 clangd 语义补全
            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "c", "cpp", "cuda", "objc", "objcpp" },
                callback = function()
                    cmp.setup.buffer({
                        sources = cmp.config.sources({
                            { name = "nvim_lsp", priority = 1000, max_item_count = 10 },
                            { name = "luasnip",  priority = 750,  max_item_count = 10 },
                            { name = "path",     priority = 250,  max_item_count = 5 },
                        }),
                    })
                end,
            })

            -- --- 命令行模式映射 ---
            -- 注意：cmdline 模式必须用 { c = fn } 包装，裸函数默认只对 insert 模式生效
            local cmdline_next = cmp.mapping(function(fallback)
                if cmp.visible() then
                    cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
                else
                    fallback() -- 补全列表未显示时，fallback 到 <Down> 原行为（历史记录）
                end
            end, { "c" })
            local cmdline_prev = cmp.mapping(function(fallback)
                if cmp.visible() then
                    cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
                else
                    fallback() -- 补全列表未显示时，fallback 到 <Up> 原行为（历史记录）
                end
            end, { "c" })

            local cmdline_mappings = cmp.mapping.preset.cmdline({
                ["<Down>"] = cmdline_next,
                ["<Up>"] = cmdline_prev,
                ["<Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.confirm({ select = true })
                    else
                        fallback()
                    end
                end, { "c" }),
                ["<CR>"] = cmp.mapping.confirm({ select = false }),
                ["<C-e>"] = cmp.mapping.abort(),
            })

            -- C-n / C-p 映射到 Up / Down，用于选择命令历史（补全未显示时生效）
            vim.keymap.set("c", "<C-n>", "<Down>", { remap = true })
            vim.keymap.set("c", "<C-p>", "<Up>",   { remap = true })

            cmp.setup.cmdline({ '/', '?' }, {
                mapping = cmdline_mappings,
                sources = { { name = 'buffer' } }
            })

            cmp.setup.cmdline(":", {
                mapping = cmdline_mappings,
                sources = cmp.config.sources({
                    { name = "path" }
                }, {
                    { name = "cmdline" }
                })
            })

            -- --- 3. 配色微调 (适配自定义 Gradient 主题) ---
            -- 将边框颜色设为紫色，让浮窗更有质感
            vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#bd93f9", bg = "NONE" })
            -- 调整 ghost text 颜色
            vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
            -- 选中项的背景色（使用深灰色）
            vim.api.nvim_set_hl(0, "PmenuSel", { bg = "#44475a", fg = "NONE" })
        end,
    },
}
