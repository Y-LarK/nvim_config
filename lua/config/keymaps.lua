local map = vim.keymap.set

-- 2. 基础操作
map("n", "<leader>w", "<cmd>w<cr>", { desc = "保存" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "退出" })
map("n", "<leader>Q", "<cmd>qa!<cr>", { desc = "强制退出所有" })

-- 3. 取消搜索高亮 (这里也改用 map，不要写 keymap.set)
map("n", "<leader>nh", ":nohl<CR>", { desc = "取消搜索高亮" })

-- 4. 插入模式快捷键 (jk/kj 退出插入模式)
map("i", "jk", "<ESC>", { desc = "使用 jk 退出插入模式" })
map("i", "kj", "<ESC>", { desc = "使用 kj 退出插入模式" })
map("n", "H", "^", { desc = "跳到行首" })
map("n", "L", "$", { desc = "跳到行尾" })
-- 使用 Alt + h/l 在标签页之间左右横跳（非常适合 C++ 头文件/源文件切换）
map("n", "<A-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "上一个标签" })
map("n", "<A-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "下一个标签" })

-- 关闭当前标签
map("n", "<leader>bc", "<cmd>bdelete<cr>", { desc = "关闭当前 Buffer" })

-- 切换 nvim-tree
map("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "切换文件树" })

-- Telescope 快捷键
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "查找文件" })
map("n", "<leader>fw", "<cmd>Telescope live_grep<cr>", { desc = "全局搜索文本" })
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "查找已打开的缓冲区" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "查找帮助文档" })
map("n", "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", { desc = "查找当前文件符号" })

-- 分屏
map("n", "<leader>sv", "<C-w>v", { desc = "左右分屏" })
map("n", "<leader>sh", "<C-w>s", { desc = "上下分屏" })

-- 快速窗口跳转
map("n", "<C-h>", "<C-w>h", { desc = "跳转到左侧窗口" })
map("n", "<C-j>", "<C-w>j", { desc = "跳转到底部窗口" })
map("n", "<C-k>", "<C-w>k", { desc = "跳转到顶部窗口" })
map("n", "<C-l>", "<C-w>l", { desc = "跳转到右侧窗口" })

-- Flash.nvim 跳转
-- 基础跳转：按下 s 输入两个字母开始丝滑移动
map({ "n", "x", "o" }, "s", function() require("flash").jump() end, { desc = "Flash 跳转" })

-- 基于 Treesitter 的选择：快速选中函数、代码块等
map({ "n", "x", "o" }, "S", function() require("flash").treesitter() end, { desc = "Flash Treesitter 选中" })

-- 远程操作：比如 yr 跳转并复制目标单词
map("o", "r", function() require("flash").remote() end, { desc = "Remote Flash" })

-- 搜索模式集成：在 / 搜索时按 <c-s> 触发 flash
map({ "n", "o", "x" }, "R", function() require("flash").treesitter_search() end, { desc = "Treesitter 搜索" })

-- cmake
map("n", "<leader>cg", "<cmd>CMakeGenerate<cr>", { desc = "CMake 生成 (Generate)" })
map("n", "<leader>cb", "<cmd>CMakeBuild<cr>", { desc = "CMake 构建 (Build)" })
map("n", "<leader>cr", "<cmd>CMakeRun<cr>", { desc = "CMake 运行 (Run)" })
map("n", "<leader>cd", "<cmd>CMakeDebug<cr>", { desc = "CMake 调试 (Debug)" })
map("n", "<leader>ct", "<cmd>CMakeSelectTarget<cr>", { desc = "选择构建目标" })
map("n", "<leader>cc", "<cmd>CMakeClean<cr>", { desc = "CMake 清理 (Clean)" })
map("n", "<leader>cD", "<cmd>lua vim.fn.delete(vim.fn.getcwd() .. '/build', 'rf')<cr>", { desc = "删除 build 目录" })
map("n", "<leader>ck", "<cmd>CMakeStop<cr>", { desc = "停止当前任务" })

