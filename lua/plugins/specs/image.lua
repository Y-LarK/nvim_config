return {
    {
        "Y-LarK/obsidian-image-nvim",
        name = "image.nvim",
        lazy = false,
        pin = true,
        build = false,
        rocks = { "image.nvim", "magick" },
        opts = {
            backend = "kitty",
            processor = "magick_cli",
            integrations = {
                markdown = {
                    enabled = true,
                    clear_in_insert_mode = false,
                    download_remote_images = true,
                    only_render_image_at_cursor = false,
                    filetypes = { "markdown", "vimwiki" },
                },
            },
            max_width_window_percentage = 100,
            max_height_window_percentage = 80,
        },
    },
}
