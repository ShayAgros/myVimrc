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
        },
    },
    config = function(_, opts)
        -- Setup with the opts (lazy.nvim passes opts as second parameter)
        require("snacks").setup(opts)

        -- Create the Notifications command
        vim.api.nvim_create_user_command('Notifications', function()
            Snacks.notifier.show_history()
        end, {
                desc = "Show notification history"
            })

        vim.keymap.set("n", "<leader>nh", function()
            Snacks.notifier.show_history()
        end, { desc = "Show notification history" })
    end
}
