-- gradient-theme —— 跟随 dms 深浅模式的双色板主题
--
-- 模式信号：DMS 切深浅时会以对应 --mode 重跑 matugen，后者重写
--   ~/.cache/niri-quickshell/colors.json
-- 取其中 surface 的 Rec.709 亮度判模式（> 0.5 为浅色），口径与
-- ~/.local/bin/theme-mode-sync 完全一致。文件缺失/解析失败一律回退 dark。
-- 运行中通过 uv_fs_event 监听该文件所在目录（监听文件本身会在 matugen
-- rename 替换时失效），防抖后重判，模式变化才重新应用 —— 换壁纸不切
-- 模式时幂等跳过。
--
-- 背景全部 transparent，跟随终端：深色下是 Nord 深底，浅色下是
-- Material You surface（kitty 的 matugen-background.conf 提供浅底）。
-- 浅色色板与 kitty 浅色 ANSI 同源（Nord 加深版，对白底对比度 ≥4.5），
-- 保证终端内 nvim 与周边（tmux/btop 等）观感统一。

local M = {}

local COLORS_DIR = vim.fs.normalize("~/.cache/niri-quickshell")
local COLORS_FILE = COLORS_DIR .. "/colors.json"

-- 两套色板。dark 与旧版逐值一致（深色模式零变化）；
-- light 彩色语义按 kitty 浅色 ANSI（Nord 加深版）映射：
--   red→color1  orange→color16  yellow→color3  green→color2
--   cyan→color6 blue→color4    purple→color5  pink→color13
local palettes = {
    dark = {
        bg = "#1e2030",
        fg = "#ffffff",
        fg_dim = "#dce4f0",
        comment = "#b8c0d8",
        selection = "#3a3d4e",
        cursorline = "#252838",
        match = "#4d5b88",
        visual = "#8296d4",
        red = "#ff6b6b",
        orange = "#ffc880",
        yellow = "#f6ffa0",
        green = "#66ff8d",
        cyan = "#a4f4ff",
        blue = "#8296d4",
        purple = "#cfacff",
        pink = "#ff8dd4",
        line_nr = "#9098b8",
        search_fg = "#1e2030",
        search_bg = "#f6ffa0",
        incsearch_bg = "#ffc880",
        end_of_buffer = "#3a3d4e",
        ibl_indent = "#586080",
        ibl_scope = "#9098b8",
        ghost = "#a0a8c0",
        inlay = "#b8c0d8",
        code_bg = "#222838",
        inline_hl_bg = "#2c2f3c",
        strong = "#fff4d0",
        strong_italic = "#ffffff",
        heading1 = "#ff8080",
        heading2 = "#80ccff",
        heading3 = "#80ff80",
        heading4 = "#ffff80",
        heading5 = "#cc80ff",
        heading6 = "#80ffff",
        statusline_bg = "#3a3d4e",
        statusline_nc_bg = "#1e2030",
        sep = "#3a3d4e",
        pmenu_sel_fg = "#1e2030",
        ufo_bg = "#252838",
    },
    light = {
        bg = "#fbf9fb",          -- Material You surface（仅作反色前景用，背景保持 transparent）
        fg = "#2e3440",          -- Nord0，同 kitty 浅色前景
        fg_dim = "#3b4252",
        comment = "#5d6b85",
        selection = "#d8dee9",
        cursorline = "#e7ecf3",
        match = "#bccfeb",
        visual = "#9fbede",      -- 同 kitty selection_background
        red = "#a63a46",
        orange = "#b25737",
        yellow = "#7f640c",
        green = "#3f7e2c",
        cyan = "#0f7a89",
        blue = "#3d6e99",
        purple = "#7d4a76",
        pink = "#965d8d",
        line_nr = "#8792a8",
        search_fg = "#2e3440",
        search_bg = "#f0e3a2",
        incsearch_bg = "#f5c98a",
        end_of_buffer = "#d8dee9",
        ibl_indent = "#c3cbdc",
        ibl_scope = "#9aa6bd",
        ghost = "#9aa6bd",
        inlay = "#8593ad",
        code_bg = "#eceff4",
        inline_hl_bg = "#e3e9f2",
        strong = "#1a2332",
        strong_italic = "#10151d",
        heading1 = "#c04b56",
        heading2 = "#3d6fa8",
        heading3 = "#3f7e2c",
        heading4 = "#7f640c",
        heading5 = "#7d4a76",
        heading6 = "#0f7a89",
        statusline_bg = "#dde3ee",
        statusline_nc_bg = "#eceff4",
        sep = "#c9d2e0",
        pmenu_sel_fg = "#fbf9fb",
        ufo_bg = "#e7ecf3",
    },
}

