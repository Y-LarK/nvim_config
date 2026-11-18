-- 统一窗口尺寸调整：<leader>z 进入 resize 模式，通吃文件树 / 终端 / diff 分屏
--
-- 模式内键位：h 变窄 / l 加宽 / k 加高 / j 减高 / = 均分
--             数字作倍数（12l = 加宽 12 步）/ q、Esc 或其它任意键退出
--
-- 为什么要按窗口类型分派，而不是统一用 :vertical resize：
--   1. nvim-tree 内部记着自己的宽度（view_state.Active.width），而
--      actions.open_file.resize_window = true 会在每次打开文件后按这个值
--      重设窗口宽度。直接 :vertical resize 只改了窗口、没改内部值 ——
--      一打开文件就被弹回配置的 32（实测）。必须走 nvim-tree 自己的
--      tree.resize()，它会同步内部宽度。
--   2. float 窗口（toggleterm 默认方向就是 float）不归 :resize 管，宽度和
--      高度由 win 配置里的 width/height 决定，只能改配置。
--   3. 其余普通分屏（diffview / neogit / trouble / aerial / 手动 split）
--      用原生 :vertical resize / :resize 即可。
--
-- 注意：float 窗口调过的尺寸不会跨会话保存，重开终端会回到 float_opts 的值。

local M = {}

-- 没有 count 前缀时的默认步长（列 / 行）
local DEFAULT_STEP = 2

---@param win integer
---@return boolean
local function isFloat(win)
    return vim.api.nvim_win_get_config(win).relative ~= ""
end

---@param bufnr integer
---@return boolean
local function isNvimTree(bufnr)
    return vim.bo[bufnr].filetype == "NvimTree"
end

--- 从 nvim_win_get_config 的结果里挑出 nvim_win_set_config 接受的字段。
--- 直接回传原表会因 external / mouse 等只读字段报错，所以用白名单重建。
---@param cfg table
---@return table
local function pickFloatConfig(cfg)
    return {
        relative = cfg.relative,
        row = cfg.row,
        col = cfg.col,
        width = cfg.width,
        height = cfg.height,
        anchor = cfg.anchor,
        zindex = cfg.zindex,
        style = cfg.style,
        border = cfg.border,
        title = cfg.title,
        title_pos = cfg.title_pos,
        focusable = cfg.focusable,
    }
end

--- 调整 float 窗口（终端）的宽或高
---@param win integer
---@param axis "width"|"height"
---@param delta integer
local function resizeFloat(win, axis, delta)
    local cfg = pickFloatConfig(vim.api.nvim_win_get_config(win))
    if axis == "width" then
        cfg.width = math.max(1, cfg.width + delta)
    else
        cfg.height = math.max(1, cfg.height + delta)
    end
    -- relative = "external" 的窗口不接受 set_config，失败就静默放弃
    pcall(vim.api.nvim_win_set_config, win, cfg)
end

--- 调整普通分屏窗口
---@param axis "width"|"height"
---@param delta integer
local function resizeSplit(axis, delta)
    -- 必须用相对写法：:resize N 是绝对高度，:resize +N / -N 才是增减。
    -- 负数的 "-" 本身已表达方向，正数要手动补 "+"。
    local sign = delta > 0 and "+" or ""
    if axis == "width" then
        -- 已到最小宽度时 Vim 抛 E36，静默忽略
        pcall(vim.cmd, ("vertical resize %s%d"):format(sign, delta))
    else
        pcall(vim.cmd, ("resize %s%d"):format(sign, delta))
    end
end

--- 调整当前窗口尺寸
---@param axis "width"|"height"
---@param delta integer 正数变大，负数变小
function M.resize(axis, delta)
    local win = vim.api.nvim_get_current_win()

    -- nvim-tree 优先判断：它必须走自己的 API 才能持久化宽度
    if isNvimTree(vim.api.nvim_get_current_buf()) then
        local ok, treeApi = pcall(require, "nvim-tree.api")
        if ok then
            treeApi.tree.resize({ relative = delta })
            return
        end
    end

    if isFloat(win) then
        resizeFloat(win, axis, delta)
        return
    end

    resizeSplit(axis, delta)
