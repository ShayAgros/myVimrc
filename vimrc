" Install Plug (plugin manager)
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
  finish
endif

" Load general configs that should come first
source ~/.vim/general_configs.vim

if has('nvim')
	source ~/.vim/neovim_specific.vim
endif

" keybindings
source ~/.vim/key_bindings.vim

" general ft autocmds {{{
augroup ft_plugins
	au!
	autocmd FileType gitcommit set spell
	autocmd FileType verilog_systemverilog set nospell
	autocmd FileType python set nospell
	autocmd BufRead,BufNewFile *.txt set filetype=markdown
	autocmd BufRead,BufNewFile nx.log* set filetype=cw_logs
	autocmd BufRead,BufNewFile messages-* set filetype=cw_gp_messages
	autocmd BufRead,BufNewFile consolelog-* set filetype=cw_consolelog
	autocmd BufRead,BufNewFile dmesg* set filetype=dmesg
augroup END
" }}}

call plug#begin('~/.vim/plugged')

" autocompletion
source ~/.vim/plugins/nvim-cmp.vim
source ~/.vim/plugins/UltiSnips.vim " Needed by nvim-lsp
" lsp config
source ~/.vim/plugins/nvim-lsp.vim
source ~/.vim/plugins/status_bar.vim
source ~/.vim/plugins/vim-obsession.vim
source ~/.vim/plugins/tags-bar.vim
source ~/.vim/plugins/netrw.vim
source ~/.vim/plugins/fugitive.vim
source ~/.vim/plugins/clever-f.vim
source ~/.vim/other_plugins.vim

" colorscheme
source ~/.vim/plugins/colorscheme.vim

call plug#end()

" source related configs
source ~/.vim/plugins_configs.vim

hi Search cterm=NONE ctermfg=black ctermbg=blue

"hi TabLine ctermfg=Blue ctermbg=Black

" set the timeout between key sequences (making it so
" small would make jk not be so annoying when typed
set timeoutlen=300

" I usually want to know if I type correctly
set spell

nnoremap <silent> cn :cn<cr>
nnoremap <silent> cN :cp<cr>

nnoremap <silent> <space>dr :!rm -rf ~/ena-drivers/tools/{upstream_release,external_git_release}/ena_release<cr>

set hidden

set mouse=a
"let g:doge_doc_standard_c = 'kernel_doc'

if has('nvim')
	lua <<EOF
	require'nvim-treesitter.configs'.setup {
	  highlight = {
		enable = true,
		-- Setting this to true will run `:h syntax` and tree-sitter at the same time.
		-- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
		-- Using this option may slow down your editor, and you may see some duplicate highlights.
		-- Instead of true it can also be a list of languages
		additional_vim_regex_highlighting = true,
	  },
	  incremental_selection = {
		enable = true,
		keymaps = {
		  init_selection = "gnn",
		  node_incremental = "grn",
		  scope_incremental = "grc",
		  node_decremental = "grm",
		},
	  },
	  indent = {
		enable = true
	  }
	}
EOF

endif
