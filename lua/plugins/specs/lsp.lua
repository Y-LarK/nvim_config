return {
    {
        "neovim/nvim-lspconfig",
        cond = not vim.g.vscode,
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "hrsh7th/cmp-nvim-lsp",
            "SmiteshP/nvim-navic",
        },
        config = function()
            local capabilities = require("blink.cmp").get_lsp_capabilities()
            local lspconfig = require("lspconfig")
            local root_pattern = require("lspconfig.util").root_pattern
            local ok_navic, navic = pcall(require, "nvim-navic")

            if ok_navic then
                navic.setup({
                    highlight = false,
                    separator = " > ",
                    depth_limit = 5,
                })
            end

            -- 定位编译数据库目录：
            --   1) 优先用 cmake-tools 的（它知道当前构建类型）
            --   2) 无效时从当前文件所在目录逐级向上搜索 build 下的常见位置
            -- 关键：必须在 cmd 函数（进程启动前）里求值 —— before_init 太晚，
            -- LSP 进程已经 spawn，那时改 cmd 不会生效。
            local function resolve_compile_commands_dir()
                local ok_cmake, cmake = pcall(require, "cmake-tools")
                if ok_cmake then
                    local probe = { cmd = {} }
                    if pcall(cmake.clangd_on_new_config, probe) then
                        for _, arg in ipairs(probe.cmd) do
                            local d = arg:match("^%-%-compile%-commands%-dir=(.+)$")
                            if d and vim.fn.isdirectory(d) == 1 then
                                return d
                            end
                        end
                    end
                end

                local suffixes = {
                    "/build/*/compile_commands.json",
                    "/build/*/.qtc_clangd/compile_commands.json",
                    "/build/compile_commands.json",
                }
                local file = vim.api.nvim_buf_get_name(0)
                local dir = vim.fn.fnamemodify(file ~= "" and file or vim.fn.getcwd(), ":p:h")
                while dir ~= "" and dir ~= "/" do
                    for _, suffix in ipairs(suffixes) do
                        for _, found in ipairs(vim.fn.glob(dir .. suffix, false, true)) do
                            return vim.fn.fnamemodify(found, ":h")
                        end
                    end
                    local parent = vim.fn.fnamemodify(dir, ":h")
                    if parent == dir then break end
                    dir = parent
                end
                return nil
            end

            local servers = {
                clangd = {
                    -- cmd 用函数形式：进程启动前求值，才能按当前文件定位编译数据库。
                    -- 注意 nvim 0.12 要求返回 rpc 对象（不是 cmd 数组），故用 vim.lsp.rpc.start
                    cmd = function(dispatchers, config)
                        local c
                        if os.getenv("CLANGD_REMOTE") == "1" then
                            local port = os.getenv("CLANGD_PORT") or "9527"
                            c = { "socat", "-", "TCP:localhost:" .. port }
                        else
                            c = {
                                "clangd",
                                "--background-index",
                                "--clang-tidy",
                                "--header-insertion=iwyu",
                                "--completion-style=detailed",
                                "--function-arg-placeholders=1",
                            }
                        end
                        local dir = resolve_compile_commands_dir()
                        if dir then
                            table.insert(c, "--compile-commands-dir=" .. dir)
                        end
                        return vim.lsp.rpc.start(c, dispatchers)
                    end,
                    root_markers = { "CMakeLists.txt", "compile_commands.json", ".git", ".clangd" },
                },

                lua_ls = {
                    settings = {
                        Lua = {
                            diagnostics = {
                                globals = { "vim" },
                            },
                            workspace = {
                                checkThirdParty = false,
                                library = vim.api.nvim_get_runtime_file("", true),
                            },
                            telemetry = { enable = false },
                        },
                    },
                },

                marksman = {
                    filetypes = { "markdown" },
                },

                yamlls = {
                    settings = {
                        yaml = {
                            validate = true,
                            hover = true,
                            completion = true,
                            format = { enable = true },
                            schemas = {
                                ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
                                ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] =
                                "docker-compose*.yml",
                            },
                        },
                    },
                },
            }

            if vim.fn.executable("cmake-language-server") == 1 then
                servers.cmake = {
                    cmd = { "cmake-language-server" },
                    filetypes = { "cmake" },
                    root_dir = root_pattern("CMakeLists.txt", "CMakePresets.json"),
                }
            end

            for server, config in pairs(servers) do
                config.capabilities = capabilities

                if vim.lsp.config and vim.lsp.enable then
                    if config.on_new_config then
                        local orig_on_new_config = config.on_new_config
                        config.before_init = function(params, init_config)
                            local fake_config = init_config
                            local cwd = params.rootPath or vim.fn.getcwd()
                            orig_on_new_config(fake_config, cwd)
                        end
                        config.on_new_config = nil
                    end
                    vim.lsp.config(server, config)
                    vim.lsp.enable(server)
                else
                    lspconfig[server].setup(config)
                end
            end

            -- navic attach
            if ok_navic then
                vim.api.nvim_create_autocmd("LspAttach", {
                    group = vim.api.nvim_create_augroup("UserNavicAttach", { clear = true }),
                    callback = function(args)
                        local client = vim.lsp.get_client_by_id(args.data.client_id)
                        if client and client.server_capabilities.documentSymbolProvider then
                            navic.attach(client, args.buf)
                        end
                    end,
                })
            end

            -- 内联提示（参数名、类型推断）
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("UserInlayHints", { clear = true }),
                callback = function(args)
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if client and client.server_capabilities.inlayHintProvider then
                        vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
                    end
                end,
            })

            -- clang-tidy 的“未使用”诊断默认不带 Unnecessary 标记，这里补上，
            -- 让它套用 DiagnosticUnnecessary 高亮（默认 link Comment），与编译器 unused 提示视觉统一
            local orig_publish_diagnostics = vim.lsp.handlers["textDocument/publishDiagnostics"]
            vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
                if result and result.diagnostics then
                    for _, d in ipairs(result.diagnostics) do
                        if d.source == "clang-tidy" and d.message:match("^[Uu]nused ") then
                            d.tags = d.tags or {}
                            if not vim.tbl_contains(d.tags, 1) then
                                table.insert(d.tags, 1) -- 1 = DiagnosticTag.Unnecessary
                            end
                        end
                    end
                end
                return orig_publish_diagnostics(err, result, ctx, config)
            end

            -- 诊断配置
            vim.diagnostic.config({
                virtual_text = { prefix = "●" },
                severity_sort = true,
                float = { border = "rounded" },
            })

            -- 光标停留自动显示 hover（类似 VSCode）
            vim.o.updatetime = 800

            vim.api.nvim_create_autocmd("CursorHold", {
                group = vim.api.nvim_create_augroup("UserLspHover", { clear = true }),
                callback = function()
                    -- hover 浮窗的 filetype 是 markdown，已打开则跳过避免重复
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        local cfg = vim.api.nvim_win_get_config(win)
                        if cfg.relative ~= "" then
                            local buf = vim.api.nvim_win_get_buf(win)
                            if vim.bo[buf].filetype == "markdown" then
                                return
                            end
                        end
                    end
                    local clients = vim.lsp.get_clients({ bufnr = 0 })
                    if #clients == 0 then return end
                    -- nvim 0.12 的 make_position_params 要求 position_encoding 非 nil，
                    -- 否则告警；部分 client 的 offset_encoding 可能为空，故加回退链
                    local client = clients[1]
                    local cur_win = vim.api.nvim_get_current_win()
                    local enc = client.offset_encoding
                        or (client.server_capabilities and client.server_capabilities.positionEncoding)
                        or "utf-16"
                    local params = vim.lsp.util.make_position_params(cur_win, enc)
                    client:request("textDocument/hover", params, function(err, result)
                        if err or not result or not result.contents then
                            return -- 没有内容时静默，不弹通知
                        end
                        vim.lsp.handlers.hover(err, result, { client_id = client.id }, {})
                    end)
                end,
            })
        end,
    },
}
