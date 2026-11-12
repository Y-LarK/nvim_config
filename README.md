# nvim_config

我的 Neovim 配置，基于 [lazy.nvim](https://github.com/folke/lazy.nvim) 管理插件。

需要 **Neovim 0.12+**（配置里用了 `vim.lsp.config` / `vim.lsp.enable` 与 0.12 的 RPC 接口）。

## 结构

```
├── init.lua                    # 入口：日志轮转 → leader → options → plugins → keymaps
├── lua/
│   ├── config/
│   │   ├── options.lua         # 基础选项、FileType 缩进/折行
│   │   ├── keymaps.lua         # 主键位（含 CMake、头文件切换、Doxygen 注释）
│   │   ├── keymaps_vscode.lua  # VS Code 内嵌 nvim 时的键位
│   │   ├── lsp_log_rotate.lua  # LSP 日志轮转（必须在最早期执行）
│   │   ├── blink_accept_fix.lua
│   │   ├── inline_bracket_guides.lua
│   │   ├── qt_include.lua
│   │   └── rainbow_level.lua
│   └── plugins/
│       ├── init.lua            # lazy.nvim 引导
│       ├── specs/              # 每个插件一个 spec 文件
│       └── local/              # 本地开发的插件（gradient-theme）
```

## 使用

```bash
git clone https://github.com/Y-LarK/nvim_config.git ~/.config/nvim
```

首次启动会自动安装 lazy.nvim 及其管理的插件；mason 会装 `lua_ls`、`marksman`、`yaml-language-server`。

**clangd 不走 mason**，用的是系统 `/usr/bin/clangd`（mason 的 22.1.0 在解析 `QObject::connect` 成员指针参数时会 segfault），需自行保证系统已安装。

## 主要插件

| 类别 | 插件 |
|------|------|
| 插件管理 | lazy.nvim |
| 补全 | blink.cmp（blink.lib + friendly-snippets） |
| LSP | nvim-lspconfig、mason、nvim-navic |
| 语法 | nvim-treesitter、rainbow-delimiters |
| 搜索 | telescope.nvim（fzf-native） |
| 文件树 | nvim-tree |
| UI | lualine、bufferline、noice、nvim-notify、which-key、alpha |
| 编辑 | nvim-autopairs、flash.nvim、neoscroll、nvim-surround、Comment |
| 代码导航 | aerial、trouble、nvim-ufo、indent-blankline |
| Git | gitsigns、neogit、diffview |
| 调试 | nvim-dap + dap-ui + dap-virtual-text（lldb-dap） |
| 构建 | cmake-tools |
| 格式化 | conform.nvim（clang-format / stylua / prettier / cmake_format） |
| Markdown | render-markdown、mdmath、img-clip、obsidian-image |
| 其他 | todo-comments、spectre、toggleterm、undotree、smear-cursor、vim-log-highlighting |
| 主题 | 深色自绘（gradient-theme）、浅色 gruvbox |

## 键位

`<leader>` = `Space`

### 文件与窗口

| 键位 | 功能 |
|------|------|
| `<leader>w` / `<leader>q` / `<leader>Q` | 保存 / 退出 / 强制退出全部 |
| `<leader>e` | 切换文件树 |
| `<leader>sv` / `<leader>sh` | 左右 / 上下分屏 |
| `<C-h/j/k/l>` | 窗口间移动 |
| `<A-,>` / `<A-.>` | 上 / 下一个标签（`Alt+h/l` 被 niri 的 Mod+H/L 占用） |
| `<leader>bc` | 关闭当前 Buffer |
| `jk` / `kj` | 退出插入模式 |
| `H` / `L` | 行首 / 行尾（覆盖原生视口跳转） |

### 搜索

| 键位 | 功能 |
|------|------|
| `<leader>ff` | 查找文件 |
| `<leader>fw` | 全局搜索文本 |
| `<leader>fb` | 已打开缓冲区 |
| `<leader>fh` | 帮助文档 |
| `<leader>fs` | 当前文件符号 |
| `<leader>ft` | 查找 TODO |
| `<leader>sr` | 全局搜索替换 |
| `<leader>nh` | 取消搜索高亮 |
| `s` / `S` / `R` / `r` | Flash 跳转 / Treesitter 选中 / Treesitter 搜索 / remote |

### LSP 与代码

| 键位 | 功能 |
|------|------|
| `K` | 悬浮文档 |
| `gd` | 第一次跳声明（.h），再按一次跳定义（.c/.cpp） |
| `gr` | 查看引用 |
| `gi` | 跳转到实现（虚函数的所有重写） |
| `<leader>ca` | 代码操作 |
| `<leader>lk` | 函数签名 |
| `<leader>dc` | 生成 Doxygen 注释 |
| `<leader>/` | 行注释（Visual 下为块注释） |
| `<leader>ha` | 头文件 ↔ 源文件（含 .tpp/.ipp 模板实现） |
| `<leader>hi` | 由头文件声明生成源文件实现 / 静态成员定义 |

### CMake 与调试

| 键位 | 功能 |
|------|------|
| `<leader>cg` | CMake 生成 |
| `<leader>cb` | 构建 |
| `<leader>cr` | 运行 |
| `<leader>cd` | 调试 |
| `<leader>ct` | 选择构建目标 |
| `<leader>cc` | 清理构建缓存 |
| `<leader>cX` | 删除 build 目录 |
| `<leader>ck` | 停止当前任务 |
| `<leader>cR` / `<leader>cD` | 切换 Release / Debug 并生成 |
| `F9` | 切换断点 |
| `F5` / `F10` / `F11` / `F12` / `F4` | 继续 / 单步跳过 / 单步进入 / 单步跳出 / 终止 |

### Git

| 键位 | 功能 |
|------|------|
| `<leader>gg` | Neogit 状态面板 |
| `<leader>gv` / `<leader>gh` / `<leader>gH` | 当前修改 / 文件历史 / 当前文件历史 |
| `]h` / `[h` | 下一处 / 上一处改动 |
| `<leader>hs` / `<leader>hr` | 暂存 / 撤销当前块（Visual 下为选中块） |
| `<leader>hS` | 暂存整个 Buffer |
| `<leader>hb` / `<leader>hp` | 行 Blame / 内联预览改动 |

### 面板、终端与 Markdown

| 键位 | 功能 |
|------|------|
| `<leader>to` | 切换大纲（aerial） |
| `<leader>xx` | 诊断列表（trouble） |
| `<leader>uu` | 撤销树 |
| `<C-\>` | 浮动终端 |
| `<C-g>` | 终端退回 normal 模式 |
| `<leader>mj` | 跳转 Markdown 锚点 / 打开链接 |
| `<leader>tw` / `<leader>tc` | 切换折行 / 生成目录 |
| `<M-e>` | autopairs 快速包裹 |

平滑滚动：`<C-u>/<C-d>/<C-b>/<C-f>` 翻页，`zt/zz/zb` 对齐。

按 `<leader>` 等待 300ms 可查看 which-key 完整键位提示。
