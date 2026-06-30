-- Default Keybindings:
-- Normal mode:
--   <leader>ac  - Toggle Claude Code terminal
--   <leader>cC  - Open Claude Code with --continue flag
--   <leader>cV  - Open Claude Code with --verbose flag
--   <leader>cs  - Send visual selection to Claude Code (visual mode)
--   <leader>cab - Send all open buffers context to Claude Code
--   <leader>cb  - Send current buffer to Claude Code
-- Terminal mode:
--   <leader>ac  - Toggle Claude Code terminal
--   <C-h/j/k/l> - Navigate between windows
--   <C-f/b>     - Scroll page down/up
--   <Esc><Esc>  - Enter normal mode
--   #           - Open file picker
--   <leader>cb  - Send current buffer to Claude Code

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
            command = "claude",
            command_variants = {
                resume = "--continue",
                verbose = "--verbose",
                review = "--agent code-reviewer-shayagr --dangerously-skip-permissions --disallowed-tools Edit Write",
            },
            window = {
                position = "botright vertical",
                split_ratio = 0.4,
            },
            keymaps = {
                toggle = {
                    normal = "<leader>ac", -- Normal mode keymap for toggling Claude Code, false to disable
                    terminal = "<leader>ac", -- Terminal mode keymap for toggling Claude Code, false to disable
                    variants = {
                        continue = "<leader>cC", -- Normal mode keymap for Claude Code with continue flag
                        verbose = "<leader>cV", -- Normal mode keymap for Claude Code with verbose flag
                        review = "<leader>cr", -- Normal mode keymap for Claude Code with code-reviewer agent
                    },
                },
                window_navigation = true, -- Enable window navigation keymaps (<C-h/j/k/l>)
                scrolling = true, -- Enable scrolling keymaps (<C-f/b>) for page up/down
                file_picker = "#", -- Terminal mode keymap for file picker (false to disable)
                send_selection = "<leader>cs", -- Visual mode keymap for sending selection to Claude Code (false to disable)
                send_buffers = "<leader>cab", -- Normal mode keymap for sending all open buffers context (false to disable)
                send_alternate = "<leader>cb", -- Normal/Terminal mode keymap for sending current buffer (false to disable)
            },
        })
    end,
}