-- 读 colors.json 的 surface 亮度判模式；任何失败回退 dark
function M.detect()
    local f = io.open(COLORS_FILE, "r")
    if not f then
        return "dark"
    end
    local ok, content = pcall(f.read, f, "*a")
    f:close()
    local surface = ok and vim.json.decode(content or "") or nil
    local hex = type(surface) == "table" and surface.surface or nil
    if type(hex) ~= "string" then
        return "dark"
    end
    hex = hex:gsub("^#", "")
    if #hex < 6 then
        return "dark"
    end
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if not (r and g and b) then
        return "dark"
    end
    -- Rec.709 亮度：浅色模式 surface 是近白色，深色模式近黑
    local lum = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255
    return lum > 0.5 and "light" or "dark"
end

-- 应用指定模式的全部高亮；可重复调用（幂等，仅重设高亮组）
function M.apply(mode)
    local c = palettes[mode] or palettes.dark
    vim.o.background = mode

    local function hl(group, opts)
        vim.api.nvim_set_hl(0, group, opts)
    end

    local transparent = "NONE"

    hl("LspReferenceText", { bg = c.match, underline = true })
    hl("LspReferenceRead", { bg = c.match, underline = true })
    hl("LspReferenceWrite", { bg = c.match, underline = true })

    hl("IlluminatedWordText", { bg = c.match, underline = true })
    hl("IlluminatedWordRead", { bg = c.match, underline = true })
    hl("IlluminatedWordWrite", { bg = c.match, underline = true })

    hl("CursorLine", { bg = c.cursorline })
    hl("NormalSB", { fg = c.fg, bg = transparent }) -- 某些侧边栏组件的背景
    hl("MsgArea", { fg = c.fg, bg = transparent })  -- 底部命令行区域的背景
    hl("Normal", { fg = c.fg, bg = transparent })
    hl("NormalFloat", { fg = c.fg, bg = transparent })
    hl("NormalNC", { fg = c.fg, bg = transparent })
    hl("SignColumn", { bg = transparent })
    hl("Folded", { fg = c.comment, bg = transparent })
    hl("FoldColumn", { fg = c.comment, bg = transparent })
    -- nvim-ufo：折叠摘要行与预览浮窗（UfoCursorFoldedLine 默认链接 CursorLine，无需另设）
    hl("UfoFoldedFg", { fg = c.comment, bg = transparent })   -- 折叠行摘要文字（"…N 行…"）
    hl("UfoFoldedBg", { bg = c.ufo_bg })                      -- 摘要行/预览标题栏底色，同 CursorLine 色系
    hl("UfoFoldedEllipsis", { fg = c.comment, bg = transparent }) -- 摘要超宽被截断时的省略号
    hl("UfoPreviewWinBar", { fg = c.comment, bg = c.ufo_bg }) -- 预览浮窗顶部标题栏
    hl("UfoPreviewSbar", { fg = c.selection, bg = transparent }) -- 预览浮窗滚动条槽
    hl("UfoPreviewThumb", { fg = c.comment, bg = transparent })  -- 预览浮窗滚动条滑块
    hl("EndOfBuffer", { fg = c.end_of_buffer, bg = transparent })
    hl("NavicText", { fg = c.fg_dim, bg = transparent })
    hl("NavicIcons", { fg = c.cyan, bg = transparent })
    hl("NavicSeparator", { fg = c.comment, bg = transparent })

    hl("StatusLine", { fg = c.fg, bg = c.statusline_bg })
    hl("StatusLineNC", { fg = c.fg_dim, bg = c.statusline_nc_bg, italic = true })
    hl("WinBar", { fg = c.fg, bg = transparent })
    hl("WinBarNC", { fg = c.fg_dim, bg = transparent, italic = true })
    hl("VertSplit", { fg = c.sep, bg = transparent })
    hl("WinSeparator", { fg = c.sep, bg = transparent })

    hl("LineNr", { fg = c.line_nr, bg = transparent })
    hl("CursorLineNr", { fg = c.purple, bg = transparent, bold = true })
    hl("Visual", { bg = c.visual, bold = true })
    -- snippet 待替换参数占位符（Tab 依次跳转的那些参数）：
    -- vim.snippet 的 SnippetTabstop 默认链接到 Visual，于是继承了蓝底 + bold，过于抢眼；
    -- SnippetTabstopActive（当前所在的那个参数）又链接到 SnippetTabstop，
    -- 所以只改前者，两者会自动一起生效。
    -- 底色与 CursorLine 同色：远比 Visual 的整块蓝底暗，不抢眼；
    -- 同时不设 bold，文字保持原样粗细。
    -- 刻意不用下划线类：inline_bracket_guides 画括号作用域连线的就是单下划线，
    -- 且其 extmark 的 priority = 120 高于 vim.snippet 未指定时的默认 0，
    -- 同位置高亮按 priority 合并、高者覆盖同名属性，下划线会在同一条基线上重合、
    -- 颜色也被吃掉，反而看不出占位符边界。
    hl("SnippetTabstop", { bg = c.cursorline })
    hl("Search", { fg = c.search_fg, bg = c.search_bg })
    hl("IncSearch", { fg = c.search_fg, bg = c.incsearch_bg })

    hl("Pmenu", { fg = c.fg, bg = transparent })
    hl("PmenuSel", { fg = c.pmenu_sel_fg, bg = c.purple })
    hl("PmenuSbar", { bg = c.selection })
    hl("PmenuThumb", { bg = c.purple })
    hl("FloatBorder", { fg = c.purple, bg = transparent })

    hl("NoiceCmdlinePopupBorder", { fg = c.cyan, bg = transparent })
    hl("NoiceCmdlinePopupTitle", { fg = c.cyan, bg = transparent, bold = true })
    hl("NoicePopupmenuBorder", { fg = c.purple, bg = transparent })

    hl("IblIndent", { fg = c.ibl_indent })
    hl("IblScope", { fg = c.ibl_scope })
    hl("CmpGhostText", { fg = c.ghost, italic = true })
    hl("BlinkCmpGhostText", { fg = c.ghost, italic = true })
    hl("LspInlayHint", { fg = c.inlay, italic = true })

    hl("DiagnosticError", { fg = c.red, undercurl = true, sp = c.red })
    hl("DiagnosticWarn", { fg = c.orange, undercurl = true, sp = c.orange })
    hl("DiagnosticInfo", { fg = c.cyan, undercurl = true, sp = c.cyan })
    hl("DiagnosticHint", { fg = c.blue, undercurl = true, sp = c.blue })

    hl("DoxygenTag", { fg = c.cyan, bold = true })
    hl("DoxygenBrief", { fg = c.fg_dim, italic = true })

    hl("DiagnosticSignError", { fg = c.red, bg = transparent })
    hl("DiagnosticSignWarn", { fg = c.orange, bg = transparent })
    hl("DiagnosticSignInfo", { fg = c.cyan, bg = transparent })
    hl("DiagnosticSignHint", { fg = c.blue, bg = transparent })
    hl("DiagnosticUnnecessary", { fg = c.comment, italic = true, undercurl = true, sp = c.purple })
    hl("DiagnosticVirtualTextError", { fg = c.red, bg = "NONE" })
    hl("DiagnosticVirtualTextWarn", { fg = c.orange, bg = "NONE" })
    hl("DiagnosticVirtualTextInfo", { fg = c.cyan, bg = "NONE" })
    hl("DiagnosticVirtualTextHint", { fg = c.blue, bg = "NONE" })
    hl("DiagnosticUnderlineError", { undercurl = true, sp = c.red })
    hl("DiagnosticUnderlineWarn", { undercurl = true, sp = c.orange })
    hl("DiagnosticUnderlineInfo", { undercurl = true, sp = c.cyan })
    hl("DiagnosticUnderlineHint", { undercurl = true, sp = c.blue })

    hl("Keyword", { fg = c.pink, bold = true })
    hl("Conditional", { fg = c.pink, bold = true })
    hl("Repeat", { fg = c.pink, bold = true })
    hl("Statement", { fg = c.pink })
    hl("Function", { fg = c.green })
    hl("Type", { fg = c.cyan })
    hl("StorageClass", { fg = c.cyan })
    hl("Identifier", { fg = c.fg })
    hl("String", { fg = c.yellow, italic = true })
    hl("Constant", { fg = c.purple })
    hl("Number", { fg = c.purple })
    hl("Boolean", { fg = c.purple, bold = true })
    hl("Comment", { fg = c.comment, italic = true })
    hl("Operator", { fg = c.pink })
    hl("Special", { fg = c.orange })
    hl("PreProc", { fg = c.cyan })
    hl("cInclude", { link = "PreProc" })
    hl("cIncludeStmt", { link = "PreProc" })

    hl("@keyword", { fg = c.pink, bold = true })
    hl("@keyword.function", { fg = c.pink, bold = true })
    hl("@keyword.return", { fg = c.pink, bold = true })
    hl("@function", { fg = c.green })
    hl("@function.builtin", { fg = c.cyan, italic = true })
    hl("@function.call", { fg = c.green })
    hl("@method", { fg = c.green })
    hl("@method.call", { fg = c.green })
    hl("@type", { fg = c.cyan })
    hl("@type.builtin", { fg = c.cyan, italic = true })
    hl("@variable", { fg = c.fg })
    hl("@variable.builtin", { fg = c.purple, italic = true })
    hl("@parameter", { fg = c.orange })
    hl("@string", { fg = c.yellow, italic = true })
    hl("@number", { fg = c.purple })
    hl("@boolean", { fg = c.purple, bold = true })
    hl("@constant", { fg = c.purple })
    hl("@constant.builtin", { fg = c.purple, italic = true })
    hl("@comment", { fg = c.comment, italic = true })
    hl("@operator", { fg = c.pink })
    hl("@field", { fg = c.cyan })
    hl("@property", { fg = c.cyan })
    hl("@constructor", { fg = c.cyan })
    hl("@namespace", { fg = c.cyan })
    -- builtin 家族统一斜体（与 @type/@variable/@constant 的 .builtin 一致）
    hl("@module.builtin", { fg = c.cyan, italic = true })
    -- 属性/注解：C++ 的 [[nodiscard]]、Rust 的 #[derive] 等，编译器附加信息
    hl("@attribute", { fg = c.cyan, italic = true })
    hl("@tag", { fg = c.pink })
    hl("@tag.attribute", { fg = c.green })
    hl("@punctuation", { fg = c.fg_dim })

    -- LSP 语义标记兜底：treesitter 不可用时注释仍保持斜体
    hl("@lsp.type.comment", { link = "Comment" })
    -- 弃用符号：只叠属性不动前景色，斜体+删除线
    hl("@lsp.mod.deprecated", { italic = true, strikethrough = true })

    -- Markdown: 标题背景 + 前景配色
    hl("RenderMarkdownH1Bg", { bg = "NONE" })
    hl("RenderMarkdownH2Bg", { bg = "NONE" })
    hl("RenderMarkdownH3Bg", { bg = "NONE" })
    hl("RenderMarkdownH4Bg", { bg = "NONE" })
    hl("RenderMarkdownH5Bg", { bg = "NONE" })
    hl("RenderMarkdownH6Bg", { bg = "NONE" })
    hl("RenderMarkdownH1", { fg = c.heading1, bold = true })
    hl("RenderMarkdownH2", { fg = c.heading2, bold = true })
    hl("RenderMarkdownH3", { fg = c.heading3, bold = true })
    hl("RenderMarkdownH4", { fg = c.heading4, bold = true })
    hl("RenderMarkdownH5", { fg = c.heading5, bold = true })
    hl("RenderMarkdownH6", { fg = c.heading6, bold = true })
    -- 标题文字颜色（treesitter 捕获）
    hl("@markup.heading.1.markdown", { fg = c.heading1, bold = true })
    hl("@markup.heading.2.markdown", { fg = c.heading2, bold = true })
    hl("@markup.heading.3.markdown", { fg = c.heading3, bold = true })
    hl("@markup.heading.4.markdown", { fg = c.heading4, bold = true })
    hl("@markup.heading.5.markdown", { fg = c.heading5, bold = true })
    hl("@markup.heading.6.markdown", { fg = c.heading6, bold = true })
    -- Markdown: 加粗文字更亮更粗
    hl("@markup.strong", { fg = c.strong, bold = true })
    -- Markdown: 斜体
    hl("@markup.italic", { fg = c.fg_dim, italic = true })
    -- Markdown: 粗斜体
    hl("@markup.strong.italic", { fg = c.strong_italic, bold = true, italic = true })
    -- Markdown: 链接
    hl("@markup.link.label.markdown_inline", { fg = c.cyan, underline = true })
    hl("@markup.link.url.markdown_inline", { fg = c.comment, underline = true })
    -- Markdown: 列表标记
    hl("@markup.list.unchecked", { fg = c.orange })
    hl("@markup.list.checked", { fg = c.green })
    -- Markdown: 引用
    hl("@markup.quote", { fg = c.comment, italic = true })
    -- Markdown: 代码块信息
    hl("@markup.raw", { fg = c.orange, italic = true })

    -- Markdown: render-markdown 补充高亮组
    hl("RenderMarkdownCode", { bg = c.code_bg })                                -- 代码块（透明，Kitty 终端支持）
    hl("RenderMarkdownCodeBorder", { fg = c.purple })                           -- 代码块边框
    hl("RenderMarkdownCodeInline", { fg = c.yellow, bg = "NONE", bold = true }) -- 行内代码
    hl("RenderMarkdownCodeInfo", { fg = c.cyan })                               -- 代码语言标识
    hl("RenderMarkdownCodeFallback", { fg = c.cyan, italic = true })            -- 代码回退
    hl("RenderMarkdownQuote", { fg = c.blue, italic = true })                   -- 引用块
    hl("RenderMarkdownQuote1", { fg = c.red, italic = true })                   -- 引用层级1
    hl("RenderMarkdownQuote2", { fg = c.orange, italic = true })                -- 引用层级2
    hl("RenderMarkdownQuote3", { fg = c.yellow, italic = true })                -- 引用层级3
    hl("RenderMarkdownQuote4", { fg = c.green, italic = true })                 -- 引用层级4
    hl("RenderMarkdownQuote5", { fg = c.cyan, italic = true })                  -- 引用层级5
    hl("RenderMarkdownQuote6", { fg = c.purple, italic = true })                -- 引用层级6
    hl("RenderMarkdownBullet", { fg = c.pink, bold = true })                    -- 无序列表符号
    hl("RenderMarkdownChecked", { fg = c.green, bold = true })                  -- 已勾选
    hl("RenderMarkdownUnchecked", { fg = c.orange })                            -- 未勾选
    hl("RenderMarkdownLink", { fg = c.cyan, underline = true, bold = true })    -- 链接
    hl("RenderMarkdownLinkTitle", { fg = c.purple, italic = true })             -- 链接标题
    hl("RenderMarkdownTableHead", { fg = c.cyan, bold = true })                 -- 表头
    hl("RenderMarkdownTableRow", { fg = c.fg })                                 -- 表格行
    hl("RenderMarkdownMath", { fg = c.pink, bold = true })                      -- LaTeX 公式
    hl("RenderMarkdownDash", { fg = c.purple, bold = true })                    -- 分隔线 ---
    hl("RenderMarkdownSign", { fg = c.purple, bold = true })                    -- 标题符号
    hl("RenderMarkdownTodo", { fg = c.red, bold = true })                       -- TODO
    hl("RenderMarkdownHtmlComment", { fg = c.comment, italic = true })          -- HTML 注释
    hl("RenderMarkdownInlineHighlight", { fg = c.yellow, bg = c.inline_hl_bg }) -- 行内高亮
    hl("RenderMarkdownIndent", { fg = c.line_nr })                              -- 缩进线
    hl("RenderMarkdownWikiLink", { fg = c.cyan, underline = true })             -- Wiki 链接
    hl("RenderMarkdownError", { fg = c.red, bold = true })                      -- 错误
    hl("RenderMarkdownWarn", { fg = c.orange, bold = true })                    -- 警告
    hl("RenderMarkdownInfo", { fg = c.cyan, bold = true })                      -- 信息
    hl("RenderMarkdownHint", { fg = c.blue, bold = true })                      -- 提示
    hl("RenderMarkdownSuccess", { fg = c.green, bold = true })                  -- 成功
    hl("RenderMarkdownColors", { fg = c.fg })                                   -- 颜色
    hl("RenderMarkdownPreview", { link = "Normal" })                            -- 预览

    hl("RainbowDelimiterRed", { fg = c.red })
    hl("RainbowDelimiterOrange", { fg = c.orange })
    hl("RainbowDelimiterYellow", { fg = c.yellow })
    hl("RainbowDelimiterGreen", { fg = c.green })
    hl("RainbowDelimiterCyan", { fg = c.cyan })
    hl("RainbowDelimiterBlue", { fg = c.purple })
    hl("RainbowDelimiterViolet", { fg = c.pink })
