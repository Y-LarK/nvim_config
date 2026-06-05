local map = vim.keymap.set
local vscode = require("vscode")
local call = vscode.call
local action = vscode.action

-- ===== 基础编辑 =====
map("i", "jk", "<ESC>", { desc = "退出插入模式" })
map("i", "kj", "<ESC>", { desc = "退出插入模式" })
map({ "n", "x" }, "H", "^", { desc = "行首" })
map({ "n", "x" }, "L", "$", { desc = "行尾" })
map("n", "<leader>nh", "<cmd>nohl<CR>", { desc = "取消高亮" })

-- ===== 跳转（二选一：flash 或 jumpy2）=====
-- 如果用 flash.nvim:
map({ "n", "x", "o" }, "s", function() require("flash").jump() end, { desc = "Flash 跳转" })
-- 如果用 jumpy2，在 keybindings.json 里配置，这里不需要

-- ===== 窗口跳转 =====
map("n", "<C-h>", function() action("workbench.action.navigateLeft") end)
map("n", "<C-l>", function() action("workbench.action.navigateRight") end)
map("n", "<C-k>", function() action("workbench.action.navigateUp") end)
map("n", "<C-j>", function() action("workbench.action.navigateDown") end)

-- ===== 标签页 =====
map("n", "<A-h>", function() action("workbench.action.previousEditorInGroup") end, { desc = "上一个标签" })
map("n", "<A-l>", function() action("workbench.action.nextEditorInGroup") end, { desc = "下一个标签" })
map("n", "<leader>bc", function() action("workbench.action.closeActiveEditor") end, { desc = "关闭标签" })

-- ===== 文件/搜索 =====
map("n", "<leader>ff", function() action("workbench.action.quickOpen") end, { desc = "查找文件" })
map("n", "<leader>fw", function() action("workbench.action.findInFiles") end, { desc = "全局搜索" })
map("n", "<leader>fb", function() action("workbench.action.showAllEditors") end, { desc = "已打开文件" })
map("n", "<leader>fs", function() action("workbench.action.gotoSymbol") end, { desc = "文件符号" })

-- ===== 文件树 =====
map("n", "<leader>e", function() action("workbench.action.toggleSidebarVisibility") end, { desc = "切换侧边栏" })

-- ===== LSP（同步调用，跳转更可靠）=====
map("n", "gd", function() call("editor.action.revealDefinition") end, { desc = "跳转定义" })
map("n", "gr", function() call("editor.action.goToReferences") end, { desc = "查看引用" })
map("n", "gi", function() call("editor.action.goToImplementation") end, { desc = "跳转实现" })
map("n", "K", function() action("editor.action.showHover") end, { desc = "悬浮文档" })
map("n", "<leader>rn", function() action("editor.action.rename") end, { desc = "重命名" })
map("n", "<leader>ca", function() action("editor.action.quickFix") end, { desc = "代码操作" })

-- ===== 保存/关闭 =====
map("n", "<leader>w", function() call("workbench.action.files.save") end, { desc = "保存" })
map("n", "<leader>q", function() action("workbench.action.closeActiveEditor") end, { desc = "关闭" })
