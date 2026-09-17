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
                -- 屏蔽 '<' 作为触发字符（本列表会整体覆盖默认值，故默认三项须列全）。
                -- 原因：clangd 虽把 '<' 注册为 triggerCharacter，但在 std::cout<< 这类位置
                -- 它以 TriggerCharacter 模式返回**空结果且不声明 incomplete**，blink 遂把这个
                -- 空结果当成一次完整结果缓存下来；此后继续输入 M/y/C 时 ctx.id 不递增，
                -- list:is_valid_for_context() 判定「缓存仍然有效」，于是整个 <<MyC 过程
                -- 再也不会向 clangd 发请求，菜单里只剩 snippet 候选。
                -- 屏蔽后输入 '<' 会走 trigger.hide() 清空 context，下一次击键 ctx.id 递增，
                -- 缓存失效从而强制重新请求。'<' 之后本来也没有可用候选，不弹菜单无损失。
                trigger = {
                    show_on_blocked_trigger_characters = { " ", "\n", "\t", "<" },
                },
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
                            -- 只计算"光标处标识符的结尾"，用于向后扩展
                            local e = ctx.pos.col + 1 -- 0-based -> 1-based
                            while e <= #line and line:sub(e, e):match("[%w_]") do
                                e = e + 1
                            end
                            local word_end = e - 1

                            for _, item in ipairs(items) do
                                local r = item.textEdit and item.textEdit.range
                                -- 注意 ctx.pos 是 { row, col } 结构，没有 line 字段；
                                -- 写成 ctx.pos.line 会静默得到 nil，导致整块逻辑被跳过
                                if r and r.start.line == ctx.pos.row and r["end"].line == ctx.pos.row then
                                    -- 起点沿用 clangd 给的范围：它可能已包含 `.` 或 `->`
                                    -- （指针误用 `.` 时，clangd 会把 `.` 一起替换成 `->`），
                                    -- 盲目重算起点会破坏这个修正。
                                    -- 只把终点向后扩到整个标识符末尾，消除"词中间补全"的残尾。
                                    if word_end > r["end"].character then
                                        r["end"].character = word_end
                                    end
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

        -- 本 config 字段不可省：补丁必须在 setup 之后挂载。
        -- 删掉它 lazy 会退回默认的 setup(opts)，补丁就不再生效。
        config = function(_, opts)
            require("blink.cmp").setup(opts)

            -- 修复：补全接受时吞掉右侧 ) / ;（blink 上游的 range 补偿越界 bug）
            -- 根因、实测数据与删除时机见该文件头部注释
            require("config.blink_accept_fix")
        end,
    },
}
