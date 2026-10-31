-- gradient-theme —— 双轨主题（当前固定深色，不跟随系统）
--
-- 跟随开关见下方 FOLLOW_SYSTEM：为 false 时启动即 apply("dark")，既不读
-- colors.json 也不起 fs_event，系统切深浅完全不影响 nvim。
-- 为 true 时恢复原跟随逻辑：DMS 切深浅会以对应 --mode 重跑 matugen，后者
-- 重写 ~/.cache/niri-quickshell/colors.json；取其中 surface 的 Rec.709
-- 亮度判模式（> 0.5 为浅色），口径与 ~/.local/bin/theme-mode-sync 完全一致。
-- 文件缺失/解析失败一律回退 dark。运行中通过 uv_fs_event 监听该文件所在
-- 目录（监听文件本身会在 matugen rename 替换时失效），防抖后重判，模式变化
-- 才重新应用 —— 换壁纸不切模式时幂等跳过。
--
-- 双轨（2026-10-25 起）：
--   dark  —— 自绘德古拉系色板，apply("dark") 手写全部高亮组，逐值不变。
--   light —— colorscheme gruvbox（morhetz/gruvbox）接管标准组与语法高亮
--            （其文件开头 hi clear + syntax reset，深色残留被清干净），
--            之后再补「钉子组」：gruvbox 没有的插件组 + 透明组。钉子值
--            全部取自 gruvbox.vim 浅色相对色（faded 语法色 + bg0-4）。
-- 背景两种模式都 transparent 跟随终端：深色下是 Nord 深底，浅色下是
-- Material You surface（kitty 的 matugen-background.conf 提供浅底）。
-- 注意：深色固定后系统若处于浅色，终端底是亮的，深色白字观感受影响；
-- 用户明确要求保持透明，不要给 Normal 等组铺实底（2026-10-31）。
-- 注意 morhetz/gruvbox 没有 g:gruvbox_transparent_bg —— 那是社区 fork
-- 的选项（wiki 过时），透明必须由 apply_light 手动补。

local M = {}

-- 是否跟随 dms 系统深浅模式。
--   false（当前）= 始终深色：启动即 apply("dark")，不读 colors.json、不起
--                   fs_event，系统切深浅不会触发任何重刷。
--   true          = 恢复原双轨跟随：启动按系统模式选轨，运行中实时跟随。
local FOLLOW_SYSTEM = false

local COLORS_DIR = vim.fs.normalize("~/.cache/niri-quickshell")
local COLORS_FILE = COLORS_DIR .. "/colors.json"

