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

-- 快速窗口跳转
map("n", "<C-h>", "<C-w>h", { desc = "跳转到左侧窗口" })
map("n", "<C-j>", "<C-w>j", { desc = "跳转到底部窗口" }) -- 这一行就是你要的
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
map("n", "<leader>ck", "<cmd>CMakeStop<cr>", { desc = "停止当前任务" })
