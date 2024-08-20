local function search_with_ag(command)
    require('telescope.builtin').grep_string { search = command.args,
        word_match = "-w",
        use_regex = true,
        additional_args = { "--ignore", "*.patch" }
    }
end

-- Kill the buffer in the current search selection
local delete_buffer = function(prompt_entry)
    local action_state = require "telescope.actions.state"
    local picker = action_state.get_current_picker(prompt_entry)

    picker:delete_selection(function(entry)
        vim.api.nvim_command("bd " .. tostring(entry.bufnr))
    end)
end

return {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "kyazdani42/nvim-web-devicons"
    },

    config = function()
        local keymap = function(keys, func)
            vim.keymap.set("n", keys, func, {})
        end

        require("telescope").setup({
            defaults = {
                vimgrep_arguments = {
                  'ag',
                  '--nocolor',
                  '--noheading',
                  '--filename',
                  '--column',
                  '--smart-case',
                },
            },
            pickers = {
                buffers = {
                    mappings = {
                        i = {
                            ["<C-d>"] = delete_buffer,
                        },
                    },
                },
            },
        })
        local builtin = require("telescope.builtin")

        keymap("<leader>sn", function()
            builtin.find_files {
                cwd = vim.fn.stdpath "config"
            }
        end)

        keymap("<space><space>", builtin.find_files)
        keymap("<space>a", function () builtin.buffers{ sort_mru = true, ignore_current_buffer = true } end)
        keymap("<space>s", function () search_with_ag { args = vim.fn.expand("<cword>") } end)

        -- Search with ag with the F command
        vim.api.nvim_create_user_command("F", search_with_ag, { desc = "search a string with Telescope", nargs = "*"})
    end
}
