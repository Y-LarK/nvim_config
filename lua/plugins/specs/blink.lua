return {
    {
        "saghen/blink.cmp",
        cond = not vim.g.vscode,
        event = { "InsertEnter", "CmdlineEnter" },
        dependencies = {
            "saghen/blink.lib",
            -- 常用 snippet 集合（可选）
            "rafamadriz/friendly-snippets",
        },
        -- 编译 Rust fuzzy matcher
        build = function()
            require("blink.cmp").build():pwait()
        end,
        ---@module 'blink.cmp'
        ---@type blink.cmp.Config
        opts = {
            -- 自定义键位（不用 preset）：
            --   ↑↓ / C-n / C-p 只移动高亮，不修改文本
            --   Tab / 回车 才真正替换文本
            keymap = {
                ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
                ["<C-e>"] = { "hide", "fallback" },
                ["<Tab>"] = { "select_and_accept", "snippet_forward", "fallback" },
                ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
                ["<C-n>"] = { "select_next", "fallback" },
                ["<C-p>"] = { "select_prev", "fallback" },
                ["<Down>"] = { "select_next", "fallback" },
                ["<Up>"] = { "select_prev", "fallback" },
                -- <CR> 不映射：回车保持默认行为（换行），不接受补全
            },

            appearance = {
                nerd_font_variant = "mono",
                -- 复用 nvim-cmp 的默认高亮组，兼容现有主题
                use_nvim_cmp_as_default = true,
            },

            completion = {
                documentation = { auto_show = true, auto_show_delay_ms = 200 },
                ghost_text = { enabled = true },
                list = {
                    selection = {
                        preselect = true,
                        -- false：选中候选时只在缓冲区做预览高亮，
                        -- 不实际插入文本；只有 Tab/回车才写入
                        auto_insert = false,
                    },
                },
                accept = {
                    -- 内置的自动补括号，替代原先 autopairs 与 cmp 的集成
                    auto_brackets = { enabled = true },
                },
            },

            sources = {
                default = { "lsp", "path", "snippets", "buffer" },
                -- 强类型语言禁用 buffer 源：避免模糊补全干扰 clangd 的语义补全
                per_filetype = {
                    c = { "lsp", "path", "snippets" },
                    cpp = { "lsp", "path", "snippets" },
                    cuda = { "lsp", "path", "snippets" },
                    objc = { "lsp", "path", "snippets" },
                    objcpp = { "lsp", "path", "snippets" },
                },
                -- 打满 2 个字符才触发（原来 cmp 的 keyword_length）
                min_keyword_length = 2,
                providers = {
                    lsp = {
                        -- clangd 的 textEdit.range 只覆盖"光标之前的前缀"，
                        -- 于是光标停在标识符中间补全时会留下残尾（pri|vate:i -> private:vate:i）。
                        -- 这里把范围扩展到整个标识符，让补全整体替换它。
                        transform_items = function(ctx, items)
                            local line = ctx.line
                            local p = ctx.pos.col + 1 -- 0-based -> 1-based，便于 string 操作
                            local s, e = p, p
                            while s > 1 and line:sub(s - 1, s - 1):match("[%w_]") do
                                s = s - 1
                            end
                            while e <= #line and line:sub(e, e):match("[%w_]") do
                                e = e + 1
                            end
                            if s >= e then
                                return items
                            end
                            for _, item in ipairs(items) do
                                if item.textEdit and item.textEdit.range then
                                    item.textEdit.range.start.character = s - 1
                                    item.textEdit.range["end"].character = e - 1
                                end
                            end
                            return items
                        end,
                    },
                },
            },

            signature = { enabled = true },
            -- 本机有 cargo，使用 Rust fuzzy matcher
            fuzzy = { implementation = "prefer_rust_with_warning" },
        },
    },
}
