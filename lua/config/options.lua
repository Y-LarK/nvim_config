local opt          = vim.opt

vim.o.winborder    = "rounded"
-- 系统剪贴板
opt.clipboard      = "unnamedplus"

-- 行号
opt.number         = true
opt.relativenumber = true

-- 缩进
opt.tabstop        = 4
opt.shiftwidth     = 4
opt.expandtab      = true
opt.smartindent    = true

-- 搜索
opt.ignorecase     = true
opt.smartcase      = true
opt.hlsearch       = false
opt.incsearch      = true

-- 文件
opt.encoding       = "utf-8"
opt.fileencoding   = "utf-8"
opt.undofile       = true
opt.swapfile       = false
opt.backup         = false

-- 性能
opt.updatetime     = 250
opt.timeoutlen     = 300
opt.termguicolors  = true
opt.cursorline     = true -- 必须开启，CursorLineNr 才会生效

vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function()
        local opt_local = vim.opt_local
        opt_local.wrap = true
        opt_local.linebreak = true
        opt_local.breakindent = true
        opt_local.spell = true
        opt_local.spelllang = { "en_us", "cjk" }
        opt_local.textwidth = 0
        opt_local.colorcolumn = ""
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "yaml",
    callback = function()
        vim.opt_local.expandtab = true
        vim.opt_local.shiftwidth = 2
        vim.opt_local.tabstop = 2
        vim.opt_local.softtabstop = 2
    end,
})
opt.guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50"
