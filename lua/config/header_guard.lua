-- 新建空头文件时自动插入 #ifndef 头文件守卫。
-- 三条同时满足才写入：BufNewFile 事件、扩展名在白名单内、buffer 确实为空。
-- 这样复制来的骨架、其他插件预填的模板、以及任何已有内容的头文件都不会被改写。
-- 写入使用一次 nvim_buf_set_lines 成块完成，`u` 可整体撤销。

-- VSCode 嵌入模式下由 VSCode 自己管编辑行为，不介入
if vim.g.vscode then
    return
end

local EXTENSIONS = {
    h = true,
    hpp = true,
    hh = true,
    hxx = true,
    inl = true,
}

-- UTF-8 前导字节 -> 该字符占用的字节数。
-- 0xC0 以下按 1 字节推进，避免遇到意外续字节（0b10xxxxxx）时死循环。
local function utf8CharLen(byteVal)
    if byteVal < 0xC0 then
        return 1
    elseif byteVal < 0xE0 then
        return 2
    elseif byteVal < 0xF0 then
        return 3
    end
    return 4
end

-- 宏名只取 basename（如 foo/bar.h -> BAR_H_）：
-- ASCII 字母数字转大写保留，其余字符（含多字节字符）各换成一个下划线，末尾补一个下划线。
-- 按字符而非按字节推进：string.gsub 逐字节匹配，中文文件名会吐出 3 倍长度的下划线串。
local function buildGuardName(fileName)
    local base = vim.fn.fnamemodify(fileName, ":t")
    local out = {}
    local i = 1
    local len = #base
    while i <= len do
        local byteVal = base:byte(i)
        local ch = base:sub(i, i)
        if ch:match("^%w$") then
            out[#out + 1] = ch:upper()
            i = i + 1
        else
            out[#out + 1] = "_"
            i = i + utf8CharLen(byteVal)
        end
    end
    local name = table.concat(out) .. "_"

    -- C/C++ 标识符不能以数字开头，否则 #ifndef 1FOO_H_ 无法编译
    if name:match("^%d") then
        name = "HDR_" .. name
    end
    return name
end

local function insertGuard(args)
    local buf = args.buf
    local fileName = vim.api.nvim_buf_get_name(buf)
    local ext = vim.fn.fnamemodify(fileName, ":e"):lower()
    if not EXTENSIONS[ext] then
        return
    end

    -- 空 buffer 的唯一可信判据：只有一行且该行为空。
    -- 已存在的空文件在磁盘上也是这个形态，但那种文件加 guard 正合适。
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    if #lines ~= 1 or lines[1] ~= "" then
        return
    end

    local guard = buildGuardName(fileName)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "#ifndef " .. guard,
        "#define " .. guard,
        "",
        "#endif  // " .. guard,
    })
end

-- 用 "*" 统一接收再自行按扩展名过滤：autocmd 的 pattern 大小写敏感，
-- 逐个列出 *.h/*.H/*.hpp/*.HPP 既冗长又容易漏；回调里 :e + lower 一次搞定。
vim.api.nvim_create_autocmd("BufNewFile", {
    pattern = "*",
    callback = insertGuard,
    desc = "为新建的 C/C++ 空头文件自动写入 #ifndef 守卫",
})
