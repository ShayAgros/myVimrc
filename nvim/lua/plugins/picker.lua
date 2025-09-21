---@param item snacks.picker.Item
---@param picker snacks.Picker
---@return snacks.picker.Highlight[]
function Shayagr_format_results_for_brazil_ws(item, picker)
    ---@type snacks.picker.Highlight[]
    local ret = {}

    if item.file then
        local path = item.file

        -- Transform src/[package]/main/java/[rest] -> [package]//[rest]
        local package_name, file_type, rest_of_path = path:match("^src/([^/]+)/([^/]+)/java/(.+)$")

        -- Add icon
        if picker.opts.icons.files.enabled ~= false then
            local icon, hl
            if file_type == "test" then
                icon = "T"         -- Simple T for test
                hl = "SnacksPickerFile"
            else
                icon, hl = Snacks.util.icon(item.file, "file")
            end
            ret[#ret + 1] = { Snacks.picker.util.align(icon, 4), hl, virtual = true }
        end

        if package_name and file_type and rest_of_path then
            -- Custom highlight group for package name
            vim.api.nvim_set_hl(0, "CustomPackageName", { fg = "#B64DEB", bold = true })

            -- Add bold colored package name
            ret[#ret + 1] = { package_name, "CustomPackageName", field = "file" }
            ret[#ret + 1] = { "//", "SnacksPickerDelim", field = "file" }
            ret[#ret + 1] = { rest_of_path, "SnacksPickerFile", field = "file" }
        else
            -- Add normal path
            ret[#ret + 1] = { path, "SnacksPickerFile", field = "file" }
        end

        -- Add position
        if item.pos and item.pos[1] > 0 then
            ret[#ret + 1] = { ":" .. item.pos[1], "SnacksPickerRow" }
        end
        ret[#ret + 1] = { " " }
    end

    -- Add line content
    if item.line then
        Snacks.picker.highlight.format(item, item.line, ret)
    end

    return ret
end

---@param search string
function TestTelescopeString(search)
    search = search or "Runnable"
    require("snacks").picker.grep { search = search, live = false,
        exclude = { "*.vim", "tmp/dryrun", "build/" },
        format = Shayagr_format_results_for_brazil_ws
    }
end

local function search_with_ag(command)
    local utils = require "telescope.utils"
    local brazil_cwd = vim.fs.root(vim.fn.expand("%:p"), {'.brazil'})

    local opt = { "--ignore", "*.patch", "--ignore", "tags" }
    if brazil_cwd then
        opt = utils.flatten {
            opt,
            { "--ignore", "build" }
        }
    end

    -- require "snacks" safely and define snack variable
    local _, snacks = pcall(require, "snacks")

    if not snacks then
        require('telescope.builtin').grep_string { search = command.args,
            word_match = "-w",
            use_regex = true,
            additional_args = opt,
            cwd = brazil_cwd,
        }
    else
        TestTelescopeString(command.args)
        -- require("snacks").picker.grep { search = "search", live = false, transform =
        --     function(items)
        --         for _, item in ipairs(items) do
        --             local path =
        --                 item.file or item.filename or item.path
        --             if path then
        --                 local
        --                 package_name, rest_path =
        --                     path:match("^src/([^/]+)/main/java/(.+)$")
        --                 if package_name
        --                     and rest_path then
        --                     item.display = package_name .. "//"
        --                         .. rest_path
        --                 end
        --             end
        --         end
        --         return items
        --     end, }
    end
end


-- Kill the buffer in the current search selection
local delete_buffer = function(prompt_entry)
    local action_state = require "telescope.actions.state"
    local picker = action_state.get_current_picker(prompt_entry)

    picker:delete_selection(function(entry)
        vim.api.nvim_command("bd " .. tostring(entry.bufnr))
    end)
end

function brazil_entry_maker(entry, in_brazil)
    if not in_brazil then
        return require('telescope.make_entry').gen_from_file({})(entry)
    end

    local display_path = entry

    -- More flexible pattern matching
    local src_pattern = "^src/([^/]+)/(.+)$"
    local repo_name, rest_of_path = entry:match(src_pattern)

    if repo_name and rest_of_path then
        display_path = "🇧🇷 " .. repo_name .. "/" .. rest_of_path
    end

    return {
        value = entry,
        display = display_path,
        ordinal = display_path,
        -- You can add more fields if needed
        filename = entry,
    }
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

        keymap("<space><space>", function()
            local in_brazil = vim.b.in_brazil
            builtin.find_files {
                entry_maker = function (entry) return brazil_entry_maker(entry, in_brazil) end,
                file_ignore_patterns = {
                    "build/",           -- Any path containing build/
                }
            }
        end)
        keymap("<space>a", function () builtin.buffers{ sort_mru = true, ignore_current_buffer = true } end)
        keymap("<space>s", function () search_with_ag { args = vim.fn.expand("<cword>") } end)
        keymap("<space>;", function () builtin.current_buffer_fuzzy_find() end)

        -- Search with ag with the F command
        vim.api.nvim_create_user_command("F", search_with_ag, { desc = "search a string with Telescope", nargs = "*"})
    end
}
