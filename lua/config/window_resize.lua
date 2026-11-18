-- 统一窗口尺寸调整：一套 <leader>z 键位，通吃文件树 / 终端 / diff 分屏
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

--- 读取 count 前缀，没有就用默认步长
---@return integer
local function currentStep()
    local n = vim.v.count
    return n > 0 and n or DEFAULT_STEP
end

function M.setup()
    local map = vim.keymap.set

    -- 键位全部避开需要按 Shift 的字符：. 与 , 代替 > 与 <，= 代替 +
    map("n", "<leader>z.", function()
        M.resize("width", currentStep())
    end, { desc = "窗口加宽" })

    map("n", "<leader>z,", function()
        M.resize("width", -currentStep())
    end, { desc = "窗口变窄" })

    map("n", "<leader>z=", function()
        M.resize("height", currentStep())
    end, { desc = "窗口加高" })

    map("n", "<leader>z-", function()
        M.resize("height", -currentStep())
    end, { desc = "窗口减高" })

    map("n", "<leader>z0", M.equalize, { desc = "窗口均分" })

    -- which-key 是 VeryLazy 才加载的，必须等它加载完再注册分组标签，
    -- 否则 require 直接失败
    vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = function()
            local ok, wk = pcall(require, "which-key")
            if ok and type(wk.add) == "function" then
                wk.add({ { "<leader>z", group = "窗口调整" } })
            end
        end,
    })
end

return M
