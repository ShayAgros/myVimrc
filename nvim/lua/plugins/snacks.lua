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
        indent = { enabled = true },
        input = { enabled = true },
        notifier = { enabled = true },
        quickfile = { enabled = true },
        scroll = { enabled = true },
        statuscolumn = { enabled = true },
        words = { enabled = true },
        picker = {
            enabled = true,
            sources = {
                files = {
                    format = require("formatters.snacks_formatters").Shayagr_format_brazil_ws,
                    preview = require("formatters.snacks_formatters").Shayagr_workspace_aware_file_preview
                },
                buffers = {
                    format = require("formatters.snacks_formatters").Shayagr_format_buffers_in_brazil_ws,
                    preview = require("formatters.snacks_formatters").Shayagr_workspace_aware_file_preview,
                    win = {
                        input = {
                            keys = {
                                ["<C-d>"] = { "bufdelete", mode = { "n", "i" } },
                            },
                        },
                    },
                },
                grep = {
                    format = require("formatters.snacks_formatters").Shayagr_format_brazil_ws,
                    preview = require("formatters.snacks_formatters").Shayagr_workspace_aware_file_preview
                },
                diagnostics = {
                    sort = function(a, b)
                        if a.severity ~= b.severity then
                            return a.severity < b.severity  -- Errors (1) before warnings (2)
                        end
                        return a.lnum < b.lnum  -- Then by line number
                    end
                },
            }
        },
    },
    config = function(_, opts)
        -- Setup with the opts (lazy.nvim passes opts as second parameter)
        require("snacks").setup(opts)

        -- Patch snacks' statuscolumn sign-icon padding to account for actual
        -- display width instead of character count.
        --
        -- Root cause: snacks.statuscolumn.icon() pads sign text with
        -- `2 - vim.fn.strchars(text)` spaces, assuming every character is 1
        -- display cell. True pictographic emoji (💡, ⭐, ✨, etc — anything in
        -- the Unicode 1F3xx+ blocks) are 1 character but 2 display cells wide,
        -- so the padded result renders 3 cells total vs. the empty "  "
        -- placeholder's 2 cells. That 1-cell mismatch is what makes the sign
        -- column resize ("shudder") as a sign like a code-action lightbulb
        -- appears/disappears while moving between lines.
        --
        -- This override pads by `vim.fn.strdisplaywidth()` instead, so any
        -- sign glyph — including full-width emoji — always renders at a fixed
        -- 2-cell width, matching the empty placeholder exactly.
        local statuscolumn = require("snacks.statuscolumn")
        function statuscolumn.icon(sign)
            if not sign then
                return "  "
            end
            local text = vim.fn.strcharpart(sign.text or "", 0, 2) ---@type string
            local width = vim.fn.strdisplaywidth(text)
            if width < 2 then
                text = text .. string.rep(" ", 2 - width)
            elseif width > 2 then
                -- A single character already wider than 2 cells (rare) —
                -- fall back to just that one character, no padding.
                text = vim.fn.strcharpart(sign.text or "", 0, 1)
            end
            return sign.texthl and ("%#" .. sign.texthl .. "#" .. text .. "%*") or text
        end

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