-- 平滑滚动快捷键 (Neoscroll)
-- 使用插件默认的函数来实现平滑翻页
map("n", "<C-u>", function() require('neoscroll').ctrl_u({ duration = 250 }) end, { desc = "平滑向上翻页" })
map("n", "<C-d>", function() require('neoscroll').ctrl_d({ duration = 250 }) end, { desc = "平滑向下翻页" })
map("n", "<C-b>", function() require('neoscroll').ctrl_b({ duration = 450 }) end, { desc = "平滑向上翻整屏" })
map("n", "<C-f>", function() require('neoscroll').ctrl_f({ duration = 450 }) end, { desc = "平滑向下翻整屏" })
-- 平滑对齐
map("n", "zt", function() require('neoscroll').zt({ duration = 150 }) end, { desc = "平滑将当前行置顶" })
map("n", "zz", function() require('neoscroll').zz({ duration = 150 }) end, { desc = "平滑将当前行居中" })
map("n", "zb", function() require('neoscroll').zb({ duration = 150 }) end, { desc = "平滑将当前行置底" })
-- LSP
map("n", "K", vim.lsp.buf.hover, { desc = "LSP 悬浮文档" })
local gd_state = {} -- 记录上次 gd 跳转来源
map("n", "gd", function()
    local cur_winnr = vim.api.nvim_get_current_win()
    local cur_buf = vim.api.nvim_get_current_buf()
    local cur_pos = vim.api.nvim_win_get_cursor(cur_winnr)
    if gd_state.buf == cur_buf and gd_state.winnr == cur_winnr
        and gd_state.pos[1] == cur_pos[1] and gd_state.pos[2] == cur_pos[2] then
        -- 第二次 gd → 跳定义(.c 函数体)
        gd_state = {}
        vim.lsp.buf.definition()
    else
        -- 第一次 gd → 跳声明(.h)
        gd_state = { buf = cur_buf, winnr = cur_winnr, pos = cur_pos }
        vim.lsp.buf.declaration()
    end
end, { desc = "跳转声明/定义 (gd→.h声明, 再次gd→.c定义)" })
map("n", "gr", vim.lsp.buf.references, { desc = "查看引用" })
map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "代码操作" })
map("n", "<leader>dc", function()
    -- 在函数/类/结构体上方生成 /** ... */ Doxygen 注释
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ""
    -- 解析：函数 / 类 / 结构体 / 枚举
    local fname = line:match("%S+%s+([%w_]+)%s*%(") or line:match("([%w_]+)%s*%(")
    local args, ret, is_class = {}, ""
    if fname then
        -- 函数
        for a in (line:match("%((.-)%)") or ""):gmatch("[^,]+") do
            local name = a:match("(%w+)%s*$") or ""
            if name ~= "" and name ~= "void" then table.insert(args, name) end
        end
        ret = line:match("^(%S+)%s") or "void"
    else
        -- 类 / 结构体 / 枚举
        fname = line:match("class%s+([%w_]+)") or line:match("struct%s+([%w_]+)") or line:match("enum%s+([%w_]+)")
        is_class = fname ~= nil
    end
    if not fname then
        -- 不是函数/类 → 行尾添加 ///< 注释
        vim.cmd("normal! A ///<  ")
        vim.cmd("startinsert")
        return
    end
    -- 构造注释
    local comment = { "/**" }
    table.insert(comment, " * @brief  ")
    if is_class then
        -- 类 / 结构体 / 枚举 模板
        local kind = line:match("(class)") or line:match("(struct)") or line:match("(enum)") or "class"
        comment = {
            "/**",
            " * @" .. kind .. " " .. fname,
            " * @brief  ",
            " * @note  ",
            " */",
        }
        vim.api.nvim_buf_set_lines(0, row, row, false, comment)
        vim.api.nvim_win_set_cursor(0, { row + 3, 10 })
        vim.cmd("startinsert!")
        return
    end
    for _, a in ipairs(args) do
        table.insert(comment, " * @param " .. a .. "  ")
    end
    if ret and ret ~= "void" then
        table.insert(comment, " * @return  ")
    end
    table.insert(comment, " */")
    -- 插入到定义行上方
    vim.api.nvim_buf_set_lines(0, row, row, false, comment)
    vim.api.nvim_win_set_cursor(0, { row + 2, 11 })
    vim.cmd("startinsert!")
end, { desc = "生成 Doxygen 注释" })
map("n", "<leader>lk", vim.lsp.buf.signature_help, { desc = "函数签名" })

