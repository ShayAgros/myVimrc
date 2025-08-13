return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
        bigfile = { enabled = false },
        dashboard = { enabled = true },
        indent = { enabled = true },
        input = { enabled = true },
        notifier = { enabled = true },
        quickfile = { enabled = true },
        scroll = { enabled = true },
        statuscolumn = { enabled = true },
        words = { enabled = true },
        picker = {
            enabled = true,
            -- layout = {
            --     backdrop = false,
            --     row = 1,
            --     width = 0.4,
            --     min_width = 80,
            --     height = 0.8,
            --     border = "none",
            --     box = "vertical",
            --     { win = "preview", title = "{preview}", height = 0.4, border = "rounded" },
            --     {
            --         box = "vertical",
            --         border = "rounded",
            --         title = "{title} {live} {flags}",
            --         title_pos = "center",
            --         { win = "input", height = 1,     border = "bottom" },
            --         { win = "list",  border = "none" },
            --     },
            -- },
        },
    }
}
