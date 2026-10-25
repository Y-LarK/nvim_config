return {
    -- 浅色模式配色（gradient-theme 在 apply("light") 时 colorscheme gruvbox）。
    -- 只需进 runtimepath，无需 config；lazy=false 保证切换命令随时可用。
    "morhetz/gruvbox",
    cond = not vim.g.vscode,
    lazy = false,
}
