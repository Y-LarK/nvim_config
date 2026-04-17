local M = {}

function M.setup()
    local function hl(group, opts)
        vim.api.nvim_set_hl(0, group, opts)
    end

    local c = {
        bg = "NONE",
        selection = "#44475a",
        red = "#ff5555",
        orange = "#ffb86c",
        yellow = "#f1fa8c",
        green = "#50fa7b",
        cyan = "#8be9fd",
        blue = "#6272a4",
        purple = "#bd93f9",
        pink = "#ff79c6",
        comment = "#a0a8c0",
        fg = "#f8f8f2",
        fg_dim = "#c8cee0",
    }
    local c_match = "#4d5b85"
    -- 核心：确保这些基础组的背景为 NONE
    hl("Normal", { fg = c.fg, bg = c.bg })             -- 主编辑区透明
    hl("NormalNC", { fg = c.fg, bg = c.bg })           -- 非当前窗口透明
    hl("SignColumn", { bg = c.bg })                    -- 侧边栏（行号左侧）透明
    hl("FoldColumn", { fg = c.comment, bg = c.bg })
    hl("EndOfBuffer", { fg = c.selection, bg = c.bg }) -- 文件末尾波浪线处透明    hl("LspReferenceText", { bg = c_match, underline = true })
    hl("LspReferenceRead", { bg = c_match, underline = true })
    hl("LspReferenceWrite", { bg = c_match, underline = true })

    hl("IlluminatedWordText", { bg = c_match, underline = true })
    hl("IlluminatedWordRead", { bg = c_match, underline = true })
    hl("IlluminatedWordWrite", { bg = c_match, underline = true })

    hl("CursorLine", { bg = "#343746" })
    hl("Normal", { fg = c.fg, bg = c.bg })
    hl("NormalFloat", { fg = c.fg, bg = c.bg })
    hl("NormalNC", { fg = c.fg, bg = c.bg })
    hl("SignColumn", { bg = c.bg })
    hl("Folded", { fg = c.comment, bg = c.bg })
    hl("FoldColumn", { fg = c.comment, bg = c.bg })
    hl("EndOfBuffer", { fg = c.selection, bg = c.bg })

    hl("StatusLine", { fg = c.fg, bg = c.selection })
    hl("StatusLineNC", { fg = c.fg_dim, bg = c.bg })
    hl("WinBar", { fg = c.fg, bg = c.bg })
    hl("WinBarNC", { fg = c.fg_dim, bg = c.bg })
    hl("VertSplit", { fg = c.selection, bg = c.bg })
    hl("WinSeparator", { fg = c.selection, bg = c.bg })

    hl("LineNr", { fg = "#7a82a0", bg = c.bg })
    hl("CursorLineNr", { fg = c.purple, bg = c.bg, bold = true })
    hl("CursorLine", { bg = c.selection })
    hl("Visual", { bg = c.blue, bold = true })
    hl("Search", { fg = c.bg, bg = c.yellow })
    hl("IncSearch", { fg = c.bg, bg = c.orange })

    hl("Pmenu", { fg = c.fg, bg = "#21222c" })
    hl("PmenuSel", { fg = c.bg, bg = c.purple })
    hl("PmenuSbar", { bg = c.selection })
    hl("PmenuThumb", { bg = c.purple })
    hl("FloatBorder", { fg = c.purple, bg = c.bg })

    hl("NoiceCmdlinePopupBorder", { fg = c.cyan, bg = c.bg })
    hl("NoiceCmdlinePopupTitle", { fg = c.cyan, bg = c.bg, bold = true })
    hl("NoicePopupmenuBorder", { fg = c.purple, bg = c.bg })

    hl("IblIndent", { fg = "#4a5170" })
    hl("IblScope", { fg = "#7a82a0" })
    hl("CmpGhostText", { fg = "#8890b0", italic = true })
    hl("BlinkCmpGhostText", { fg = "#8890b0", italic = true })
    hl("LspInlayHint", { fg = "#a0a8c0", italic = true })

    hl("DiagnosticError", { fg = c.red, undercurl = true, sp = c.red })
    hl("DiagnosticWarn", { fg = c.orange, undercurl = true, sp = c.orange })
    hl("DiagnosticInfo", { fg = c.cyan, undercurl = true, sp = c.cyan })
    hl("DiagnosticHint", { fg = c.blue, undercurl = true, sp = c.blue })
    hl("DiagnosticSignError", { fg = c.red, bg = c.bg })
    hl("DiagnosticSignWarn", { fg = c.orange, bg = c.bg })
    hl("DiagnosticSignInfo", { fg = c.cyan, bg = c.bg })
    hl("DiagnosticSignHint", { fg = c.blue, bg = c.bg })
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

    hl("RainbowDelimiterRed", { fg = c.red })
    hl("RainbowDelimiterOrange", { fg = c.orange })
    hl("RainbowDelimiterYellow", { fg = c.yellow })
    hl("RainbowDelimiterGreen", { fg = c.green })
    hl("RainbowDelimiterCyan", { fg = c.cyan })
    hl("RainbowDelimiterBlue", { fg = c.purple })
    hl("RainbowDelimiterViolet", { fg = c.pink })
end

return M
