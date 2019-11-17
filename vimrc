set nocompatible " don't make vim 'vi compatible'

" Sources {{{

if has('nvim')
	source ~/.vim/neovim_specific.vim
endif
" Load general configs that should come first
source ~/.vim/general_configs.vim

" Load vundle = plugin manager
source ~/.vim/plug_plugins.vim
" source related configs
source ~/.vim/plugins_configs.vim
" }}}

" general ft autocmds {{{
augroup ft_plugins
	au!
	autocmd FileType gitcommit set spell
	autocmd BufRead,BufNewFile *.txt set filetype=markdown
augroup END
" }}}

" Colorscheme {{{

" {rtp}/autoload/has.vim
function! HasColorscheme(name) abort
    let pat = 'colors/'.a:name.'.vim'
    return !empty(globpath(&rtp, pat))
endfunction

" set colorscheme
if HasColorscheme('palenight')
	colorscheme palenight
else
	colorscheme desert
endif
" }}}

nmap <silent> <F8> :TagbarToggle<CR>
" cwin

" allow viewing man pages in vim
runtime! ftplugin/man.vim

hi Search cterm=NONE ctermfg=black ctermbg=blue

"hi Comment ctermfg=green

inoremap <C-d> printk("Shay, %s(%d): ",__func__,__LINE__);<esc>T:a
hi TabLine ctermfg=Blue ctermbg=Black

" set the timeout between key sequences (making it so
" small would make jk not be so annoying when typed
set timeoutlen=300
