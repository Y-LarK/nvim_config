-- nvim 的 LSP 日志没有内置轮转机制。clangd 的 stderr 会被逐条按 ERROR 级别落盘，
-- 而单条 stderr 里带着完整的编译命令（ASTWorker building file ... Command Line: ...），
-- 本机该文件曾累积到 545 MB。
--
-- 时机是硬约束，不是风格问题：nvim 在「首次写 LSP 日志」时以 io.open(path, 'a+')
-- 打开文件并常驻持有句柄（见 runtime/lua/vim/lsp/log.lua 的 open_logfile / create_logger），
-- 中途 rename 不会生效 —— nvim 会继续往被改名的那份写。所以必须在任何 LSP 写日志
-- 之前执行，也就是 init.lua 的最顶部。

local MAX_BYTES = 8 * 1024 * 1024 -- 单份上限
local KEEP = 2 -- 保留的历史份数：lsp.log.1 / lsp.log.2

local function rotate()
    local path = vim.lsp.log.get_filename()
    local stat = vim.uv.fs_stat(path)
    if not stat or stat.size < MAX_BYTES then
        return
    end

    -- 从最旧的一份往前挪，空位腾出来后再挪当前日志
    for i = KEEP - 1, 1, -1 do
        local from = string.format("%s.%d", path, i)
        local to = string.format("%s.%d", path, i + 1)
        if vim.uv.fs_stat(from) then
            local ok, err = vim.uv.fs_rename(from, to)
            if not ok then
                vim.notify(
                    string.format("LSP 日志轮转失败：%s → %s：%s", from, to, err),
                    vim.log.levels.WARN
                )
                return
            end
        end
    end

    local ok, err = vim.uv.fs_rename(path, path .. ".1")
    if not ok then
        vim.notify(
            string.format("LSP 日志轮转失败：%s → %s.1：%s", path, path, err),
            vim.log.levels.WARN
        )
    end
end

rotate()
