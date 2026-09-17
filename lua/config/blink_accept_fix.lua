-- 修复 blink.cmp 在标识符末尾接受补全时吞掉右侧字符（) ; 等）的问题
--
-- 现象：
--   for (auto it = v.begin(); it != v.en;)  在 en 后按 Tab 补 end()
--   结果变成 ... v.end()  ——  右侧的 ; 被吃掉
--
-- 根因（上游 bug，blink.cmp @ 473c928，与本机 sources 里的 transform_items 无关）：
--   item.pos 记录的是 context 创建时的光标列，而 textDocument/completion 请求是
--   异步发出的，实际发出时光标可能已经右移。clangd 按真实光标返回的
--   textEdit.range 已经把这段位移算在内了，而 compensate_for_cursor_movement
--   又按 (接受时光标 - item.pos.col) 把 range 终点平移了一次 —— 同一段位移被算了
--   两遍，终点被推到光标之外，apply 时右侧的 ) ; 一并被替换掉。
--   （item 为 Snippet 格式时更直观：先按 range 删除，再插入 newText）
--
--   实测（922 条 accept 记录中命中 2 例）：
--     请求时 col=32、clangd 终点=34、接受时 col=34 → 终点被推到 36，吞掉 2 个字符
--     正常情况 clangd 终点 == 请求时 col，补偿后正好落在接受时光标上
--
-- 修法：
--   补偿只负责把 range 终点推进到「当前光标」，不越过它。
--   终点本来就在光标右侧（transform_items 扩到词尾）时保持不动，
--   以免破坏「光标停在标识符中间补全」的行为。
--
-- 上游修复后本文件即可删除。

local text_edits = require("blink.cmp.lib.text_edits")

local original_compensate = text_edits.compensate_for_cursor_movement

--- @param text_edit lsp.TextEdit
--- @param old_pos vim.Pos 补全请求发出时的光标
--- @param new_pos vim.Pos 接受补全时的光标
--- @return lsp.TextEdit
function text_edits.compensate_for_cursor_movement(text_edit, old_pos, new_pos)
    local end_before = text_edit.range["end"].character
    local out = original_compensate(text_edit, old_pos, new_pos)

    -- 补偿前终点没越过光标，说明这段位移最多只该补到光标处；
    -- 越过光标的都是重复计算的部分，收回来。
    if end_before <= new_pos.col then
        out.range["end"].character = math.min(out.range["end"].character, new_pos.col)
    end

    return out
end
