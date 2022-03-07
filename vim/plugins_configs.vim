" vim: set foldmethod=marker:
" This file contains plugin specific configs
" and keymappings

" FZF {{{
nnoremap <silent> <space>/ :execute 'Ag ' . input('Ag/')<CR>
nnoremap <silent> <space>. :Ag<CR>

"nnoremap <silent> <space>; :BLines<CR>
"vnoremap <silent> <space>; "zy:BLines <C-R>z<CR>

nnoremap <silent> <space>o :BTags<CR>
"vnoremap <silent> <space>o "zy:BTags <C-R>z<CR>
nnoremap <silent> <space>O :Tags<CR>
vnoremap <silent> <space>O "zy:Tags <C-R>z<CR>

nnoremap <silent> <space>A :Windows<CR>

function! SearchWordWithAg()
    execute 'Ag ' expand('<cword>')
endfunction

command! -bang -nargs=+ -complete=dir Rag
        \ call fzf#vim#ag_raw(<q-args> . ' ~/Documents/Projects/',
        \ fzf#vim#with_preview({'options': '--delimiter : --nth 4..'}), <bang>0)

let g:fzf_tags_command = '~/workspace/Software/ctags/ctags-p5.9.20210307.0/ctags -x'

if !has('nvim')
	noremap <space><space> :Files<CR>
	nnoremap <silent> <space>a :Buffers<CR>
	nnoremap <silent> <space>s :call SearchWordWithAg()<CR>
	vnoremap <silent> <space>s "zy:Ag <C-R>z<CR>
endif

" }}}

" Telescope {{{

if has('nvim')
" Find files using Telescope command-line sugar.
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>

" Using Lua functions
nnoremap <leader>ff <cmd>lua require('telescope.builtin').find_files()<cr>
nnoremap <leader>fg <cmd>lua require('telescope.builtin').live_grep()<cr>
nnoremap <leader>fs <cmd>exec "lua require('telescope.builtin').grep_string{ search = " . expand('<cword>') . "}"<cr>
nnoremap <leader>fb <cmd>lua require('telescope.builtin').buffers()<cr>
nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags()<cr>

" Beginning transition from FZF to Telescope
"nnoremap <silent> <space>o <cmd>lua require('telescope.builtin').current_buffer_tags()<cr>
nnoremap <silent> <space>; <cmd>lua require('telescope.builtin').current_buffer_fuzzy_find()<cr>

command! -nargs=1 F lua require('telescope.builtin').grep_string{search="<args>"}

function! SearchWordWithTelescope()
    execute 'F ' expand('<cword>')
endfunction
nnoremap <silent> <space>s :call SearchWordWithTelescope()<CR>
vnoremap <silent> <space>s "zy:F <C-R>z<CR>

lua << EOF
local function search_word_under_cursor()
	
end

local delete_buffer = function(prompt_entry)
	local action_state = require "telescope.actions.state"
	local actions = require('telescope.actions')
	local picker = action_state.get_current_picker(prompt_entry)

	for _, entry in ipairs(picker:get_multi_selection()) do
		print("deleting", entry.bufnr)
		vim.api.nvim_command("bd " .. tostring(entry.bufnr))
	end

	actions.close(prompt_entry)
end

local success, telescope = pcall(require, 'telescope')

if success then

telescope.setup{
	defaults = {
		vimgrep_arguments = {
		  'ag',
		  '--nocolor',
		  '--noheading',
		  '--filename',
		  '--column',
		  '--smart-case'
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
	extensions = {
		fzf = {
		  override_generic_sorter = false, -- override the generic sorter
		  override_file_sorter = true,     -- override the file sorter
		  case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
		}
	},
}

vim.api.nvim_set_keymap('n', ' a', "<cmd>lua require('telescope.builtin').buffers{ sort_mru = true, ignore_current_buffer = true }<cr>", {noremap = true})
vim.api.nvim_set_keymap('n', '<space><space>', "<cmd>lua require('telescope.builtin').find_files()<cr>", {noremap = true})

end
EOF

endif

" }}}
