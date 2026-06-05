-- 设置 Leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- 开启文件类型检测、插件和缩进
vim.cmd([[
  filetype plugin indent on
  syntax enable
]])

-- 额外的 C++ 文件类型映射
vim.filetype.add({
    extension = {
        cc = "cpp",
        cxx = "cpp",
        hpp = "cpp",
        hxx = "cpp",
    },
})

require("config.options")

if vim.g.vscode then
    require("plugins")
    require("config.keymaps_vscode")
    vim.opt.cmdheight = 100000    -- 消息行数不超过这个值就不弹出
    vim.opt.shortmess:append("q")
    vim.opt.shortmess:append("s") -- 静默搜索消息
    vim.opt.shortmess:append("S") -- 不显示搜索计数
    vim.opt.shortmess:append("qsSF")
else
    require("plugins")
    require("config.keymaps")
    require("config.options")
end
