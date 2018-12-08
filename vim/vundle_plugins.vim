" set filetype off - required by Vundle
filetype off

" Add Vundle plugins to path
set rtp+=~/.vim/bundle/Vundle.vim

call vundle#begin() " start Vundle

" Load Vundle plugin
Plugin 'VundleVim/Vundle.vim'

Plugin 'vim-airline/vim-airline'
Plugin 'vim-syntastic/syntastic'
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-eunuch'
Plugin 'vim-scripts/ZoomWin'
Plugin 'kien/ctrlp.vim'
Plugin 'gabrielelana/vim-markdown'

" Surrounding text with comments/chars {{{
Plugin 'scrooloose/nerdcommenter'
Plugin 'tpope/vim-surround'
" }}}

" Tags and files windows {{{
Plugin 'majutsushi/tagbar'
Plugin 'scrooloose/nerdtree'
" }}}

" Themes amd colors {{{
Plugin 'neutaaaaan/iosvkem'
Plugin 'drewtempelmeyer/palenight.vim'
Plugin 'ayu-theme/ayu-vim'
" }}}

call vundle#end()
" required by Vundle
filetype plugin indent on
