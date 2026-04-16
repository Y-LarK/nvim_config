return {
  "windwp/nvim-autopairs",
  event = "InsertEnter", -- 仅在进入插入模式时加载，极致性能
  dependencies = { "hrsh7th/nvim-cmp" }, -- 配合补全插件实现回车确认
  opts = {
    check_ts = true, -- 开启 Treesitter 支持
    ts_config = {
      lua = { "string" }, -- lua 字符串内不补全
      javascript = { "template_string" },
      cpp = { "string", "comment" }, -- C++ 的字符串和注释里不补全
    },
    disable_filetype = { "TelescopePrompt", "spectre_panel" },
    fast_wrap = {
      map = "<M-e>", -- 快捷键 Alt+e，可以将括号快速包裹住后面的词
    },
  },
  config = function(_, opts)
    local autopairs = require("nvim-autopairs")
    autopairs.setup(opts)

    -- 核心逻辑：当你按回车选中补全项时，自动加上括号
    local cmp_autopairs = require("nvim-autopairs.completion.cmp")
    local cmp = require("cmp")
    cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
  end,
}
