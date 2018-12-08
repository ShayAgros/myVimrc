set nocompatible " don't make vim 'vi compatible'

" Sources {{{
" Load general configs that should come first
source ~/vimsources/general_configs.vim

" Load vundle = plugin manager
source ~/.vim/vundle_plugins.vim
" source related configs
source ~/.vim/plugins_configs.vim
" }}}

" Syntastic args {{{
"let g:syntastic_always_populate_loc_list = 1
"let g:syntastic_auto_loc_list = 0
"let g:syntastic_check_on_open = 1
"let g:syntastic_check_on_wq = 1
"let g:syntastic_cpp_check_header = 1

"let g:syntastic_cpp_compiler = "g++"
"let g:syntastic_cpp_compiler_options = "-std=c++11 -Wall -Wextra -Wpedantic"

"let g:syntastic_vhd_compiler = "vcom"
" }}}

nmap <silent> <F8> :TagbarToggle<CR>
" cwin

noremap <silent> <leader>sh :SyntasticReset<CR>

" allow viewing man pages in vim
runtime! ftplugin/man.vim

hi Search cterm=NONE ctermfg=black ctermbg=blue

"hi Comment ctermfg=green

" set colorscheme
colorscheme palenight

inoremap <C-d> printk("Shay: ");<esc>F"i
hi TabLine ctermfg=Blue ctermbg=Black
