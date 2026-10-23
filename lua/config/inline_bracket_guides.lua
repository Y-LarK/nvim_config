local M = {}

local api = vim.api
local namespace
local guide_groups = {}

-- 幽灵下划线（覆盖括号内的 LSP inlay hint）：连线激活时把范围内 hint extmark 的
-- chunk 高亮就地改写为合并组，光标离开后还原。改写由本文件自建 decoration
-- provider 的 on_line 执行 —— on_line 恒在所有 on_win（含 runtime inlay_hint
-- provider 的 clear+重设）之后运行，打字时 LSP 每次响应重设 hint 都能在同帧补写，
-- 不闪烁。依赖三点 runtime 细节（升级 nvim 后需重测）：ns 名 "nvim.lsp.inlayhint"、
-- hint extmark 的 chunk 结构（hl 为 LspInlayHint、padding 是无 hl 的空格 chunk）、
-- on_line 晚于 on_win 的重绘顺序。任一失效都静默降级为「幽灵无下划线」，连线不受影响。
-- 注意：范围 extmark 的高亮够不到不带 hl_mode 的 virt_text（0.12.5 实测），所以
-- 必须改写 hint extmark 本体，而不是指望 merge。
local hint_groups = {}       -- RainbowDelimiter<X> -> InlineBracketGuideHint<X>
local lsp_hint_ns            -- "nvim.lsp.inlayhint" 的 ns id，懒查找后缓存
local active_hint            -- nil 或 { bufnr, row, sc, ec, hl }，仅同行整段连线时置位
local rewritten_hints = {}   -- ["bufnr_id"] = { bufnr, row, vt, pos }，恢复用
local hint_feature_ok = true -- provider 内出错即关闸，不让重绘路径反复报错

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

-- 连线版 hint 组：LspInlayHint 的解析属性 + underline + sp=该层级彩虹色。
-- LspInlayHint 可能是 link，须取解析值再扩展，否则会丢 fg/italic。
local function build_hint_group(color)
    local ok, base = pcall(api.nvim_get_hl, 0, { name = "LspInlayHint", link = false })
    local def = ok and base or {}
    def.underline = true
    def.sp = color
    if not def.fg then
        def.fg = 0xb8c0d8 -- 解析失败时的兜底 = 主题里 LspInlayHint 的定义
        def.italic = true
    end
    return def
end

