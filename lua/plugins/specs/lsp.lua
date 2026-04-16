return {
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "hrsh7th/cmp-nvim-lsp",
            "SmiteshP/nvim-navic",
        },
        config = function()
            local capabilities = require("cmp_nvim_lsp").default_capabilities()
            local lspconfig = require("lspconfig")
            local root_pattern = require("lspconfig.util").root_pattern
            local ok_navic, navic = pcall(require, "nvim-navic")

            if ok_navic then
                navic.setup({
                    highlight = true,
                    separator = " > ",
                    depth_limit = 5,
                })
            end

            -- ── clangd 专用：从 cmake-tools 获取编译数据库路径 ──────────────
            local function clangd_on_new_config(new_config, new_cwd)
                local ok_cmake, cmake = pcall(require, "cmake-tools")
                if ok_cmake then
                    cmake.clangd_on_new_config(new_config)
                end
            end

            local servers = {
                clangd = {
                    cmd = {
                        "clangd",
                        "--background-index",
                        "--clang-tidy",
                        "--header-insertion=iwyu",
                        "--completion-style=detailed",
                        "--function-arg-placeholders=1",
                    },
                    -- cmake-tools 会动态修改 compilationDatabasePath
                    -- 通过 on_new_config 注入，这里保留一个合理的静态后备值
                    init_options = {
                        compilationDatabasePath = "build",
                    },
                    on_new_config = clangd_on_new_config,
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
                    -- Neovim 0.11+ 原生 LSP 路径
                    -- on_new_config 是 lspconfig 的概念，原生路径需改用 before_init
                    if config.on_new_config then
                        local orig_on_new_config = config.on_new_config
                        -- 转换为原生 LSP 的 before_init 钩子
                        config.before_init = function(params, init_config)
                            -- 构造一个兼容 lspconfig on_new_config 签名的临时对象
                            local fake_config = init_config
                            local cwd = params.rootPath or vim.fn.getcwd()
                            orig_on_new_config(fake_config, cwd)
                        end
                        config.on_new_config = nil -- 原生路径不识别此字段
                    end
                    vim.lsp.config(server, config)
                    vim.lsp.enable(server)
                else
                    -- lspconfig 路径（Neovim < 0.11）
                    lspconfig[server].setup(config)
                end
            end

            -- ── navic 自动挂载 ────────────────────────────────────────────
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

            -- ── 诊断样式 ──────────────────────────────────────────────────
            vim.diagnostic.config({
                virtual_text = { prefix = "●" },
                severity_sort = true,
                float = { border = "rounded" },
            })
        end,
    },
}
