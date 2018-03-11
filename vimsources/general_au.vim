augroup general_au
:	autocmd!
:	autocmd FileType *      set formatoptions=tcql nocindent comments& 
:	autocmd FileType vim	setlocal foldmethod=marker
:	autocmd FileType vim	set foldlevelstart=0
augroup END

syntax on
colorscheme desert
set wildmenu

set nocompatible
set path=.,**
"set relativenumber

" Default settings
set autoindent
" indent length
set sw=4
" define newLine format
set fileformats=unix,dos
" highlight search
set hlsearch
" start searching pattern while typing
set incsearch
:hi Search cterm=NONE ctermfg=black ctermbg=lightgreen
set textwidth=70