local function refresh_highlights()
    for _, group in ipairs(rainbow_highlights) do
        local color = api.nvim_get_hl(0, { name = group, link = false }).fg or "#9098b8"
        local suffix = group:sub(#"RainbowDelimiter" + 1)
        local guide_group = "InlineBracketGuide" .. suffix
        api.nvim_set_hl(0, guide_group, {
            underline = true,
            sp = color,
        })
        guide_groups[group] = guide_group
        local hint_group = "InlineBracketGuideHint" .. suffix
        api.nvim_set_hl(0, hint_group, build_hint_group(color))
        hint_groups[group] = hint_group
    end
end

-- 从语法树算层级，不读 rainbow 的 extmark：补全菜单可见时 rainbow 会跳过高亮更新
-- 且事后不补刷，此时查 extmark 会拿到过期颜色，导引线就与括号本身脱色。
local function get_rainbow_group(bufnr, row, col)
    local level = require("config.rainbow_level").level_at(bufnr, row, col)
    if not level then
        return "RainbowDelimiterViolet"
    end
    return rainbow_highlights[(level - 1) % #rainbow_highlights + 1]
end

-- 懒查找 LSP inlay hint 的 ns：inlay_hint 模块懒加载，可能尚未注册；
-- ns id 整个会话稳定，找到即缓存，找不到（LSP 未启用）就静默降级。
local function get_lsp_hint_ns()
    if lsp_hint_ns then
        return lsp_hint_ns
    end
    local ok, nss = pcall(api.nvim_get_namespaces)
    if ok then
        lsp_hint_ns = nss["nvim.lsp.inlayhint"]
    end
    return lsp_hint_ns
end

-- chunk 是否已全部是合并组（幂等闸门：已是则跳过 set，防脏行引发持续重绘）
local function is_hint_rewritten(vt, merged)
    for _, chunk in ipairs(vt) do
        if chunk[1] ~= "" and chunk[2] ~= merged then
            return false
        end
    end
    return #vt > 0
end

-- 还原单条改写。extmark 可能已被 LSP provider 清掉（每次响应换新 id），
-- 对已删除的 id 带 id 参数 set 会新建僵尸 extmark，必须先查存在性。
local function restore_hint_id(key)
    local entry = rewritten_hints[key]
    if not entry then
        return
    end
    rewritten_hints[key] = nil
    local ns = get_lsp_hint_ns()
    if not ns then
        return
    end
    local ok, pos = pcall(api.nvim_buf_get_extmark_by_id, entry.bufnr, ns, entry.id, {})
    if ok and pos and #pos > 0 then
        pcall(api.nvim_buf_set_extmark, entry.bufnr, ns, pos[1], pos[2], {
            id = entry.id,
            virt_text = entry.vt,
            virt_text_pos = entry.pos,
        })
    end
end

local function restore_buf_hints(bufnr)
    for key, entry in pairs(rewritten_hints) do
        if entry.bufnr == bufnr then
            restore_hint_id(key)
        end
    end
end

local function restore_all_hints()
    for key in pairs(rewritten_hints) do
        restore_hint_id(key)
    end
end

-- 把 row 上位于连线开区间 (sc, ec) 的 hint extmark chunk 改写为合并组，
-- 返回本行仍在改写状态的 id 键集合。列过滤在 Lua 侧做，不赌 get_extmarks
-- 端点的开闭语义；extmark id 按 buffer 取值，键里拼 bufnr 防跨缓冲区撞 id。
local function rewrite_hint_row(bufnr, row)
    local ns = get_lsp_hint_ns()
    if not ns then
        return {}
    end
    local merged = active_hint.hl
    local ok, marks = pcall(api.nvim_buf_get_extmarks, bufnr, ns, 0, -1, { details = true })
    if not ok then
        return {}
    end
    local kept = {}
    for _, m in ipairs(marks) do
        local id, mark_row, col, details = m[1], m[2], m[3], m[4]
        local key = bufnr .. "_" .. id
        if
            mark_row == row
            and col > active_hint.sc
            and col < active_hint.ec
            and details.virt_text
            and #details.virt_text > 0
        then
            kept[key] = true
            if not is_hint_rewritten(details.virt_text, merged) then
                local ok_pos, pos = pcall(api.nvim_buf_get_extmark_by_id, bufnr, ns, id, {})
                if ok_pos and pos and #pos > 0 then
                    local vt = {}
                    for i, chunk in ipairs(details.virt_text) do
                        vt[i] = { chunk[1], merged } -- padding 空格也上组，下划线不留断口
                    end
                    rewritten_hints[key] = {
                        bufnr = bufnr,
                        id = id,
                        row = pos[1],
                        vt = details.virt_text,
                        pos = details.virt_text_pos or "inline",
                    }
                    pcall(api.nvim_buf_set_extmark, bufnr, ns, pos[1], pos[2], {
                        id = id,
                        virt_text = vt,
                        virt_text_pos = rewritten_hints[key].pos,
                    })
                end
            end
        end
    end
    return kept
end

-- 幽灵下划线的唯一执行点（重绘帧内运行）：本行是连线行 → 改写范围内的、
-- 还原滑出范围的；非连线行 → 只清该行的账。全部 pcall，出错即整体关闸降级。
local function on_line_provider(_, _, bufnr, lnum)
    if not hint_feature_ok or (not active_hint and not next(rewritten_hints)) then
        return
    end
    local ok, err = pcall(function()
        local kept = {}
        if active_hint and active_hint.bufnr == bufnr and active_hint.row == lnum then
            kept = rewrite_hint_row(bufnr, lnum)
        end
        for key, entry in pairs(rewritten_hints) do
            if entry.bufnr == bufnr and entry.row == lnum and not kept[key] then
                restore_hint_id(key)
            end
        end
    end)
    if not ok then
        hint_feature_ok = false
        active_hint = nil
        pcall(restore_all_hints)
        vim.schedule(function()
            vim.notify("inline_bracket_guides: 幽灵下划线已停用（" .. tostring(err) .. "）", vim.log.levels.WARN)
        end)
    end
end

-- active 变化时只切状态并触发重画；改写/恢复都由 provider 在重画帧内执行。
-- valid=true：不整体失效，按需重画受影响窗口（与 runtime inlay_hint 同款用法）。
local function apply_hint_state(bufnr, new_active)
    local same = active_hint == nil and new_active == nil
    if not same and active_hint and new_active then
        same = active_hint.bufnr == new_active.bufnr
            and active_hint.row == new_active.row
            and active_hint.sc == new_active.sc
            and active_hint.ec == new_active.ec
            and active_hint.hl == new_active.hl
    end
    if same then
        return
    end
    active_hint = new_active
    pcall(api.nvim__redraw, { buf = bufnr, valid = true, flush = false })
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
        apply_hint_state(bufnr, nil)
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

    -- C) 画最内层的一个；同行整段连线时同步置位幽灵下划线状态
    local new_active
    if best_inline and (not best_node or best_inline.span <= best_node.span) then
        local group = get_rainbow_group(bufnr, row, best_inline.sc)
        api.nvim_buf_set_extmark(bufnr, namespace, row, best_inline.sc, {
            end_col = best_inline.ec,
            hl_group = guide_groups[group],
            hl_mode = "combine",
            priority = 120,
        })
        new_active = { bufnr = bufnr, row = row, sc = best_inline.sc, ec = best_inline.ec, hl = hint_groups[group] }
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
            new_active = { bufnr = bufnr, row = row, sc = best_node.sc, ec = best_node.ec, hl = hint_groups[group] }
        else
            -- 跨行块：{ / < 与 } / > 各画一条短下划线（短线段不覆盖内部幽灵，不置位）
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
    apply_hint_state(bufnr, new_active)
end

local function is_supported(bufnr)
    return supported_filetypes[vim.bo[bufnr].filetype] == true
end

function M.setup()
    namespace = api.nvim_create_namespace("inline_bracket_guides")
    refresh_highlights()

    -- 幽灵下划线 provider：复用本模块 ns 作为 provider 标识（runtime 同款做法）
    api.nvim_set_decoration_provider(namespace, { on_line = on_line_provider })

    local group = api.nvim_create_augroup("UserInlineBracketGuides", { clear = true })
    api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = function()
            refresh_highlights()
            -- 组定义已换代：全部还原，active 置空，下次 update 按新色重新改写
            active_hint = nil
            restore_all_hints()
        end,
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
                if active_hint and active_hint.bufnr == args.buf then
                    active_hint = nil
                end
                api.nvim_buf_clear_namespace(args.buf, namespace, 0, -1)
                restore_buf_hints(args.buf)
            end
        end,
    })
end

return M
