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
-- 清理当前构建缓存（cmake-tools 以 nvim 工作目录为项目根；无缓存时它会静默返回，这里补上提示）
map("n", "<leader>cc", function()
    local caches = vim.fn.glob(vim.fn.getcwd() .. "/build/*/CMakeCache.txt", false, true)
    if #caches == 0 then
        vim.notify("没有可清理的构建缓存，请先 <leader>cg 生成", vim.log.levels.WARN)
        return
    end
    vim.cmd("CMakeClean")
end, { desc = "CMake 清理 (Clean)" })
-- 删除 build 目录（含 cmake-tools 在项目根建的 compile_commands.json 软链，避免留下坏链）
map("n", "<leader>cX", function()
    local root = vim.fn.getcwd()
    local build = root .. "/build"
    local link = root .. "/compile_commands.json"
    local removed = {}

    if vim.fn.getftype(link) == "link" then
        vim.fn.delete(link)
        removed[#removed + 1] = "compile_commands.json 软链"
    end

    if vim.fn.isdirectory(build) == 1 then
        vim.fn.delete(build, "rf")
        if vim.fn.isdirectory(build) == 1 then
            vim.notify("删除 build 目录失败：" .. build, vim.log.levels.ERROR)
            return
        end
        table.insert(removed, 1, "build 目录")
    end

    if #removed == 0 then
        vim.notify("未找到 build 目录：" .. build, vim.log.levels.WARN)
    else
        vim.notify("已删除 " .. table.concat(removed, " + "), vim.log.levels.INFO)
    end
end, { desc = "删除 build 目录" })
map("n", "<leader>ck", "<cmd>CMakeStop<cr>", { desc = "停止当前任务" })

-- 切换构建类型（Debug/Release）并生成：复用插件的 CMakeSelectBuildType，自动选中目标类型
local function switch_build_type(target)
    return function()
        local orig_select = vim.ui.select
        vim.ui.select = function(items, opts, on_choice)
            vim.ui.select = orig_select -- 先还原，避免影响后续交互
            for _, item in ipairs(items) do
                local short = type(item) == "table" and item.short or item
                if short == target then
                    return on_choice(item)
                end
            end
            return on_choice(nil)
        end
        vim.cmd("CMakeSelectBuildType")
    end
end

map("n", "<leader>cR", switch_build_type("Release"), { desc = "CMake 切 Release 并生成" })
map("n", "<leader>cD", switch_build_type("Debug"), { desc = "CMake 切 Debug 并生成" })

-- 平滑滚动快捷键 (Neoscroll)
-- 使用插件默认的函数来实现平滑翻页
map("n", "<C-u>", function() require('neoscroll').ctrl_u({ duration = 250 }) end, { desc = "平滑向上翻页" })
map("n", "<C-d>", function() require('neoscroll').ctrl_d({ duration = 250 }) end, { desc = "平滑向下翻页" })
map("n", "<C-b>", function() require('neoscroll').ctrl_b({ duration = 450 }) end, { desc = "平滑向上翻整屏" })
map("n", "<C-f>", function() require('neoscroll').ctrl_f({ duration = 450 }) end, { desc = "平滑向下翻整屏" })
-- 平滑对齐
map("n", "zt", function() require('neoscroll').zt({ half_win_duration = 150 }) end, { desc = "平滑将当前行置顶" })
map("n", "zz", function() require('neoscroll').zz({ half_win_duration = 150 }) end, { desc = "平滑将当前行居中" })
map("n", "zb", function() require('neoscroll').zb({ half_win_duration = 150 }) end, { desc = "平滑将当前行置底" })
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
-- 虚函数多态：列出所有重写实现（gd/声明只给静态类型即基类，无法覆盖多态）
map("n", "gi", function()
    require("telescope.builtin").lsp_implementations()
end, { desc = "跳转到实现（虚函数的所有重写）" })
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
            -- 兼容数组 int arr[] / int arr[10]：先去掉 [..] 再取末尾单词
            local name = (a:gsub("%[.*%]", "")):match("(%w+)%s*$") or ""
            if name ~= "" and name ~= "void" then table.insert(args, name) end
        end
        -- 返回类型：先去行首缩进（类内成员声明有缩进），再跳过常见修饰符；
        -- 构造函数/析构函数取不到返回类型，按 void 处理（不加 @return）
        local head = line:gsub("^%s+", "")
        for _, kw in ipairs({ "virtual", "static", "inline", "explicit", "constexpr", "friend", "extern" }) do
            head = head:gsub("^" .. kw .. "%s+", "")
        end
        ret = head:match("^(.-)%s*[%w_~]+%s*%(") or "void"
        if ret == "" then
            ret = "void"
        end
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
                    vim.cmd("normal! m'") -- 记入跳转列表，Ctrl-o 可回
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
        vim.cmd("normal! m'") -- 记入跳转列表，Ctrl-o 可回
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
    elseif ext:match("^tpp$") or ext:match("^ipp$") or ext:match("^inl$") or ext:match("^tcc$") then
        -- 模板实现文件 → C++ 头文件
        targets = { base .. ".hpp", base .. ".hh", base .. ".h" }
    elseif ext:match("^hpp$") or ext:match("^hh$") or ext:match("^hxx$") then
        -- C++ 头文件 → 优先模板实现文件（模板类外实现须放在被 hpp 包含的文件里）
        targets = { base .. ".tpp", base .. ".ipp", base .. ".inl", base .. ".cc", base .. ".cpp" }
    elseif ext:match("^h") then
        targets = { base .. ".cc", base .. ".cpp", base .. ".c" }
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
end, { desc = "头文件↔源文件（含模板 .tpp）" })

