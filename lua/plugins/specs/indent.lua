return {
  {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPost", "BufNewFile" },
    main = "ibl", -- 新版本需要指定入口
    dependencies = { "nvim-treesitter/nvim-treesitter" }, -- 必须依赖 TS
    opts = {
      -- 1. 缩进线基础配置
      indent = {
        char = "│", -- 连线字符，也可以用 "╎" 或 "┆"
        tab_char = "│",
      },
      -- 2. 核心：括号作用域连线 (Scope)
      scope = {
        enabled = true,
        show_start = true, -- 是否在作用域开始处显示小横线
        show_end = false,
        injected_languages = true,
        highlight = { "RainbowDelimiterViolet" }, -- 连线颜色：建议关联你的彩虹色
        priority = 500,
      },
      -- 3. 排除规则
      exclude = {
        filetypes = {
          "help",
          "dashboard",
          "lazy",
          "mason",
          "notify",
          "toggleterm",
        },
      },
    },
    config = function(_, opts)
      require("ibl").setup(opts)
    end,
  },
}
