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
require("config.keymaps")
require("plugins")
