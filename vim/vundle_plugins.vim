" set filetype off - required by Vundle
filetype off

" Add Vundle plugins to path
set rtp+=~/.vim/bundle/Vundle.vim

call vundle#begin() " start Vundle

" Load Vundle plugin
Plugin 'VundleVim/Vundle.vim'

Plugin 'Valloric/YouCompleteMe'

Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'vim-syntastic/syntastic'
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-eunuch'
Plugin 'vim-scripts/ZoomWin'
Plugin 'kien/ctrlp.vim'

" Tex
Plugin 'xuhdev/vim-latex-live-preview'
Plugin 'lervag/vimtex'

"	note taking and text documents {{{
Plugin 'gabrielelana/vim-markdown'
Plugin 'shayagros/vim-tasks'
Plugin 'vimwiki/vimwiki'
" }}}

" Surrounding text with comments/chars {{{
Plugin 'scrooloose/nerdcommenter'
Plugin 'tpope/vim-surround'
" }}}

" Tags and files windows {{{
Plugin 'majutsushi/tagbar'
"Plugin 'scrooloose/nerdtree'
Plugin 'tpope/vim-vinegar'
" }}}

" Themes amd colors {{{
Plugin 'neutaaaaan/iosvkem'
Plugin 'drewtempelmeyer/palenight.vim'
Plugin 'ayu-theme/ayu-vim'
" }}}

"	Syntax {{{
Plugin 'mboughaba/i3config.vim'
" }}}

"	Ultra snip {{{
Plugin 'SirVer/ultisnips'

" Optional
Plugin 'honza/vim-snippets'
" }}}

call vundle#end()
" required by Vundle
filetype plugin indent on
