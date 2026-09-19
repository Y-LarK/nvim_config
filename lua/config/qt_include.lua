-- 把 clangd 自动插入的 Qt 私有头改写成公开头
--
-- 现象：
--   接受 QPushButton 的补全时，clangd 插入 #include <qpushbutton.h>，
--   而 Qt 惯例是 #include <QPushButton>。
--
-- 根因（clangd 侧无解，故只能在这一层修）：
--   --header-insertion=iwyu 插入的是「声明该符号的物理头文件」。
--   /usr/include/qt6/QtWidgets/QPushButton 只是个转发头，内容是
--     #include <QtWidgets/qpushbutton.h> // IWYU pragma: export
--   Qt 用的是 IWYU 的 export 语义（「包含我等于包含那个私有头」），
--   但全树没有反向的 `IWYU pragma: private, include <QPushButton>`
--   （6.11.2 只有 qstringconverter_base.h 一处，且指向的还是私有头），
--   所以 clangd 从 qpushbutton.h 里读不到「请改用公开头包含我」的提示。
--   clangd 也没有对应配置项：Completion.HeaderInsertion 只有 IWYU / Never，
--   Style 只管插引号还是尖括号，管不了选哪个头。
--
-- 修法：
--   在 blink 的 transform_items 里改写 additionalTextEdits 的文本。
--   映射表从 Qt 自带的转发头反查得到 —— 转发头的文件名就是公开头名，
--   内容里写着它代理哪个私有头，一次 grep 全部拿到（本机 1329 条，约 17ms）。
--
-- 括号类型保持 clangd 给的原样，只换名字：配了 Style.AngledHeaders 的工程
-- 里 clangd 本来就用尖括号，改写后即 <QPushButton>。

local M = {}

local QT_INCLUDE_ROOT = "/usr/include/qt6"

-- 私有头 basename → 公开头名，首次用到时构建一次
local header_map = nil
local map_built = false

--- 扫描 Qt 的转发头，建立 qpushbutton.h → QPushButton 的反查表
--- @return table<string, string>
local function build_header_map()
    -- grep -r 保留文件名前缀，那就是公开头名（QPushButton）；
    -- 行内容形如：#include <QtWidgets/qpushbutton.h> // IWYU pragma: export
    local lines = vim.fn.systemlist(
        ("grep -r '^#include <.*> // IWYU pragma: export' %s/Qt*/Q* 2>/dev/null"):format(
            QT_INCLUDE_ROOT
        )
    )

    -- 一个私有头可能被多个公开头代理（如 qassociativeiterable.h 同时被
    -- QAssociativeIterable 与 QAssociativeIterator 代理），先收齐再消歧
    local candidates = {}
    for _, line in ipairs(lines) do
        local path, target = line:match("^(.-):#include <([^>]+)>")
        if path and target then
            local public = path:match("([^/]+)$")
            local private = target:match("([^/]+)$")
            if public and private then
                candidates[private] = candidates[private] or {}
                table.insert(candidates[private], public)
            end
        end
    end

    local map = {}
    for private, publics in pairs(candidates) do
        if #publics == 1 then
            map[private] = publics[1]
        else
            -- 多个候选时选「小写后恰好等于私有头名（去掉 .h）」的那个：
            -- qassociativeiterable.h → QAssociativeIterable（而非 QAssociativeIterator）
            local stem = private:gsub("%.h$", "")
            for _, public in ipairs(publics) do
                if public:lower() == stem then
                    map[private] = public
                    break
                end
            end
            -- 分不出就不猜，保持原样 —— qxxx.h 本身也能编译，猜错反而更糟
        end
    end

    return map
end

--- @return table<string, string>
local function get_header_map()
    if not map_built then
        -- 先置位：即使 grep 失败也不要在每次补全时反复重试
        map_built = true
        local ok, map = pcall(build_header_map)
        header_map = (ok and type(map) == "table") and map or {}
    end
    return header_map
end

--- 把 #include <qpushbutton.h> 改写为 #include <QPushButton>
--- 非 Qt 私有头、或查不到映射时原样返回
--- @param text string additionalTextEdits 的 newText
--- @return string
function M.rewrite(text)
    if type(text) ~= "string" then
        return text
    end

    -- 拆成 前缀 / 开括号 / 路径 / 闭括号 / 尾部（尾部通常是换行，
    -- 故用 [%s%S] 而非 . —— Lua 的 . 不匹配 \n）
    local head, open, path, close, tail = text:match('^(#include%s*)([<"])([^>"]*)([>"])([%s%S]*)$')
    if not path then
        return text
    end

    local basename = path:match("([^/]+)$")
    -- 只认 Qt 私有头的形态（qpushbutton.h）。项目头（widget.h）、标准库头都
    -- 直接放行，免得为一个 widget.h 就触发整张映射表的构建。
    if not (basename and basename:match("^q[a-z0-9_]+%.h$")) then
        return text
    end

    local public = get_header_map()[basename]
    if not public then
        return text
    end

    return head .. open .. public .. close .. tail
end

--- 就地改写补全项里的 include 插入，返回同一个 items 表
--- @param items blink.cmp.CompletionItem[]
--- @return blink.cmp.CompletionItem[]
function M.rewrite_items(items)
    for _, item in ipairs(items) do
        -- additionalTextEdits 是 clangd 用来插 #include 的字段（LSP 原始命名，
        -- blink 在 accept 阶段同样按这个名字取，见 completion/accept/init.lua:11）。
        -- 这里只碰 include，不动 textEdit —— 那是符号本身的替换文本。
        for _, edit in ipairs(item.additionalTextEdits or {}) do
            edit.newText = M.rewrite(edit.newText)
        end
    end
    return items
end

return M
