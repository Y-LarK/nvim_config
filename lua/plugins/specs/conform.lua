return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  opts = {
    formatters_by_ft = {
      -- C/C++
      cpp = { "clang-format" },
      c = { "clang-format" },
      -- Lua (Neovim 配置的核心)
      lua = { "stylua" },
      -- Python (如果你以后用到)
      python = { "isort", "black" },
      -- Web 相关 (JSON, Markdown, YAML)
      json = { "prettier" },
      markdown = { "prettier" },
      yaml = { "prettier" },
      -- CMake (C++ 项目必备)
      cmake = { "cmake_format" },
      -- 兜底：对所有未定义的类型尝试 LSP 格式化
      ["_"] = { "trim_whitespace" },
    },
    format_on_save = {
      timeout_ms = 500,
      lsp_fallback = true,
    },
  },
}
