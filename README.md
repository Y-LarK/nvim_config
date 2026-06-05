# nvim_config

我的 Neovim 配置，基于 [lazy.nvim](https://github.com/folke/lazy.nvim) 管理插件。

## 结构

```
├── init.lua              # 入口
├── lua/
│   ├── config/           # 基础配置（options、keymaps）
│   └── plugins/          # 插件管理
│       └── specs/        # 各插件独立配置
```

## 使用

```bash
git clone https://github.com/Y-LarK/nvim_config.git ~/.config/nvim
```

首次启动会自动安装 lazy.nvim 及所有插件。

## 主要插件

| 类别 | 插件 |
|------|------|
| 补全 | nvim-cmp + LuaSnip + LSP |
| 语法 | nvim-treesitter |
| 搜索 | telescope.nvim |
| UI | lualine、bufferline、noice、which-key |
| 编辑 | nvim-autopairs、flash.nvim、neoscroll |
| LSP | nvim-lspconfig + mason |

## 键位

`<leader>` = `Space`

- `<leader>ff` — 查找文件
- `<leader>fw` — 全局搜索
- `<leader>e`  — 文件树
- `gd` / `gr` — LSP 跳转定义 / 引用
- `K` — 悬浮文档
- `<C-h/j/k/l>` — 窗口间移动

按 `<leader>` 等待 300ms 可查看 which-key 完整键位提示。
