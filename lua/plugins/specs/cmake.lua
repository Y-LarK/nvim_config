return {
    "Civitasv/cmake-tools.nvim",
    lazy = false,
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
        cmake_command = "cmake",         -- cmake 可执行路径
        ctest_command = "ctest",         -- ctest 可执行路径
        cmake_regenerate_on_save = true, -- 保存 CMakeLists.txt 时自动重新生成
        cmake_generate_options = {       -- cmake 生成时附加参数
            "-DCMAKE_EXPORT_COMPILE_COMMANDS=1",
        },
        cmake_build_options = {},          -- cmake --build 时附加参数
        cmake_build_directory = function() -- 构建目录（可写死或动态生成）
            local osys = require("cmake-tools.osys")
            if osys.iswin32 then
                return "out\\${variant:buildType}"
            end
            return "out/${variant:buildType}"
        end,
        cmake_soft_link_compile_commands = false, -- 软链 compile_commands.json 到项目根
        cmake_compile_commands_from_lsp = true,   -- 由 LSP on_new_config 管理时设为 true
        cmake_kits_path = nil,                    -- cmake-kits.json 路径，nil 使用全局默认
        cmake_variants_message = {
            short = { show = true },              -- 状态栏显示短名
            long  = { show = true, max_length = 40 },
        },

        -- ── 执行器（构建输出窗口） ──────────────────────────────────────
        cmake_executor = {
            name = "terminal", -- "terminal" | "quickfix" | "overseer"
            opts = {},
            default_opts = {
                quickfix = {
                    show                    = "always",     -- "always" | "only_on_error"
                    position                = "belowright", -- 窗口位置
                    size                    = 10,
                    encoding                = "utf-8",
                    auto_close_when_success = true,
                },
                toggleterm = {
                    direction     = "float", -- "float" | "horizontal" | "vertical" | "tab"
                    close_on_exit = false,
                    auto_scroll   = true,
                },
                overseer = {
                    new_task_opts = { strategy = { "toggleterm" } },
                    on_new_task = function(task) end,
                },
                terminal = {
                    name                          = "Main Terminal",
                    prefix_name                   = "[CMakeTools]: ",
                    split_direction               = "horizontal",
                    split_size                    = 11,
                    single_terminal_per_instance  = true,
                    single_terminal_per_tab       = true,
                    keep_terminal_static_location = true,
                    auto_resize                   = true,
                    start_insert                  = false,
                    focus                         = false,
                    do_not_add_newline            = false,
                },
            },
        },

        -- ── 运行器（运行可执行目标） ────────────────────────────────────
        cmake_runner = {
            name = "terminal",
            opts = {},
            default_opts = {
                -- 同 cmake_executor 的 default_opts
            },
        },

        -- ── 通知样式 ────────────────────────────────────────────────────
        cmake_notifications = {
            runner = { enabled = true },
            executor = { enabled = true },
            spinner = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" },
            refresh_rate_ms = 100,
        },
    },
}
