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

syntax on " allow syntax highlighting

set wildmenu " allow choose between different options
set nocompatible " don't make vim 'vi compatible'
set path=.,** " make path include all the directories above

filetype off " set Vundle (Plugin manager)
set rtp+=~/.vim/bundle/Vundle.vim

set autoindent " automatic indent after newline
set sw=4 " indent length
set copyindent	" copy the previous indentation on autoindenting
set showmatch " show matching paranthesis

" define newLine format
set fileformats=unix,dos

set hlsearch " highlight search
set incsearch " start searching pattern while typing
set ignorecase " ignore case when searching
set smartcase " ignore case if search pattern is lowercase,
		" case-sensitive otherwise
noh " don't highlight anything on vim start


" set searching color
:hi Search cterm=NONE ctermfg=black ctermbg=lightgreen
set textwidth=70

" mark trailig spaces (toggle)
nnoremap <silent> <leader>w :call Mark_whitespace()<cr>
" delete all trailing spaces (delete spaces)
nnoremap <silent> <leader>ds :%s/\([ \t]\+\)$/<cr>

set title " change teminal's title
