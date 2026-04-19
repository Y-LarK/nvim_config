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

            local function clangd_on_new_config(new_config, new_cwd)
                local ok_cmake, cmake = pcall(require, "cmake-tools")
                if ok_cmake then
                    cmake.clangd_on_new_config(new_config)
                end
            end

            local servers = {
                clangd = {
                    cmd = (function()
                        if os.getenv("CLANGD_REMOTE") == "1" then
                            local port = os.getenv("CLANGD_PORT") or "9527"
                            return { "socat", "-", "TCP:localhost:" .. port }
                        end
                        return {
                            "clangd",
                            "--background-index",
                            "--clang-tidy",
                            "--header-insertion=iwyu",
                            "--completion-style=detailed",
                            "--function-arg-placeholders=1",
                        }
                    end)(),
                    root_markers = { ".clangd", "compile_commands.json", "CMakeLists.txt", ".git" },
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

            vim.diagnostic.config({
                virtual_text = { prefix = "●" },
                severity_sort = true,
                float = { border = "rounded" },
            })
        end,
    },
}
