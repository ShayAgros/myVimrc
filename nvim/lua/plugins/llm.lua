return {
    name = "kiro-cli-nvim",
    url = "ssh://git.amazon.com/pkg/KiroCliNvim",
    dependencies = {
        "nvim-lua/plenary.nvim", -- Required for git operations
    },
    enabled = function()
        return not vim.g.g_disable_amazon_plugins
    end,
    config = function()
        require("claude-code").setup({
            command = "kiro-cli chat",
            command_variants = {
                resume = "--resume",
                verbose = "--verbose",
            },
            window = {
                position = "vertical",
                split_ratio = 0.4,
            },
            keymaps = {
                toggle = {
                    normal = "<leader>ac", -- Normal mode keymap for toggling Claude Code, false to disable
                    terminal = "<leader>ac", -- Terminal mode keymap for toggling Claude Code, false to disable
                    variants = {
                        continue = "<leader>cC", -- Normal mode keymap for Claude Code with continue flag
                        verbose = "<leader>cV", -- Normal mode keymap for Claude Code with verbose flag
                    },
                },
                window_navigation = true, -- Enable window navigation keymaps (<C-h/j/k/l>)
                scrolling = true, -- Enable scrolling keymaps (<C-f/b>) for page up/down
            },
        })
    end,
}
