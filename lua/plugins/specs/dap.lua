return {
    {
        "mfussenegger/nvim-dap",
        lazy = false,
        dependencies = {
            "rcarriga/nvim-dap-ui",
            "nvim-neotest/nvim-nio",
            "theHamsta/nvim-dap-virtual-text",
        },
        config = function()
            local dap = require("dap")
            local dapui = require("dapui")

            -- lldb 适配器
            dap.adapters.lldb = {
                type = "executable",
                command = "/usr/bin/lldb-dap",
                name = "lldb",
            }

            -- 手动调试用的兜底配置（cmake-tools 的 CMakeDebug 会自己构建配置并覆盖 program）
            local fallback = {
                name = "Launch (手动)",
                type = "lldb",
                request = "launch",
                program = function()
                    return vim.fn.input(
                        "可执行文件路径: ",
                        vim.fn.getcwd() .. "/build/",
                        "file"
                    )
                end,
                cwd = "${workspaceFolder}",
                stopOnEntry = false,
                args = {},
            }
            dap.configurations.c = { fallback }
            dap.configurations.cpp = { fallback }

            -- UI
            dapui.setup()
            require("nvim-dap-virtual-text").setup({
                enabled = true,
                highlight_changed_variables = true,      -- 高亮刚变化的变量
                highlight_new_as_changed = true,         -- 新增作用域的变量也高亮
                commented = true,                        -- 用注释语法，不干扰代码颜色
                only_first_definition = true,            -- 只显示第一个定义
                all_references = false,                  -- 不显示所有引用
            })

            dap.listeners.after.event_initialized["dapui_config"] = function()
                dapui.open()
            end
            dap.listeners.before.event_terminated["dapui_config"] = function()
                dapui.close()
            end
            dap.listeners.before.event_exited["dapui_config"] = function()
                dapui.close()
            end

            -- 快捷键
            vim.keymap.set("n", "<F9>", dap.toggle_breakpoint, { desc = "切换断点" })
            vim.keymap.set("n", "<F5>", dap.continue, { desc = "继续" })
            vim.keymap.set("n", "<F10>", dap.step_over, { desc = "单步跳过" })
            vim.keymap.set("n", "<F11>", dap.step_into, { desc = "单步进入" })
            vim.keymap.set("n", "<F12>", dap.step_out, { desc = "单步跳出" })
            vim.keymap.set("n", "<F4>", dap.terminate, { desc = "终止调试" })
        end,
    },
}
