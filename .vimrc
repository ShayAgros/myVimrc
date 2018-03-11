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
source ~/vimsources/vundlerc.vim
source ~/vimsources/movement_keys_shortcuts.vim
source ~/vimsources/abbr.vim
source ~/vimsources/windows_management.vim
source ~/vimsources/custom_functions.vim

" Language specific conf
source ~/vimsources/c_conf.vim " C\C++
" }}}

" Plugins {{{
"Plugin 'Valloric/YouCompleteMe'
Plugin 'vim-airline/vim-airline'
Plugin 'morhetz/gruvbox'
Plugin 'gosukiwi/vim-atom-dark'
Plugin 'majutsushi/tagbar'
" }}}

nmap <silent> <F8> :TagbarToggle<CR>
" cwin