end

--- 均分所有窗口；float 窗口不参与
function M.equalize()
    if isFloat(vim.api.nvim_get_current_win()) then
        return
    end
    vim.cmd("wincmd =")
end

-- 模式内的提示行
local MODE_HINT = "[RESIZE]  h 变窄   l 加宽   k 加高   j 减高   = 均分   数字×倍数   q/Esc 退出"

--- 通知 lualine 重新渲染状态栏。
--- 阻塞在 getcharstr 期间 lualine 不会自己刷新（没有事件循环），必须手动 refresh，
--- 否则组件要等退出模式后的下一次普通按键才更新。lualine 未加载时静默跳过。
local function refreshLualine()
    local ok, lualine = pcall(require, "lualine")
    if ok and type(lualine.refresh) == "function" then
        pcall(lualine.refresh, { placement = "statusline", force = true })
    end
end

--- 进入窗口调整模式。
---
--- 为什么用阻塞式 getcharstr 循环，而不是临时改键位：
---   1. 改键位必须保存/恢复用户与插件对 h/j/k/l 的映射，一旦中途出错就永久污染；
---   2. `<leader>z` 只做入口、没有更长的 <leader>zX 子映射，按键不需要等 timeoutlen。
--- 代价：模式期间不能切窗口，只能调当前窗口。
function M.startMode()
    local multiplier = 1
    local hasCount = false

    local function refresh()
        -- lualine 组件读这个全局变量；nil = 不在模式中
        vim.g.window_resize_mode = hasCount and ("↔ RESIZE  ×" .. multiplier) or "↔ RESIZE"
        refreshLualine()

        -- 有数字累积时把倍数显示出来，否则用户不知道 3 已经记下了
        local hint = hasCount and (MODE_HINT .. "    倍数 ×" .. multiplier) or MODE_HINT
        vim.api.nvim_echo({ { hint, "WarningMsg" } }, false, {})
        -- 阻塞在 getcharstr 里时屏幕不会自动重绘，手动刷一次才能看到尺寸变化
        vim.cmd("redraw")
    end

    refresh()
    while true do
        local ok, key = pcall(vim.fn.getcharstr)
        -- 取不到字符（被打断）直接退出，避免死循环
        if not ok or key == "" then
            break
        end

        -- q / Esc / Ctrl-C 退出
        if key == "q" or key == "\27" or key == "\3" then
            break
        end

        if key:match("^[1-9]$") then
            -- 数字累积成倍数：输入 12l 就是加宽 12 步。
            -- 数字本身不产生动作，不能在这里重置倍数，要留给下一个方向键用。
            multiplier = (hasCount and multiplier * 10 or 0) + tonumber(key)
            hasCount = true
            refresh()
        else
            if key == "h" then
                M.resize("width", -multiplier * DEFAULT_STEP)
            elseif key == "l" then
                M.resize("width", multiplier * DEFAULT_STEP)
            elseif key == "k" then
                M.resize("height", multiplier * DEFAULT_STEP)
            elseif key == "j" then
                M.resize("height", -multiplier * DEFAULT_STEP)
            elseif key == "=" then
                M.equalize()
            else
                -- 其它键一律退出，避免吞掉误触
                break
            end

            multiplier = 1
            hasCount = false
            refresh()
        end
    end

    -- 退出（q / Esc / 未知键 / 读键失败）：清掉状态，让状态栏立刻恢复
    vim.g.window_resize_mode = nil
    refreshLualine()
end

function M.setup()
    vim.keymap.set("n", "<leader>z", M.startMode, { desc = "窗口调整模式" })
end

return M
