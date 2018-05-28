echom "Wellcome to Vim" ">^.^<"
" Make words uppercase
nnoremap <c-u> viwU
" fix del key
inoremap <Del> <esc>lxi

" Convinient way to edit vimrc
nnoremap <silent> <localleader>ev :bo 60vsplit ${MYVIMRC}<CR>
nnoremap <silent> <localleader>sv :source $MYVIMRC<CR>

" surround selected tex with quotes
vnoremap <silent> <localleader>" <esc>a"<esc>`<i"<esc>lwl
" add support for visual line mode

" Sources {{{
source ~/vimsources/general_au.vim
source ~/vimsources/movement_keys_shortcuts.vim
source ~/vimsources/abbr.vim
source ~/vimsources/windows_management.vim
source ~/vimsources/custom_functions.vim

" Language specific conf
source ~/vimsources/c_conf.vim " C\C++
" }}}

" Plugins {{{
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
"Plugin 'Valloric/YouCompleteMe'
Plugin 'vim-airline/vim-airline'
Plugin 'majutsushi/tagbar'
Plugin 'file:///home/shay/.vim/potion'
Plugin 'scrooloose/nerdcommenter'
Plugin 'vim-syntastic/syntastic'
Plugin 'tpope/vim-fugitive'
call vundle#end()            " required
filetype plugin indent on    " required
" }}}

" Syntastic args {{{
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 0
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 1
let g:syntastic_cpp_check_header = 1

let g:syntastic_cpp_compiler = "g++"
let g:syntastic_cpp_compiler_options = "-std=c++11 -Wall -Wextra -Wpedantic"

let g:syntastic_vhd_compiler = "vcom"
" }}}


nmap <silent> <F8> :TagbarToggle<CR>
" cwin

:nnoremap <leader>N :setlocal number!<cr> :setlocal relativenumber!<cr>

cabbrev ep call EditPotion()

function! EditPotion()
	find ~/.vim/bundle/potion
endfunction

nnoremap d "_d
nnoremap D d
nnoremap x "_x
nnoremap c "_c

nnoremap <silent> <leader>h :noh<CR>
nnoremap <silent> <leader>rf :find %<CR>


noremap <silent> <leader>sl :lopen<cr>
noremap <silent> <leader>cl :lclose<cr>