-- 统一注释：normal → //   visual → /* */
map("n", "<leader>/", "gcc", { remap = true, desc = "切换行注释 //" })
map("v", "<leader>/", "gb", { remap = true, desc = "切换块注释 /* */" })

-- Markdown 链接跳转：锚点跳转 / URL 浏览器打开
map("n", "<leader>mj", function()
    -- 1) treesitter 精确获取光标下的 link_destination
    local node = vim.treesitter.get_node()
    if node then
        while node do
            if node:type() == "link_destination" then
                local url = vim.treesitter.get_node_text(node, 0)
                if url:match("^https?://") or url:match("^www%.") then
                    vim.fn.jobstart({ "xdg-open", url }, { detach = true })
                    return
                elseif url:match("^#") then
                    local text = url:sub(2):gsub("%-", " ")
                    local pat = [[^#\+\s\+]] .. vim.pesc(text) .. [[\>]]
                    vim.cmd("normal! m'")               -- 记入跳转列表，Ctrl-o 可回
                    vim.fn.search(pat, "w")
                    return
                end
            end
            node = node:parent()
        end
    end
    -- 2) 降级：行内正则（光标不在 treesitter 节点时也能用）
    local line = vim.api.nvim_get_current_line()
    local ext_url = line:match("%[.-%]%((https?://[^%)]+)%)")
    if ext_url then
        vim.fn.jobstart({ "xdg-open", ext_url }, { detach = true })
        return
    end
    local anchor = line:match("%[.-%]%((#.-)%)")
    if anchor then
        local text = anchor:sub(2):gsub("%-", " ")
        local pat = [[^#\+\s\+]] .. vim.pesc(text) .. [[\>]]
        vim.cmd("normal! m'")                           -- 记入跳转列表，Ctrl-o 可回
        vim.fn.search(pat, "w")
    end
end, { desc = "跳转 Markdown 锚点 / 打开链接" })

-- 头文件 ↔ 源文件切换
map("n", "<leader>ha", function()
    local dir = vim.fn.expand("%:p:h")
    local base = vim.fn.expand("%:t:r")
    local ext = vim.fn.expand("%:e")
    -- .c/.cpp/.cc → .h/.hpp
    local targets = {}
    if ext:match("^c") then
        targets = { base .. ".h", base .. ".hpp" }
    elseif ext:match("^h") then
        targets = { base .. ".c", base .. ".cpp", base .. ".cc" }
    else
        return
    end
    local search = { dir, dir .. "/../include", dir .. "/../src", dir .. "/include", dir .. "/src" }
    for _, sdir in ipairs(search) do
        for _, tgt in ipairs(targets) do
            local path = sdir .. "/" .. tgt
            if vim.fn.filereadable(path) == 1 then
                vim.cmd("e " .. path)
                return
            end
        end
    end
    -- 找不到就新建同级文件
    vim.cmd("e " .. dir .. "/" .. targets[1])
end, { desc = "头文件↔源文件切换" })

-- Markdown 折行开关（大表格时关掉看对齐）
map("n", "<leader>tw", function()
    vim.wo.wrap = not vim.wo.wrap
end, { desc = "切换折行" })
