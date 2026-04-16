-- 1. 自动下载 (Bootstrap) - 保持不变
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 2. 配置 lazy.nvim
require("lazy").setup({
  spec = {
    -- 这样 lazy 会自动加载 lua/plugins/specs/ 目录下的所有 lua 文件
    { import = "plugins.specs" },
  },
  
  -- 基础设置
  defaults = { lazy = true }, -- 默认所有插件懒加载
  ui = { border = "rounded" },
  checker = { enabled = true, notify = false },
})
