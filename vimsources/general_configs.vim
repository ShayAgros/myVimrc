syntax on " allow syntax highlighting

set wildmenu " allow choose between different options
set path=.,** " make path include all the directories above
set title " change teminal's title
set textwidth=70

set showmatch " show matching paranthesis

" file and text formatting {{{

" make backspace delete newlines
set backspace=indent,eol,start
" define newLine format
set fileformats=unix,dos

" set auto formatting
"	t - auto-wrap text using 'textwidth'
"	c - same as t, but with comments 'textwidth'
"	r - create comment leader if pressed return in comment 
"	o - same but with 'o' normal command
set formatoptions=tcrol
" }}}

" Indentation {{{
set autoindent " automatic indent after newline
set copyindent	" copy the previous indentation on autoindenting
" }}}

" searching {{{
set hlsearch " highlight search
set incsearch " start searching pattern while typing
set ignorecase " ignore case when searching
set smartcase " ignore case if search pattern is lowercase,
		" case-sensitive otherwise
" set searching color
:hi Search cterm=NONE ctermfg=black ctermbg=lightgreen
" }}}
