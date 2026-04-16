return {
    {
        "nvim-telescope/telescope.nvim",
        -- tag = "0.1.8",  ← 移除，使用最新版
        branch = "0.1.x", -- 跟踪 0.1 稳定分支，不用 master 的激进更新
        cmd = "Telescope",
        dependencies = {
            "nvim-lua/plenary.nvim",
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
        },
        config = function()
            local telescope = require("telescope")
            telescope.setup({
                defaults = {
                    layout_strategy = "horizontal",
                    layout_config = {
                        horizontal = { preview_width = 0.55 },
                        width = 0.9,
                    },
                    file_ignore_patterns = { "node_modules", ".git/", "build/", "dist/" },
                    prompt_prefix = "   ",
                    selection_caret = "  ",
                    -- 修复 Neovim 0.11+ treesitter 预览兼容性
                    preview = {
                        treesitter = true,
                    },
                },
            })
            pcall(telescope.load_extension, "fzf")
        end,
    },
}
