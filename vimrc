" Install Plug (plugin manager)
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
  finish
endif

if has('nvim')
	source ~/.vim/neovim_specific.vim
	luafile ~/.vim/lua/custom_functions.lua
endif

" Load general configs that should come first
source ~/.vim/general_configs.vim

" keybindings
source ~/.vim/key_bindings.vim

" general ft autocmds {{{
augroup ft_plugins
	au!
	autocmd FileType gitcommit set spell
	autocmd FileType verilog_systemverilog set nospell
	autocmd FileType python set nospell
	" it's more intuitive this way
	autocmd FileType qf nnoremap <buffer> <silent> <cr> :.cc<cr>
	autocmd BufRead,BufNewFile *.txt set filetype=markdown
	autocmd BufRead,BufNewFile nx.log* set filetype=cw_logs
	autocmd BufRead,BufNewFile messages-* set filetype=cw_gp_messages
	autocmd BufRead,BufNewFile consolelog-* set filetype=cw_consolelog
	autocmd BufRead,BufNewFile .projectinfo set filetype=project_info
	autocmd BufRead,BufNewFile dmesg* set filetype=dmesg
	autocmd BufRead,BufNewFile CMakeLists.txt set filetype=cmake
	" Remove new lines when saving
"	autocmd BufWritePre * :%s/\s\+$//e
augroup END
" }}}

call plug#begin('~/.vim/plugged')

" autocompletion
source ~/.vim/plugins/nvim-cmp.vim
source ~/.vim/plugins/UltiSnips.vim " Used by VIM
source ~/.vim/plugins/luasnip.vim " Used by Neovim
" lsp config
source ~/.vim/plugins/nvim-lsp.vim

" Telescope should be configured before various plugins
" as it is used by them
source ~/.vim/plugins/telescope.vim

source ~/.vim/plugins/nvim-treesitter.vim
if has('nvim')
luafile ~/.vim/plugins/lualine.lua
else
source ~/.vim/plugins/airline.vim
endif

" My own plugin. Ongoing development
source ~/.vim/plugins/register_calltrace.vim

source ~/.vim/plugins/vim-obsession.vim
source ~/.vim/plugins/tags-bar.vim
source ~/.vim/plugins/vim-dispatch.vim
source ~/.vim/plugins/netrw.vim
source ~/.vim/plugins/fugitive.vim
source ~/.vim/plugins/clever-f.vim
source ~/.vim/plugins/marks.vim
"source ~/.vim/plugins/harpoon.vim
source ~/.vim/plugins/lightspeed.vim
source ~/.vim/plugins/pear-tree.vim
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

" TODO: Move into project management section
nnoremap <silent> <space>dr :!rm -rf ~/ena-drivers/tools/{upstream_release,external_git_release}/ena_release<cr>

set hidden

set mouse=a
set runtimepath+=~/.vim/after