end

-- Doxygen 标签高亮：matchadd 引用的是高亮组名，组色随模式重定义自动生效，
-- 因此 autocmd 与 match 只需建一次，放在 setup 而非 apply
local function setup_doxygen()
    vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("GradientDoxygenHL", { clear = true }),
        pattern = { "c", "cpp", "cuda" },
        callback = function()
            vim.fn.clearmatches()
            -- Doxygen 标签
            local tags =
            [[@\%(param\|tparam\|return\|returns\|brief\|details\|note\|warning\|see\|ref\|throws\|exception\|author\|date\|version\|since\|deprecated\|todo\|test\|code\|endcode\|class\|struct\|enum\|fn\|var\|def\|file\|namespace\|ingroup\)\>]]
            vim.fn.matchadd("DoxygenTag", tags, 10, -1)
            vim.fn.matchadd("DoxygenBrief", [[@brief\s\+\zs.*$]], 9, -1)
        end,
    })
end

-- 监听 colors.json 变化（matugen 切模式/换壁纸时重写），实时跟随系统模式。
-- 监听所在目录而非文件本身：matugen 若以 rename 替换文件，对旧 inode 的
-- watch 会静默失效；监听目录则始终有效，按 filename 过滤。
local function start_watcher()
    local fs_event = vim.uv.new_fs_event()
    local timer = vim.uv.new_timer()
    if not fs_event or not timer then
        return
    end

    local function check()
        local mode = M.detect()
        if mode ~= vim.g.gradient_theme_mode then
            vim.g.gradient_theme_mode = mode
            M.apply(mode)
            vim.notify("主题已切换为 " .. (mode == "light" and "浅色" or "深色"), vim.log.levels.INFO)
        end
    end

    fs_event:start(COLORS_DIR, {}, function(err)
        if err then
            return
        end
        -- 防抖：matugen 可能在短时间内多次触发事件
        timer:stop()
        timer:start(200, 0, vim.schedule_wrap(check))
    end)
end

function M.setup()
    local mode = M.detect()
    vim.g.gradient_theme_mode = mode
    M.apply(mode)
    setup_doxygen()
    start_watcher()

    -- 手动临时覆盖（不写任何状态，下次 fs_event 触发或重启后回到跟随系统）
    vim.api.nvim_create_user_command("ThemeLight", function()
        vim.g.gradient_theme_mode = "light"
        M.apply("light")
    end, { desc = "临时切换浅色主题" })
    vim.api.nvim_create_user_command("ThemeDark", function()
        vim.g.gradient_theme_mode = "dark"
        M.apply("dark")
    end, { desc = "临时切换深色主题" })
end

return M
