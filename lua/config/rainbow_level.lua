-- 计算 treesitter 节点对应的 rainbow-delimiters 层级。
--
-- 为什么不读 extmark 反推：rainbow-delimiters 在补全菜单可见时会跳过高亮更新
-- （strategy/global.lua 里 `pumvisible() ~= 0` 直接 return），且事后没有补偿刷新。
-- 此时去查 extmark 会读到过期或按局部范围重算过的颜色，导致缩进连线与括号本身
-- 配色不一致（接受补全后再 dd 就能复现）。改为直接从语法树算层级，与高亮的
-- 绘制时机彻底解耦。
--
-- 为什么要复刻栈算法而不是数祖先深度：rainbow 的层级不是「容器的绝对嵌套深度」，
-- 而是 match 顺序遍历过程中的「栈内相对深度」—— 偏序不成立时栈会被清空，
-- 下一棵匹配树重新从 level 1 起算。两种算法在浅嵌套文件里恰好一致，深嵌套下
-- 会差 1 到 2 级（实测 1600 行文件上 8.7% 的 scope 节点配色不一致）。
local M = {}

local api = vim.api

local QUERY_NAME = "rainbow-delimiters"

-- 每个 buffer 一份 { tick, levels }：levels 是 container node id -> 层级。
-- 建栈需要遍历整棵匹配树，成本随文件规模线性上升（1600 行约 26ms），
-- 但结果只取决于 buffer 内容，所以按 changedtick 缓存 —— 光标移动不重建。
local cache = {}

-- query 里带 @container 的节点类型集合。从 query 文件解析而来，避免硬编码
-- 一份会随插件更新漂移的类型清单。
local container_types = {}

local function get_container_types(lang)
    local cached = container_types[lang]
    if cached then
        return cached
    end

    local types = {}
    local ok, files = pcall(vim.treesitter.query.get_files, lang, QUERY_NAME)
    if ok and files then
        for _, file in ipairs(files) do
            local lines = vim.fn.readfile(file)
            if type(lines) == "table" then
                -- query 以空行分隔模式块，逐块取首个节点类型
                local text = table.concat(lines, "\n") .. "\n\n"
                for block in text:gmatch("(.-)\n%s*\n") do
                    if block:find("@container", 1, true) then
                        local node_type = block:match("%(%s*([%w_]+)")
                        if node_type then
                            types[node_type] = true
                        end
                    end
                end
            end
        end
    end

    container_types[lang] = types
    return types
end

-- 复刻 rainbow-delimiters strategy/global.lua 的建栈逻辑。
-- 直接复用插件自己的 MatchTree/Stack，偏序判定不重写一遍。
local function build_levels(bufnr, lang, start_row, end_row)
    local ok_lib, lib = pcall(require, "rainbow-delimiters.lib")
    local ok_tree, MatchTree = pcall(require, "rainbow-delimiters.match-tree")
    local ok_stack, Stack = pcall(require, "rainbow-delimiters.stack")
    if not (ok_lib and ok_tree and ok_stack) then
        return nil
    end

    local query = lib.get_query(lang, bufnr)
    if not query then
        return nil
    end

    local ok_parser, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
    if not ok_parser or not parser then
        return nil
    end
    local trees = parser:parse()
    if not trees or not trees[1] then
        return nil
    end
    local root = trees[1]:root()

    local stack = Stack.new()
    local ok_iter = pcall(function()
        for _, match in query:iter_matches(root, bufnr, start_row, end_row) do
            local this = MatchTree.assemble(query, match)
            while stack:size() > 0 do
                local other = stack:pop()
                if this < other then
                    this(other)
                else
                    stack:push(other)
                    break
                end
            end
            stack:push(this)
        end
    end)
    if not ok_iter then
        return nil
    end

    local levels = {}
    local function walk(tree, level)
        levels[tree.match.container:id()] = level
        for child in tree.children:items() do
            walk(child, level + 1)
        end
    end
    for _, tree in stack:iter() do
        walk(tree, 1)
    end

    return levels
end

-- 节点所在的最外层 container：以它的范围建栈就能得到与全量建栈相同的层级，
-- 因为栈的分段边界本就落在最外层容器之间（实测 216/216 一致，耗时降到约 1/12）。
local function outermost_container(node, types)
    local top = nil
    local current = node
    while current do
        if types[current:type()] then
            top = current
        end
        current = current:parent()
    end
    return top
end

local function get_levels(bufnr, lang, node, types)
    local tick = api.nvim_buf_get_changedtick(bufnr)
    local entry = cache[bufnr]
    if entry and entry.tick == tick and entry.levels[node:id()] then
        return entry.levels
    end

    local top = outermost_container(node, types)
    local levels
    if top then
        local start_row, _, end_row, _ = top:range()
        levels = build_levels(bufnr, lang, start_row, end_row + 1)
    else
        levels = build_levels(bufnr, lang, 0, -1)
    end
    if not levels then
        return nil
    end

    cache[bufnr] = { tick = tick, levels = levels }
    return levels
end

--- 取节点的 rainbow 层级（1 起）。返回 nil 表示无法判定。
--- 返回的是原始层级，不取模 —— 调用方按自己的配色数组长度处理。
---@param bufnr integer
---@param node table|nil treesitter 节点
---@return integer|nil
function M.level_of(bufnr, node)
    if not node or not api.nvim_buf_is_valid(bufnr) then
        return nil
    end

    local lang = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype)
    if not lang then
        return nil
    end

    local types = get_container_types(lang)
    if not next(types) then
        return nil
    end

    local levels = get_levels(bufnr, lang, node, types)
    if not levels then
        return nil
    end
    return levels[node:id()]
end

--- 取覆盖指定位置的最内层 container 的层级。
--- 供按坐标取色的场景使用（如行内括号导引）。
---@param bufnr integer
---@param row integer 0-indexed
---@param col integer 0-indexed
---@return integer|nil
function M.level_at(bufnr, row, col)
    if not api.nvim_buf_is_valid(bufnr) then
        return nil
    end

    local ok, node = pcall(vim.treesitter.get_node, { bufnr = bufnr, pos = { row, col } })
    if not ok or not node then
        return nil
    end

    local lang = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype)
    if not lang then
        return nil
    end
    local types = get_container_types(lang)
    if not next(types) then
        return nil
    end

    -- 光标可能落在 container 内的普通节点上，向上找到最近的 container
    local current = node
    while current and not types[current:type()] do
        current = current:parent()
    end
    if not current then
        return nil
    end

    return M.level_of(bufnr, current)
end

function M.setup()
    local group = api.nvim_create_augroup("UserRainbowLevel", { clear = true })
    api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
        group = group,
        callback = function(args)
            cache[args.buf] = nil
        end,
    })
end

return M