-- 两套色板。dark 与旧版逐值一致（深色模式零变化）；
-- light 彩色不再沿用 kitty 浅色 ANSI（Nord 加深版，低饱和），改为
-- 色相对齐 dark 色板 + 高饱和（70~95%），并保证对浅底对比度 ≥4.5，
-- 两个模式的彩色观感一致：
--   red→0°  orange→34°  yellow→66°  green→135°
--   cyan→187° blue→225° purple→265° pink→323°
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
    -- 浅色不再是完整自绘板：apply("light") 先 colorscheme gruvbox 接管
    -- 标准组/语法高亮，这里只喂 apply_light 的「钉子组」（gruvbox 没有
    -- 的插件组 + 需要透明的组）。全部取自 gruvbox.vim 浅色相对色：
    --   bg0 #fbf1c7  bg1 #ebdbb2  bg2 #d5c4a1  bg3 #bdae93  bg4 #a89984
    --   fg1 #3c3836  fg2 #504945  fg3 #665c54  fg4 #7c6f64  gray #928374
    --   faded: red #9d0006  orange #af3a03  yellow #b57614
    --          green #79740e  aqua #427b58  blue #076678  purple #8f3f71
    light = {
        bg = "#fbf1c7",          -- light0（仅作锚点注释，Normal 背景实际透明）
        fg = "#3c3836",          -- fg1
        fg_dim = "#504945",      -- fg2
        comment = "#928374",     -- gray
        match = "#d5c4a1",       -- bg2，LspReference/Illuminated 底
        cursorline = "#ebdbb2",  -- bg1，同 gruvbox 自绘 CursorLine 色系
        red = "#9d0006",
        orange = "#af3a03",
        yellow = "#b57614",
        green = "#79740e",
        cyan = "#427b58",        -- aqua
        blue = "#076678",
        purple = "#8f3f71",
        pink = "#8f3f71",        -- gruvbox 无 pink，Keyword 系并入 purple
        line_nr = "#7c6f64",     -- fg4
        end_of_buffer = "#d5c4a1",
        ibl_indent = "#d5c4a1",  -- bg2
        ibl_scope = "#a89984",   -- bg4
        ghost = "#a89984",       -- bg4
        inlay = "#7c6f64",       -- fg4
        code_bg = "#ebdbb2",     -- bg1
        inline_hl_bg = "#ebdbb2",
        strong = "#282828",      -- fg0（dark0）
        strong_italic = "#1d2021", -- dark0_hard，粗斜体再压一档
        heading1 = "#9d0006",
        heading2 = "#076678",
        heading3 = "#79740e",
        heading4 = "#b57614",
        heading5 = "#8f3f71",
        heading6 = "#427b58",
        sep = "#d5c4a1",         -- bg2
        ufo_bg = "#ebdbb2",      -- bg1，同 CursorLine 色系
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

-- smear-cursor 拖影色随模式（启动期由 cursor.lua 的 opts 惰性函数按模式
-- 取值；这里管运行时切换）。元表把 cursor_color 转发给 color 模块，
-- 改完必须 clear_cache()，否则已缓存的高亮组名不会重算颜色。
local function apply_cursor_color(mode)
    local ok, smear = pcall(require, "smear_cursor")
    if not ok then
        return
    end
    smear.cursor_color = mode == "light" and "#8f3f71" or "#bd93f9"
    local ok_color, color_mod = pcall(require, "smear_cursor.color")
    if ok_color and color_mod.clear_cache then
        color_mod.clear_cache()
    end
end

-- 浅色轨：gruvbox 接管标准组/语法高亮，再补钉子组。
-- gruvbox 开头 hi clear + syntax reset，深色轨的手写组被清干净；
-- 所以本函数必须在 colorscheme 之后逐组设置，顺序不能反。
-- 可重复调用（幂等，重跑 colorscheme + 重设钉子组）。
local function apply_light()
    -- 终端里 nvim 同样能渲染斜体，gruvbox 默认终端关斜体，打开以对齐深色观感
    vim.g.gruvbox_italic = 1
    -- gruvbox 按 &background 选浅色板（源码 s:is_dark），必须在 colorscheme 前
    vim.o.background = "light"
    vim.cmd("colorscheme gruvbox")

    local c = palettes.light

    local function hl(group, opts)
        vim.api.nvim_set_hl(0, group, opts)
    end

    local transparent = "NONE"

    -- 透明组：gruvbox 会把 Normal 等刷成米色实底，本机浅色走终端 matugen 白底
    hl("Normal", { fg = c.fg, bg = transparent })
    hl("NormalNC", { fg = c.fg, bg = transparent })
    hl("NormalFloat", { fg = c.fg, bg = transparent })
    hl("NormalSB", { fg = c.fg, bg = transparent }) -- 某些侧边栏组件的背景
    hl("MsgArea", { fg = c.fg, bg = transparent })
    hl("SignColumn", { bg = transparent })
    hl("EndOfBuffer", { fg = c.end_of_buffer, bg = transparent })
    hl("Folded", { fg = c.comment, bg = transparent })
    hl("FoldColumn", { fg = c.comment, bg = transparent })
    hl("TabLineFill", { bg = transparent }) -- bufferline 透明标签栏的兜底层
    hl("WinBar", { fg = c.fg, bg = transparent })
    hl("WinBarNC", { fg = c.fg_dim, bg = transparent, italic = true })
    hl("VertSplit", { fg = c.sep, bg = transparent })
    hl("WinSeparator", { fg = c.sep, bg = transparent })
    hl("Pmenu", { fg = c.fg, bg = transparent }) -- PmenuSel/Sbar/Thumb 留给 gruvbox
    hl("FloatBorder", { fg = c.purple, bg = transparent })

    -- LSP/插件组（gruvbox 未定义）
    hl("LspReferenceText", { bg = c.match, underline = true })
    hl("LspReferenceRead", { bg = c.match, underline = true })
    hl("LspReferenceWrite", { bg = c.match, underline = true })
    hl("IlluminatedWordText", { bg = c.match, underline = true })
    hl("IlluminatedWordRead", { bg = c.match, underline = true })
    hl("IlluminatedWordWrite", { bg = c.match, underline = true })
    hl("NavicText", { fg = c.fg_dim, bg = transparent })
    hl("NavicIcons", { fg = c.cyan, bg = transparent })
    hl("NavicSeparator", { fg = c.comment, bg = transparent })
    hl("IblIndent", { fg = c.ibl_indent })
    hl("IblScope", { fg = c.ibl_scope })
    hl("CmpGhostText", { fg = c.ghost, italic = true })
    hl("BlinkCmpGhostText", { fg = c.ghost, italic = true })
    hl("LspInlayHint", { fg = c.inlay, italic = true })
    -- snippet 占位符底色与 CursorLine 同色系，不设 bold（理由见深色轨同名注释）
    hl("SnippetTabstop", { bg = c.cursorline })
    hl("DoxygenTag", { fg = c.cyan, bold = true })
    hl("DoxygenBrief", { fg = c.fg_dim, italic = true })

    -- nvim-ufo
    hl("UfoFoldedFg", { fg = c.comment, bg = transparent })
    hl("UfoFoldedBg", { bg = c.ufo_bg })
    hl("UfoFoldedEllipsis", { fg = c.comment, bg = transparent })
    hl("UfoPreviewWinBar", { fg = c.comment, bg = c.ufo_bg })
    hl("UfoPreviewSbar", { fg = c.cursorline, bg = transparent })
    hl("UfoPreviewThumb", { fg = c.comment, bg = transparent })

    -- 诊断：undercurl + 透明标号列/虚拟文本（gruvbox 未定义 Diagnostic*）
    hl("DiagnosticError", { fg = c.red, undercurl = true, sp = c.red })
    hl("DiagnosticWarn", { fg = c.orange, undercurl = true, sp = c.orange })
    hl("DiagnosticInfo", { fg = c.cyan, undercurl = true, sp = c.cyan })
    hl("DiagnosticHint", { fg = c.blue, undercurl = true, sp = c.blue })
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

    -- LSP 语义标记兜底（gruvbox 无语义标记支持）
    hl("@lsp.type.comment", { link = "Comment" })
    hl("@lsp.mod.deprecated", { italic = true, strikethrough = true })

    -- Markdown：标题色相映射与深色轨一致，值用 gruvbox faded
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
    hl("@markup.heading.1.markdown", { fg = c.heading1, bold = true })
    hl("@markup.heading.2.markdown", { fg = c.heading2, bold = true })
    hl("@markup.heading.3.markdown", { fg = c.heading3, bold = true })
    hl("@markup.heading.4.markdown", { fg = c.heading4, bold = true })
    hl("@markup.heading.5.markdown", { fg = c.heading5, bold = true })
    hl("@markup.heading.6.markdown", { fg = c.heading6, bold = true })
    hl("@markup.strong", { fg = c.strong, bold = true })
    hl("@markup.italic", { fg = c.fg_dim, italic = true })
    hl("@markup.strong.italic", { fg = c.strong_italic, bold = true, italic = true })
    hl("@markup.link.label.markdown_inline", { fg = c.cyan, underline = true })
    hl("@markup.link.url.markdown_inline", { fg = c.comment, underline = true })
    hl("@markup.list.unchecked", { fg = c.orange })
    hl("@markup.list.checked", { fg = c.green })
    hl("@markup.quote", { fg = c.comment, italic = true })
    hl("@markup.raw", { fg = c.orange, italic = true })

    hl("RenderMarkdownCode", { bg = c.code_bg })
    hl("RenderMarkdownCodeBorder", { fg = c.purple })
    hl("RenderMarkdownCodeInline", { fg = c.yellow, bg = "NONE", bold = true })
    hl("RenderMarkdownCodeInfo", { fg = c.cyan })
    hl("RenderMarkdownCodeFallback", { fg = c.cyan, italic = true })
    hl("RenderMarkdownQuote", { fg = c.blue, italic = true })
    hl("RenderMarkdownQuote1", { fg = c.red, italic = true })
    hl("RenderMarkdownQuote2", { fg = c.orange, italic = true })
    hl("RenderMarkdownQuote3", { fg = c.yellow, italic = true })
    hl("RenderMarkdownQuote4", { fg = c.green, italic = true })
    hl("RenderMarkdownQuote5", { fg = c.cyan, italic = true })
    hl("RenderMarkdownQuote6", { fg = c.purple, italic = true })
    hl("RenderMarkdownBullet", { fg = c.pink, bold = true })
    hl("RenderMarkdownChecked", { fg = c.green, bold = true })
    hl("RenderMarkdownUnchecked", { fg = c.orange })
    hl("RenderMarkdownLink", { fg = c.cyan, underline = true, bold = true })
    hl("RenderMarkdownLinkTitle", { fg = c.purple, italic = true })
    hl("RenderMarkdownTableHead", { fg = c.cyan, bold = true })
    hl("RenderMarkdownTableRow", { fg = c.fg })
    hl("RenderMarkdownMath", { fg = c.pink, bold = true })
    hl("RenderMarkdownDash", { fg = c.purple, bold = true })
    hl("RenderMarkdownSign", { fg = c.purple, bold = true })
    hl("RenderMarkdownTodo", { fg = c.red, bold = true })
    hl("RenderMarkdownHtmlComment", { fg = c.comment, italic = true })
    hl("RenderMarkdownInlineHighlight", { fg = c.yellow, bg = c.inline_hl_bg })
    hl("RenderMarkdownIndent", { fg = c.line_nr })
    hl("RenderMarkdownWikiLink", { fg = c.cyan, underline = true })
    hl("RenderMarkdownError", { fg = c.red, bold = true })
    hl("RenderMarkdownWarn", { fg = c.orange, bold = true })
    hl("RenderMarkdownInfo", { fg = c.cyan, bold = true })
    hl("RenderMarkdownHint", { fg = c.blue, bold = true })
    hl("RenderMarkdownSuccess", { fg = c.green, bold = true })
    hl("RenderMarkdownColors", { fg = c.fg })
    hl("RenderMarkdownPreview", { link = "Normal" })

    -- 彩虹括号：7 槽对应深色轨，值用 gruvbox faded + aqua
    hl("RainbowDelimiterRed", { fg = c.red })
    hl("RainbowDelimiterOrange", { fg = c.orange })
    hl("RainbowDelimiterYellow", { fg = c.yellow })
    hl("RainbowDelimiterGreen", { fg = c.green })
    hl("RainbowDelimiterCyan", { fg = c.cyan })
    hl("RainbowDelimiterBlue", { fg = c.blue })
    hl("RainbowDelimiterViolet", { fg = c.purple })

    apply_cursor_color("light")
    -- 外围组件（bufferline 标签栏等）的随模式自绘高亮靠这个事件重挂
    vim.api.nvim_exec_autocmds("User", { pattern = "GradientThemeApplied" })
end

-- 应用指定模式的全部高亮；可重复调用（幂等，仅重设高亮组）
function M.apply(mode)
    -- 模式状态统一在入口写入：lualine / alpha / cursor / bufferline 的回调
    -- 都读 vim.g.gradient_theme_mode，不能依赖调用方先写
    vim.g.gradient_theme_mode = mode
    if mode == "light" then
        apply_light()
        return
    end
    local c = palettes.dark
    vim.o.background = mode
    -- 浅色轨的 gruvbox 会写 g:terminal_color_0..15；回深色时清掉，
    -- 让 :terminal 回落到 kitty 传入的 ANSI（本机终端色始终由 kitty 管）
    for i = 0, 15 do
        vim.g["terminal_color_" .. i] = nil
    end
    -- colorscheme gruvbox 留下的 g:colors_name 同理清掉，避免按
    -- colorscheme 取色的插件误判（本配置深色轨不是任何 colorscheme）
    vim.g.colors_name = nil

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

    apply_cursor_color("dark")
    vim.api.nvim_exec_autocmds("User", { pattern = "GradientThemeApplied" })
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
    -- FOLLOW_SYSTEM = false 时固定深色：不读 colors.json、不起 watcher，
    -- 系统切深浅不会触发任何重刷（标签栏等外围插件也不会被重挂）。
    local mode = FOLLOW_SYSTEM and M.detect() or "dark"
    vim.g.gradient_theme_mode = mode
    M.apply(mode)
    setup_doxygen()
    if FOLLOW_SYSTEM then
        start_watcher()
    end

    -- 手动临时覆盖（不写任何状态；FOLLOW_SYSTEM = false 时不会自动切回，
    -- 重启或再执行 :ThemeDark 恢复深色）
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
