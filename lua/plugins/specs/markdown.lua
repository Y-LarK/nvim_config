return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      render_modes = { "n" },
      file_types = { "markdown" },
      heading = {
        enabled = true,
        icons = { " 1 ", " 2 ", " 3 ", " 4 ", " 5 ", " 6 " },
      },
      code = {
        enabled = true,
        sign = false,
        width = "block",
        right_pad = 1,
      },
      bullet = {
        enabled = true,
        icons = { "●", "○", "◆", "◇" },
      },
      checkbox = {
        enabled = true,
        unchecked = { icon = "󰄱 " },
        checked = { icon = "󰱒 " },
      },
    },
  },
}
