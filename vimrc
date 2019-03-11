set nocompatible " don't make vim 'vi compatible'

" Sources {{{

if has('nvim')
	source ~/.vim/neovim_specific.vim
endif
" Load general configs that should come first
source ~/vimsources/general_configs.vim

" Load vundle = plugin manager
source ~/.vim/vundle_plugins.vim
" source related configs
source ~/.vim/plugins_configs.vim
" }}}

" general ft autocmds {{{
augroup ft_plugins
	au!
	autocmd FileType gitcommit set spell
augroup END
" }}}

nmap <silent> <F8> :TagbarToggle<CR>
" cwin

" allow viewing man pages in vim
runtime! ftplugin/man.vim

hi Search cterm=NONE ctermfg=black ctermbg=blue

"hi Comment ctermfg=green

" set colorscheme
colorscheme palenight

inoremap <C-d> printk("Shay, %s(%d): ",__func__,__LINE__);<esc>T:a
hi TabLine ctermfg=Blue ctermbg=Black

" set the timeout between key sequences (making it so
" small would make jk not be so annoying when typed
set timeoutlen=300
