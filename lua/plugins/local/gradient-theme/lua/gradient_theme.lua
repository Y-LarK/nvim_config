local M = {}

function M.setup()
    local function hl(group, opts)
        vim.api.nvim_set_hl(0, group, opts)
    end

    local transparent = "NONE"

    local c = {
        bg = "#1e2030",
        selection = "#3a3d4e",
        red = "#ff6b6b",
        orange = "#ffc880",
        yellow = "#f6ffa0",
        green = "#66ff8d",
        cyan = "#a4f4ff",
        blue = "#8296d4",
        purple = "#cfacff",
        pink = "#ff8dd4",
        comment = "#b8c0d8",
        fg = "#ffffff",
        fg_dim = "#dce4f0",
    }
    local c_match = "#4d5b88"


    hl("LspReferenceText", { bg = c_match, underline = true })
    hl("LspReferenceRead", { bg = c_match, underline = true })
    hl("LspReferenceWrite", { bg = c_match, underline = true })

    hl("IlluminatedWordText", { bg = c_match, underline = true })
    hl("IlluminatedWordRead", { bg = c_match, underline = true })
    hl("IlluminatedWordWrite", { bg = c_match, underline = true })

    hl("CursorLine", { bg = c.selection })          -- c.selection 是 #3a3d4e
    hl("CursorLine", { bg = "#2c2f3c" })
    hl("NormalSB", { fg = c.fg, bg = transparent }) -- 某些侧边栏组件的背景
    hl("MsgArea", { fg = c.fg, bg = transparent })  -- 底部命令行区域的背景
    hl("Normal", { fg = c.fg, bg = transparent })
    hl("NormalFloat", { fg = c.fg, bg = transparent })
    hl("NormalNC", { fg = c.fg, bg = transparent })
    hl("SignColumn", { bg = transparent })
    hl("Folded", { fg = c.comment, bg = transparent })
    hl("FoldColumn", { fg = c.comment, bg = transparent })
    hl("EndOfBuffer", { fg = c.selection, bg = transparent })
    hl("NavicText", { fg = c.fg_dim, bg = transparent })
    hl("NavicIcons", { fg = c.cyan, bg = transparent })
    hl("NavicSeparator", { fg = c.comment, bg = transparent })

    hl("StatusLine", { fg = c.fg, bg = c.selection })
    hl("StatusLineNC", { fg = c.fg_dim, bg = c.bg })
    hl("WinBar", { fg = c.fg, bg = transparent })
    hl("WinBarNC", { fg = c.fg_dim, bg = transparent })
    hl("VertSplit", { fg = c.selection, bg = transparent })
    hl("WinSeparator", { fg = c.selection, bg = transparent })

    hl("LineNr", { fg = "#9098b8", bg = transparent })
    hl("CursorLineNr", { fg = c.purple, bg = transparent, bold = true })
    hl("CursorLine", { bg = "#252838" })
    hl("Visual", { bg = c.blue, bold = true })
    hl("Search", { fg = c.bg, bg = c.yellow })
    hl("IncSearch", { fg = c.bg, bg = c.orange })

    hl("Pmenu", { fg = c.fg, bg = transparent })
    hl("PmenuSel", { fg = c.bg, bg = c.purple })
    hl("PmenuSbar", { bg = c.selection })
    hl("PmenuThumb", { bg = c.purple })
    hl("FloatBorder", { fg = c.purple, bg = transparent })

    hl("NoiceCmdlinePopupBorder", { fg = c.cyan, bg = transparent })
    hl("NoiceCmdlinePopupTitle", { fg = c.cyan, bg = transparent, bold = true })
    hl("NoicePopupmenuBorder", { fg = c.purple, bg = transparent })

    hl("IblIndent", { fg = "#586080" })
    hl("IblScope", { fg = "#9098b8" })
    hl("CmpGhostText", { fg = "#a0a8c0", italic = true })
    hl("BlinkCmpGhostText", { fg = "#a0a8c0", italic = true })
    hl("LspInlayHint", { fg = "#b8c0d8", italic = true })

    hl("DiagnosticError", { fg = c.red, undercurl = true, sp = c.red })
    hl("DiagnosticWarn", { fg = c.orange, undercurl = true, sp = c.orange })
    hl("DiagnosticInfo", { fg = c.cyan, undercurl = true, sp = c.cyan })
    hl("DiagnosticHint", { fg = c.blue, undercurl = true, sp = c.blue })
    -- Doxygen 标签高亮
    vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("GradientDoxygenHL", { clear = true }),
        pattern = { "c", "cpp", "cuda" },
        callback = function()
            vim.fn.clearmatches()
            -- Doxygen 标签
            local tags = [[@\%(param\|tparam\|return\|returns\|brief\|details\|note\|warning\|see\|ref\|throws\|exception\|author\|date\|version\|since\|deprecated\|todo\|test\|code\|endcode\|class\|struct\|enum\|fn\|var\|def\|file\|namespace\|ingroup\)\>]]
            vim.fn.matchadd("DoxygenTag", tags, 10, -1)
            vim.fn.matchadd("DoxygenBrief", [[@brief\s\+\zs.*$]], 9, -1)
            -- TODO / FIXME / HACK / NOTE 注释高亮
            vim.fn.matchadd("TodoComment", [[//\s*\zs\%(TODO\|FIXME\|HACK\|NOTE\|XXX\|OPTIM\)\>]], 8, -1)
            vim.fn.matchadd("TodoComment", [[/\*\s*\zs\%(TODO\|FIXME\|HACK\|NOTE\|XXX\|OPTIM\)\>]], 8, -1)
        end,
    })
    hl("DoxygenTag", { fg = c.cyan, bold = true })
    hl("DoxygenBrief", { fg = c.fg_dim, italic = true })
    hl("TodoComment", { fg = c.orange, bold = true })

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
    hl("String", { fg = c.yellow })
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
    hl("@function.builtin", { fg = c.cyan })
    hl("@function.call", { fg = c.green })
    hl("@method", { fg = c.green })
    hl("@method.call", { fg = c.green })
    hl("@type", { fg = c.cyan })
    hl("@type.builtin", { fg = c.cyan, italic = true })
    hl("@variable", { fg = c.fg })
    hl("@variable.builtin", { fg = c.purple, italic = true })
    hl("@parameter", { fg = c.orange })
    hl("@string", { fg = c.yellow })
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
    hl("@tag", { fg = c.pink })
    hl("@tag.attribute", { fg = c.green })
    hl("@punctuation", { fg = c.fg_dim })

    -- Markdown: 标题背景 + 前景配色
    hl("RenderMarkdownH1Bg", { bg = "NONE" })
    hl("RenderMarkdownH2Bg", { bg = "NONE" })
    hl("RenderMarkdownH3Bg", { bg = "NONE" })
    hl("RenderMarkdownH4Bg", { bg = "NONE" })
    hl("RenderMarkdownH5Bg", { bg = "NONE" })
    hl("RenderMarkdownH6Bg", { bg = "NONE" })
    hl("RenderMarkdownH1", { fg = "#ff8080", bold = true })
    hl("RenderMarkdownH2", { fg = "#80ccff", bold = true })
    hl("RenderMarkdownH3", { fg = "#80ff80", bold = true })
    hl("RenderMarkdownH4", { fg = "#ffff80", bold = true })
    hl("RenderMarkdownH5", { fg = "#cc80ff", bold = true })
    hl("RenderMarkdownH6", { fg = "#80ffff", bold = true })
    -- 标题文字颜色（treesitter 捕获）
    hl("@markup.heading.1.markdown", { fg = "#ff8080", bold = true })
    hl("@markup.heading.2.markdown", { fg = "#80ccff", bold = true })
    hl("@markup.heading.3.markdown", { fg = "#80ff80", bold = true })
    hl("@markup.heading.4.markdown", { fg = "#ffff80", bold = true })
    hl("@markup.heading.5.markdown", { fg = "#cc80ff", bold = true })
    hl("@markup.heading.6.markdown", { fg = "#80ffff", bold = true })
    -- Markdown: 加粗文字更亮更粗
    hl("@markup.strong", { fg = "#fff4d0", bold = true })
    -- Markdown: 斜体
    hl("@markup.italic", { fg = c.fg_dim, italic = true })
    -- Markdown: 粗斜体
    hl("@markup.strong.italic", { fg = "#ffffff", bold = true, italic = true })
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
    hl("RenderMarkdownCode",         { bg = "#2c2f3c" })              -- 代码块（仅背景，不覆盖 treesitter 前景色）
    hl("RenderMarkdownCodeBorder",   { fg = c.purple })                -- 代码块边框
    hl("RenderMarkdownCodeInline",   { fg = c.yellow, bg = "#2c2f3c", bold = true }) -- 行内代码
    hl("RenderMarkdownCodeInfo",     { fg = c.cyan })                  -- 代码语言标识
    hl("RenderMarkdownCodeFallback", { fg = c.cyan, italic = true })   -- 代码回退
    hl("RenderMarkdownQuote",        { fg = c.blue, italic = true })   -- 引用块
    hl("RenderMarkdownQuote1",       { fg = c.red, italic = true })    -- 引用层级1
    hl("RenderMarkdownQuote2",       { fg = c.orange, italic = true }) -- 引用层级2
    hl("RenderMarkdownQuote3",       { fg = c.yellow, italic = true }) -- 引用层级3
    hl("RenderMarkdownQuote4",       { fg = c.green, italic = true })  -- 引用层级4
    hl("RenderMarkdownQuote5",       { fg = c.cyan, italic = true })   -- 引用层级5
    hl("RenderMarkdownQuote6",       { fg = c.purple, italic = true }) -- 引用层级6
    hl("RenderMarkdownBullet",       { fg = c.pink, bold = true })     -- 无序列表符号
    hl("RenderMarkdownChecked",      { fg = c.green, bold = true })    -- 已勾选
    hl("RenderMarkdownUnchecked",    { fg = c.orange })                -- 未勾选
    hl("RenderMarkdownLink",         { fg = c.cyan, underline = true, bold = true }) -- 链接
    hl("RenderMarkdownLinkTitle",    { fg = c.purple, italic = true }) -- 链接标题
    hl("RenderMarkdownTableHead",    { fg = c.bg, bg = c.purple, bold = true }) -- 表头
    hl("RenderMarkdownTableRow",     { fg = c.fg })                    -- 表格行
    hl("RenderMarkdownMath",         { fg = c.pink, bold = true })     -- LaTeX 公式
    hl("RenderMarkdownDash",         { fg = c.purple, bold = true })   -- 分隔线 ---
    hl("RenderMarkdownSign",         { fg = c.purple, bold = true })   -- 标题符号
    hl("RenderMarkdownTodo",         { fg = c.red, bold = true })      -- TODO
    hl("RenderMarkdownHtmlComment",  { fg = c.comment, italic = true }) -- HTML 注释
    hl("RenderMarkdownInlineHighlight", { fg = c.yellow, bg = "#2c2f3c" }) -- 行内高亮
    hl("RenderMarkdownIndent",       { fg = "#9098b8" })               -- 缩进线
    hl("RenderMarkdownWikiLink",     { fg = c.cyan, underline = true }) -- Wiki 链接
    hl("RenderMarkdownError",        { fg = c.red, bold = true })      -- 错误
    hl("RenderMarkdownWarn",         { fg = c.orange, bold = true })   -- 警告
    hl("RenderMarkdownInfo",         { fg = c.cyan, bold = true })     -- 信息
    hl("RenderMarkdownHint",         { fg = c.blue, bold = true })     -- 提示
    hl("RenderMarkdownSuccess",      { fg = c.green, bold = true })    -- 成功
    hl("RenderMarkdownColors",       { fg = c.fg })                    -- 颜色
    hl("RenderMarkdownPreview",      { link = "Normal" })              -- 预览

    hl("RainbowDelimiterRed", { fg = c.red })
    hl("RainbowDelimiterOrange", { fg = c.orange })
    hl("RainbowDelimiterYellow", { fg = c.yellow })
    hl("RainbowDelimiterGreen", { fg = c.green })
    hl("RainbowDelimiterCyan", { fg = c.cyan })
    hl("RainbowDelimiterBlue", { fg = c.purple })
    hl("RainbowDelimiterViolet", { fg = c.pink })
end

return M
