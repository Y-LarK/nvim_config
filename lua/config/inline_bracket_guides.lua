local M = {}

local api = vim.api
local namespace
local guide_groups = {}

-- 行内栈匹配的括号对（<> 不进栈：C 里 < > 多为比较运算，须由节点法识别模板）
local bracket_pairs = {
    ["("] = ")",
    ["["] = "]",
    ["{"] = "}",
}
local closing_pairs = {
    [")"] = "(",
    ["]"] = "[",
    ["}"] = "{",
}
-- 节点法识别的括号对：{ }（代码块）、< >（C++ 模板参数）与 " "（字符串字面量）
local node_pair_chars = {
    ["{"] = "}",
    ["<"] = ">",
    ['"'] = '"',
}
local rainbow_highlights = {
    "RainbowDelimiterRed",
    "RainbowDelimiterYellow",
    "RainbowDelimiterBlue",
    "RainbowDelimiterOrange",
    "RainbowDelimiterGreen",
    "RainbowDelimiterViolet",
    "RainbowDelimiterCyan",
}
local rainbow_highlight_set = {}
local supported_filetypes = {
    c = true,
    cpp = true,
    cuda = true,
}

-- 括号出现在字符串/注释/预处理/头文件中时不是语法括号，需排除
local non_code_node_types = {
    string_literal = true,
    char_literal = true,
    comment = true,
    preproc_arg = true,
    concatenated_string = true,
    raw_string_literal = true,
}

for _, group in ipairs(rainbow_highlights) do
    rainbow_highlight_set[group] = true
end

