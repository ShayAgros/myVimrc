set nocompatible " don't make vim 'vi compatible'

" Sources {{{
" Load general configs that should come first
source ~/vimsources/general_configs.vim
" Load vundle = plugin manager
source ~/.vim/vundle_plugins.vim

source ~/vimsources/vim_mapping_override.vim
source ~/vimsources/abbr.vim
source ~/vimsources/windows_management.vim
source ~/vimsources/custom_functions.vim

" type specific conf
source ~/vimsources/c_conf.vim " C\C++
source ~/vimsources/netrw_conf.vim " file tree
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

:nnoremap <leader>N :setlocal number!<cr>

cabbrev ep call EditPotion()
function! EditPotion()
	find ~/.vim/bundle/potion
endfunction

" stop highlighting
nnoremap <silent> <leader>h :noh<CR>
" refresh file
nnoremap <silent> <leader>rf :find %<CR>

noremap <silent> <leader>sl :lopen<cr>
noremap <silent> <leader>cl :lclose<cr>
noremap <silent> <leader>sh :SyntasticReset<CR>

" allow viewing man pages in vim
runtime! ftplugin/man.vim

hi Search cterm=NONE ctermfg=black ctermbg=blue

"hi Comment ctermfg=green

" change default split for c-]
"noremap <silent> <c-w><c-]> :vsplit<CR>:execute "tag " . expand("<cword>")<CR>:vertical resize 60<CR>
noremap <silent> <c-w><c-]> <c-w><c-]><c-w>L

nnoremap <silent> <leader>sa :bo 70vsplit /home/shay/workspace/asm_learn<CR>

" set colorscheme
colorscheme palenight

" maybe for future reference
"set list
"set listchars=tab:>\

" toggle paste mode
set pastetoggle=<leader>pt

inoremap <C-d> printk("Shay: ");<esc>F"i
hi TabLine ctermfg=Blue ctermbg=Black
