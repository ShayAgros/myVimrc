" Similar to vim fzf, this is a fuzzy searcher

if !has('nvim-0.5.0')
	finish
endif

Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'kyazdani42/nvim-web-devicons'
"Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }

" Beginning transition from FZF to Telescope


let g:my_telescope_supported=1

"nnoremap <silent> <space>o <cmd>lua require('telescope.builtin').current_buffer_tags()<cr>
nnoremap <silent> <space>; <cmd>lua require('telescope.builtin').current_buffer_fuzzy_find()<cr>

lua << EOF
function ag_additional_args_func(opts)
    if ag_additional_args then
        return ag_additional_args
    end
    return nil
end

function search_with_ag(string)
    require('telescope.builtin').grep_string{search=string, word_match="-w", use_regex=true, additional_args=ag_additional_args_func}
end
EOF
command! -nargs=1 F lua search_with_ag([[<args>]])
function! SearchWordWithTelescope()
    execute 'F ' expand('<cword>')
endfunction
nnoremap <silent> <space>s :lua search_with_ag()<CR>
vnoremap <silent> <space>s "zy:F <C-R>z<CR>

lua << EOF
local delete_buffer = function(prompt_entry)
	local action_state = require "telescope.actions.state"
	local actions = require('telescope.actions')
	local picker = action_state.get_current_picker(prompt_entry)

	picker:delete_selection(function(entry)
		vim.api.nvim_command("bd " .. tostring(entry.bufnr))
	end)
--	for _, entry in ipairs(picker:get_multi_selection()) do
--		vim.api.nvim_command("bd " .. tostring(entry.bufnr))
--	end
--
--	actions.close(prompt_entry)
end

local search_exact = function(prompt_entry)
	local action_state = require "telescope.actions.state"
	local actions = require('telescope.actions')
	local picker = action_state.get_current_picker(prompt_entry)
	local finders = require "telescope.finders"

	grep_string_ops = picker.grep_string_ops
	if not grep_string_ops then
		print("No grep_string configurations were found")
		return
	end

	-- toggle exact search
	grep_string_ops.word_match = not grep_string_ops.word_match and "-w" or nil
	ag_com = vim.tbl_flatten {
				grep_string_ops.vimgrep_arguments,
				grep_string_ops.additional_args,
				grep_string_ops.word_match,
				"--",
				grep_string_ops.search,
			}

	new_finder = finders.new_oneshot_job(ag_com,
										 {
											 entry_maker = require("telescope.make_entry").gen_from_vimgrep{} 
										 })

	-- TODO: this doesn't work... Needs fixing
	prompt_title = "Find Word (" .. grep_string_ops.word .. ")"
	prompt_title = prompt_title .. (grep_string_ops.word_match and " - exact match" or "")
    picker.prompt_title = prompt_title

	picker:refresh(new_finder)

--	vim.api.nvim_buf_set_lines(picker.prompt_bufnr, 0, 1, false, { "word" })
end

function setup_telescope()
	local success, telescope = pcall(require, 'telescope')

	if not success then
		return
	end

	telescope.setup{
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
			grep_string = {
					mappings = {
						i = {
							["<C-x>"] = search_exact,
						},
					},
				},
		},
	--	extensions = {
	--		fzf = {
	--		  override_generic_sorter = false, -- override the generic sorter
	--		  override_file_sorter = true,     -- override the file sorter
	--		  case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
	--		}
	--	},
	}

	vim.api.nvim_set_keymap('n', ' a', "<cmd>lua require('telescope.builtin').buffers{ sort_mru = true, ignore_current_buffer = true }<cr>", {noremap = true})
	vim.api.nvim_set_keymap('n', '<space><space>', "<cmd>lua require('telescope.builtin').find_files()<cr>", {noremap = true})
end

vim.api.nvim_command("augroup TelescopeAU")
vim.api.nvim_command("au!")
vim.api.nvim_command("autocmd User DoAfterConfigs ++nested lua setup_telescope()")
vim.api.nvim_command("augroup END")

EOF