local function refresh_highlights()
    for _, group in ipairs(rainbow_highlights) do
        local color = api.nvim_get_hl(0, { name = group, link = false }).fg or "#9098b8"
        local guide_group = "InlineBracketGuide" .. group:sub(#"RainbowDelimiter" + 1)
        api.nvim_set_hl(0, guide_group, {
            underline = true,
            sp = color,
        })
        guide_groups[group] = guide_group
    end
end

local function get_rainbow_group(bufnr, row, col)
    local extmarks = api.nvim_buf_get_extmarks(bufnr, -1, { row, col }, { row, col }, {
        type = "highlight",
        details = true,
    })
    for _, extmark in ipairs(extmarks) do
        local details = extmark[4]
        if details and rainbow_highlight_set[details.hl_group] then
            return details.hl_group
        end
    end
    return "RainbowDelimiterViolet"
end

-- col 处的括号是否属于真实代码（排除字符串/注释/预处理）
local function is_real_bracket(bufnr, row, col)
    local ok, node = pcall(vim.treesitter.get_node, { bufnr = bufnr, pos = { row, col } })
    if not ok or not node then
        return false
    end
    local n = node
    while n do
        if non_code_node_types[n:type()] then
            return false
        end
        n = n:parent()
    end
    return true
end

-- 节点是否覆盖光标位置
-- 同行节点要求光标列在 [sc, ec) 内；跨行节点要求光标在 { } 之间
local function node_covers(row, col, sr, sc, er, ec)
    if sr == er then
        return sc <= col and col < ec
    end
    if row == sr then
        return col >= sc
    end
    if row == er then
        return col <= ec - 1
    end
    return row > sr and row < er
end

-- 行内括号对扫描带缓存：这段匹配的结果只依赖「行内容」，与光标位置无关，
-- 所以插模式里光标在同一行内移动（如 Tab 跳参数占位符）时可整段复用，
-- 免去重复的 treesitter 查询 —— 实测这是写代码掉帧的主因。
-- 键含 bufnr，避免不同缓冲区之间串味。
local inline_scan_cache = { bufnr = -1, row = -1, text = false, pairs = nil }

local function scan_inline_pairs(bufnr, row, line)
    if
        inline_scan_cache.bufnr == bufnr
        and inline_scan_cache.row == row
        and inline_scan_cache.text == line
    then
        return inline_scan_cache.pairs
    end

    local stack = {}
    local inline_pairs = {}
    for c = 0, #line - 1 do
        local ch = line:sub(c + 1, c + 1)
        if bracket_pairs[ch] then
            if is_real_bracket(bufnr, row, c) then
                stack[#stack + 1] = { ch, c }
            end
        elseif closing_pairs[ch] then
            if is_real_bracket(bufnr, row, c) then
                local top = stack[#stack]
                if top and bracket_pairs[top[1]] == ch then
                    inline_pairs[#inline_pairs + 1] = { top[2], c }
                    stack[#stack] = nil
                else
                    -- 失配闭括号（多为跨行块的 }）：丢弃栈顶即可
                    stack[#stack] = nil
                end
            end
        end
    end

    inline_scan_cache.bufnr = bufnr
    inline_scan_cache.row = row
    inline_scan_cache.text = line
    inline_scan_cache.pairs = inline_pairs
    return inline_pairs
end

local function update(bufnr)
    api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)

    local cursor = api.nvim_win_get_cursor(0)
    local row = cursor[1] - 1
    local col = cursor[2]
    local line = api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""

    -- 快速路径：行内没有括号类字符时两段匹配都不可能命中，省掉扫描与查树
    -- （clear_namespace 已在函数开头执行，不会残留上一次的标记）
    if not line:find('[%(%)%[%]{}<>"]') then
        return
    end

    -- A) 行内栈匹配 ( ) [ ] { }（结果按行内容缓存，光标移动时整段复用）
    local inline_pairs = scan_inline_pairs(bufnr, row, line)

    -- 行内最内层覆盖光标的括号对
    local best_inline
    for _, p in ipairs(inline_pairs) do
        if p[1] <= col and col <= p[2] then
            local span = p[2] - p[1]
            if not best_inline or span < best_inline.span then
                best_inline = { span = span, sc = p[1], ec = p[2] + 1 }
            end
        end
    end

    -- B) 节点法：{ } 块与 < > 模板中覆盖光标的最内层节点
    local best_node
    local ok, node = pcall(vim.treesitter.get_node, { bufnr = bufnr, pos = { row, col } })
    if ok and node then
        local n = node
        while n do
            local ntype = n:type()
            local in_non_code = non_code_node_types[ntype]
            -- 字符串字面量本身可作为引号连线目标；其它非代码节点直接停止上溯
            if in_non_code and ntype ~= "string_literal" then
                break
            end
            local sr, sc, er, ec = n:range()
            if node_covers(row, col, sr, sc, er, ec) then
                local open_line = api.nvim_buf_get_lines(bufnr, sr, sr + 1, false)[1] or ""
                local close_line = api.nvim_buf_get_lines(bufnr, er, er + 1, false)[1] or ""
                local open_ch = open_line:sub(sc + 1, sc + 1)
                local close_ch = close_line:sub(ec, ec)
                if node_pair_chars[open_ch] == close_ch then
                    local span = (er - sr) * 10000 + (ec - sc)
                    if not best_node or span < best_node.span then
                        best_node = {
                            span = span,
                            sr = sr,
                            sc = sc,
                            er = er,
                            ec = ec,
                            is_string = open_ch == '"', -- 字符串引号固定用黄色
                        }
                    end
                end
            end
            if in_non_code then
                break -- 已在字符串/注释内，不再向上找外层块
            end
            n = n:parent()
        end
    end

    -- C) 画最内层的一个
    if best_inline and (not best_node or best_inline.span <= best_node.span) then
        local group = get_rainbow_group(bufnr, row, best_inline.sc)
        api.nvim_buf_set_extmark(bufnr, namespace, row, best_inline.sc, {
            end_col = best_inline.ec,
            hl_group = guide_groups[group],
            hl_mode = "combine",
            priority = 120,
        })
    elseif best_node then
        -- rainbow 不给字符串引号着色，故引号连线固定用黄色；其余取该位置 delimiter 的颜色
        local group = best_node.is_string and "RainbowDelimiterYellow"
            or get_rainbow_group(bufnr, best_node.sr, best_node.sc)
        if best_node.sr == row and best_node.er == row then
            -- 同行块/模板：整段下划线
            api.nvim_buf_set_extmark(bufnr, namespace, row, best_node.sc, {
                end_col = best_node.ec,
                hl_group = guide_groups[group],
                hl_mode = "combine",
                priority = 120,
            })
        else
            -- 跨行块：{ / < 与 } / > 各画一条短下划线
            if best_node.sr == row then
                api.nvim_buf_set_extmark(bufnr, namespace, row, best_node.sc, {
                    end_col = best_node.sc + 1,
                    hl_group = guide_groups[group],
                    hl_mode = "combine",
                    priority = 120,
                })
            end
            if best_node.er == row then
                api.nvim_buf_set_extmark(bufnr, namespace, row, best_node.ec - 1, {
                    end_col = best_node.ec,
                    hl_group = guide_groups[group],
                    hl_mode = "combine",
                    priority = 120,
                })
            end
        end
    end
end

local function is_supported(bufnr)
    return supported_filetypes[vim.bo[bufnr].filetype] == true
end

function M.setup()
    namespace = api.nvim_create_namespace("inline_bracket_guides")
    refresh_highlights()

    local group = api.nvim_create_augroup("UserInlineBracketGuides", { clear = true })
    api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = refresh_highlights,
    })
    api.nvim_create_autocmd({ "BufEnter", "CursorMoved", "CursorMovedI", "TextChanged", "TextChangedI" }, {
        group = group,
        callback = function(args)
            if api.nvim_get_current_buf() == args.buf and is_supported(args.buf) then
                update(args.buf)
            end
        end,
    })
    api.nvim_create_autocmd("BufLeave", {
        group = group,
        callback = function(args)
            if is_supported(args.buf) then
                api.nvim_buf_clear_namespace(args.buf, namespace, 0, -1)
            end
        end,
    })
end

return M