-- 在 .h 成员函数声明处按 <leader>hi -> 在对应源文件生成实现骨架
map("n", "<leader>hi", function()
    if not vim.fn.expand("%:e"):match("^h") then
        vim.notify("请在头文件 (.h/.hpp) 里使用", vim.log.levels.WARN)
        return
    end

    local row = vim.api.nvim_win_get_cursor(0)[1]
    -- 声明可能跨行（参数多时换行书写），从光标行起向下累计到括号配平或遇到 ';'，
    -- 最多读 50 行兜底，避免异常输入时一路读到文件尾
    local parts, depth, seen_paren = {}, 0, false
    for i = row, math.min(row + 50, vim.api.nvim_buf_line_count(0)) do
        local l = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1] or ""
        -- 去掉续行的行首缩进，避免拼接后参数中间出现一长串空格
        -- （外层括号不可省：gsub 会返回「结果, 替换次数」两个值，
        --   直接交给 table.insert 会把次数当成位置参数而报错）
        table.insert(parts, (l:gsub("^%s+", "")))
        for ch in l:gmatch("[()]") do
            if ch == "(" then
                depth = depth + 1
                seen_paren = true
            else
                depth = depth - 1
            end
        end
        if l:find(";", 1, true) then break end
        if seen_paren and depth <= 0 then break end
    end
    local line = table.concat(parts, " ")

    -- 向上找最近的 class/struct（函数实现与静态成员定义共用）
    local function find_class(from_row)
        for i = from_row, 1, -1 do
            local l = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1] or ""
            local c = l:match("^%s*class%s+([%w_]+)") or l:match("^%s*struct%s+([%w_]+)")
            if c then return c end
        end
        return nil
    end

    -- 找对应源文件（与 <leader>ha 相同的搜索路径）；.hpp 优先模板实现文件 .tpp/.ipp
    local function find_source_file()
        local dir, base = vim.fn.expand("%:p:h"), vim.fn.expand("%:t:r")
        local cur_ext = vim.fn.expand("%:e")
        local src_exts = { ".cc", ".cpp", ".cxx" }
        if cur_ext:match("^hpp$") or cur_ext:match("^hh$") or cur_ext:match("^hxx$") then
            src_exts = { ".tpp", ".ipp", ".inl", ".cc", ".cpp" }
        end
        for _, sdir in ipairs({ dir, dir .. "/../src", dir .. "/src" }) do
            for _, e in ipairs(src_exts) do
                local p = sdir .. "/" .. base .. e
                if vim.fn.filereadable(p) == 1 then return p end
            end
        end
        return nil
    end

    -- 去掉行尾注释、分号、首尾空白
    local decl = line:gsub("//.*$", ""):gsub(";%s*$", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if decl == "" or decl:match("^#") then
        vim.notify("当前行不是函数声明", vim.log.levels.WARN)
        return
    end

    local head, args = decl:match("^(.-)(%b())")
    if not head or not args then
        -- 不是函数声明，按「静态成员变量」处理：
        --   static std::vector<User> userVec;  →  std::vector<User> CData::userVec;
        if not decl:match("^static%f[%W]") then
            vim.notify("无法解析：既不是函数声明，也不是 static 成员变量", vim.log.levels.WARN)
            return
        end
        -- constexpr / inline 的静态成员自 C++17 起是隐式 inline，类内定义即可，
        -- 在源文件里再写一遍会重复定义报错，必须跳过
        if decl:match("%f[%w]constexpr%f[%W]") or decl:match("%f[%w]inline%f[%W]") then
            vim.notify("constexpr / inline 静态成员无需在源文件定义（C++17 起隐式 inline）", vim.log.levels.WARN)
            return
        end

        -- 去掉 static、去掉初始化器（源文件里的定义不能再带）
        local body = decl:gsub("^static%s+", ""):gsub("%s*=%s*.*$", "")
        local var = body:match("([%w_]+)%s*$")
        local vtype = var and body:sub(1, #body - #var):gsub("%s+$", "") or ""
        if not var or vtype == "" then
            vim.notify("未识别到变量名或类型", vim.log.levels.WARN)
            return
        end

        local cls = find_class(row)
        if not cls then
            vim.notify("未找到所属 class/struct", vim.log.levels.WARN)
            return
        end
        local cpp = find_source_file()
        if not cpp then
            vim.notify("未找到对应源文件（.cc/.cpp/.cxx 或模板实现文件）", vim.log.levels.WARN)
            return
        end

        vim.cmd("e " .. vim.fn.fnameescape(cpp))
        -- 已有定义则只跳转，不重复生成
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        for i, l in ipairs(lines) do
            if l:find(cls .. "::" .. var, 1, true) then
                vim.api.nvim_win_set_cursor(0, { i, 0 })
                vim.notify("定义已存在，已跳转", vim.log.levels.INFO)
                return
            end
        end

        -- 插到第一个「类名:: 且带参数列表」的函数定义之前，
        -- 让变量定义集中在 include 之后、函数之前
        local at = #lines
        for i, l in ipairs(lines) do
            if l:match("^%s*" .. vim.pesc(cls) .. "%s*::") and l:find("(", 1, true) then
                at = i - 1
                break
            end
        end
        local def = vtype .. " " .. cls .. "::" .. var .. ";"
        vim.api.nvim_buf_set_lines(0, at, at, false, { def })
        vim.api.nvim_win_set_cursor(0, { at + 1, 0 })
        vim.notify("已生成静态成员定义：" .. def, vim.log.levels.INFO)
        return
    end
    local tail = decl:sub(#head + #args + 1)

    local name = head:match("([%w_~][%w_]*)$")
    if not name then
        vim.notify("未识别到函数名", vim.log.levels.WARN)
        return
    end

    -- 返回类型 = head 去掉函数名，再剔除常见限定符
    local ret = head:sub(1, #head - #name)
    for _, kw in ipairs({ "virtual", "static", "inline", "explicit", "friend", "constexpr" }) do
        ret = ret:gsub("%f[%w]" .. kw .. "%f[%W]", " ")
    end
    ret = ret:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")

    -- 参数去掉默认值（实现里不能再写）
    local params = args:gsub("%s*=%s*[^,)]+", "")
    -- 尾部：保留 const/noexcept，丢弃 override/final/=0/=default/=delete
    tail = tail:gsub("%f[%w]override%f[%W]", "")
        :gsub("%f[%w]final%f[%W]", "")
        :gsub("%s*=%s*[%w_]+", "")
        :gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")

    -- 所属类：向上找最近的 class/struct
    local cls = find_class(row)
    if not cls then
        vim.notify("未找到所属 class/struct", vim.log.levels.WARN)
        return
    end

    -- 找对应源文件
    local cpp = find_source_file()
    if not cpp then
        vim.notify("未找到对应源文件（.cc/.cpp/.cxx 或模板实现文件）", vim.log.levels.WARN)
        return
    end

    vim.cmd("e " .. vim.fn.fnameescape(cpp))
    -- 已存在同名"同参数"实现才只跳转（比较参数串以区分重载；纯文本匹配避免 vim 正则问题）
    local prefix = cls .. "::" .. name
    local want_args = params:gsub("%s+", "")
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    for i, l in ipairs(lines) do
        local pos = l:find(prefix, 1, true)
        if pos then
            local argstr = l:sub(pos + #prefix):match("^%s*(%b())")
            if argstr and argstr:gsub("%s+", "") == want_args then
                vim.api.nvim_win_set_cursor(0, { i, 0 })
                vim.notify("实现已存在，已跳转", vim.log.levels.INFO)
                return
            end
        end
    end

    local impl = (ret ~= "" and (ret .. " ") or "")
        .. cls .. "::" .. name .. params .. (tail ~= "" and (" " .. tail) or "") .. " {\n\n}"
    local last = vim.api.nvim_buf_line_count(0)
    local new_lines = { "" }
    vim.list_extend(new_lines, vim.split(impl, "\n", { plain = true }))
    vim.api.nvim_buf_set_lines(0, last, last, false, new_lines)
    vim.api.nvim_win_set_cursor(0, { last + 3, 0 }) -- 光标落在 {} 内
end, { desc = "生成函数实现/静态成员定义到源文件" })

-- Markdown 折行开关（大表格时关掉看对齐）
map("n", "<leader>tw", function()
    vim.wo.wrap = not vim.wo.wrap
end, { desc = "切换折行" })

-- Markdown 自动生成目录 (TOC)
map("n", "<leader>tc", function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local toc = { "<!--toc:start-->", "" }
    for _, line in ipairs(lines) do
        local level, text = line:match("^(#+)%s+(.+)$")
        if level and #level <= 6 then
            local indent = string.rep("  ", #level - 1)
            -- GitHub 风格 anchor：小写、空格/标点转 -
            local anchor = text:lower()
                :gsub("[%p%c]", "-")
                :gsub("%s+", "-")
                :gsub("%-+", "-")
                :gsub("^%-", "")
                :gsub("%-$", "")
            table.insert(toc, indent .. "- [" .. text .. "](#" .. anchor .. ")")
        end
    end
    table.insert(toc, "")
    table.insert(toc, "<!--toc:end-->")
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, row, row, false, toc)
end, { desc = "生成 Markdown 目录 (TOC)" })

-- 原生终端(cmake 编译等弹出的终端)：<C-g> 退回 normal 模式，与 toggleterm 一致
map("t", "<C-g>", "<C-\\><C-n>", { desc = "终端退回 normal 模式" })
