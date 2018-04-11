augroup general_filetype
:	autocmd!
:	autocmd FileType *      set formatoptions=tcql nocindent comments&
:	autocmd FileType vim	setlocal foldmethod=marker
:	autocmd FileType vim	set foldlevelstart=0
augroup END

augroup general_buffer_change
:	autocmd!
:	autocmd BufWritePre *
    		\ if !isdirectory(expand("<afile>:p:h")) |
 	      	\ call mkdir(expand("<afile>:p:h"), "p") |
    		\ endif
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
noh
" start searching pattern while typing
set incsearch
:hi Search cterm=NONE ctermfg=black ctermbg=lightgreen
set textwidth=70

" mark trailig spaces (toggle)
nnoremap <silent> <leader>w :call Mark_whitespace()<cr>
" delete all trailing spaces (delete spaces)
nnoremap <silent> <leader>ds :%s/\([ \t]\+\)$/<cr>
