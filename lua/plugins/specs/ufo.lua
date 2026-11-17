return {
    {
        "kevinhwang91/nvim-ufo",
        cond = not vim.g.vscode,
        dependencies = { "kevinhwang91/promise-async" },
        event = "VeryLazy",
        init = function()
            -- ufo 依赖的全局选项（README quickstart 要求）：ufo 内部把 foldmethod
            -- 转为 manual 并用 extmark 管折叠，foldlevel 必须足够大才能保持展开态
            -- foldcolumn=0：不显示折叠列（2026-11-17 用户要求；折叠统一走 Tab / za）
            -- 注意 options.lua 里的 foldopen/foldclose/foldsep/foldinner 在此配置下不生效
            vim.o.foldcolumn = "0"
            vim.o.foldlevel = 99
            vim.o.foldlevelstart = 99
            vim.o.foldenable = true
        end,
        config = function()
            local ufo = require("ufo")

            vim.keymap.set("n", "zR", ufo.openAllFolds, { desc = "折叠: 全部展开" })
            vim.keymap.set("n", "zM", ufo.closeAllFolds, { desc = "折叠: 全部折叠" })
            vim.keymap.set("n", "zr", ufo.openFoldsExceptKinds, { desc = "折叠: 按层级展开" })
            vim.keymap.set("n", "zm", ufo.closeFoldsWith, { desc = "折叠: 按层级折叠" })

            -- 折叠行上按 K：浮窗预览被折叠内容（VSCode 式），不在折叠行上则回退 LSP hover。
            -- nvim 0.11+ 的默认 hover K 是 LspAttach 时设的 buffer-local 映射，
            -- 会覆盖全局映射，故这里也要在 LspAttach 后设一份 buffer-local 的
            -- （本 autocmd 注册晚于核心默认键位的注册时机，callback 后执行、后写者胜）
            local function peekFoldOrHover()
                local winid = ufo.peekFoldedLinesUnderCursor()
                if not winid then
                    vim.lsp.buf.hover()
                end
            end
            vim.keymap.set("n", "K", peekFoldOrHover, { desc = "折叠预览 / LSP hover" })
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("UserUfoPeekKeymap", { clear = true }),
                callback = function(args)
                    vim.keymap.set("n", "K", peekFoldOrHover,
                        { buffer = args.buf, desc = "折叠预览 / LSP hover" })
                end,
            })

            -- <Tab> 进入/离开 LSP hover 属性浮窗（配合上面的 K）：
            -- 1) 原 buffer 上有打开的 hover 浮窗（open_floating_preview 在原 buffer 上
            --    设 lsp_floating_preview = 浮窗 winid）→ 进入浮窗
            -- 2) 已在浮窗内（浮窗窗口上有 lsp_floating_bufnr = 原 buffer id）→ 切回原窗口
            -- 3) 都不是 → 折叠/展开当前行（等价 za；仅 normal 模式，insert 模式的 <Tab>
            --    是 blink 的补全键，不受影响）
            -- 不冲突：ufo 折叠预览开着时其 buffer-local <Tab>（switch）优先级更高；
            -- aerial/nvim-tree/telescope 的 buffer-local <Tab> 同理。
            -- 已实测 0.12：切进浮窗不会触发 BufLeave 自动关闭（豁免名单含浮窗自身）。
            vim.keymap.set("n", "<Tab>", function()
                if vim.w.lsp_floating_bufnr then
                    -- 当前就在 hover 浮窗里：切回显示原 buffer 的普通窗口
                    for _, w in ipairs(vim.fn.win_findbuf(vim.w.lsp_floating_bufnr)) do
                        if vim.api.nvim_win_get_config(w).relative == "" then
                            vim.api.nvim_set_current_win(w)
                            return
                        end
                    end
                    return
                end
                local floatWin = vim.b.lsp_floating_preview
                if floatWin and vim.api.nvim_win_is_valid(floatWin) then
                    vim.api.nvim_set_current_win(floatWin)
                    return
                end
                -- ufo 无 toggleFold API，用原生 za（上面鼠标点击处理器同款做法）
                vim.cmd("normal! za")
            end, { desc = "折叠/展开当前块，或进出 LSP hover 浮窗" })


            ufo.setup({
                provider_selector = function(_, _, buftype)
                    -- 特殊 buftype（nofile/terminal/preview 等）不折叠；
                    -- 普通文件先按 treesitter 的 folds.scm 折叠（函数/类，与语法一致），
                    -- treesitter 不可用的 filetype 退到按缩进折叠
                    if buftype ~= "" then
                        return ""
                    end
                    return { "treesitter", "indent" }
                end,
                preview = {
                    win_config = { border = "rounded" },
                },
            })
        end,
    },
}
