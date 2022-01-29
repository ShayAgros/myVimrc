set nocompatible " don't make vim 'vi compatible'

syntax on " allow syntax highlighting

" Make the theme dark. Only actually needed for VIM
set background=dark

set wildmenu " allow choose between different options
set path=.,** " make path include all the directories above
set title " change teminal's title
set textwidth=80

set showcmd " show partially typed commands

set number " show line numbers
set relativenumber

set showmatch " show matching paranthesis
set noswapfile " no swap files

" Splits open at the bottom and right, which is non-retarded, unlike vim defaults.
set splitbelow splitright

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

" don't split long lines into several lines
set nowrap
" }}}

" Indentation {{{
" every tab is 4 spaces
set shiftwidth=4 
" when autoindenting, use 4 spaces
set tabstop=4
" TODO: try to see why it's needed. It seems to indent the code w/o it
set noautoindent " automatic indent after newline
set nocopyindent " copy the previous indentation on autoindenting
" }}}

" Searching {{{
set hlsearch " highlight search
set incsearch " start searching pattern while typing
set smartcase " ignore case if search pattern is lowercase,
			  " case-sensitive otherwise
" smartcase overrides this option only if capital letters appear in search
" but doesn't by default ignore case
set ignorecase
" }}}

"	Sessions {{{
" Save the following when running 'mksession'
"	blank		| empty windows
"	buffers		| hidden and uloaded buffers,not just those
"				  in windows
"	curdir		| the current directory
"	tabpages	| all tab pages
"	winsize		| window sizes
set sessionoptions=blank,buffers,curdir,tabpages,winsize
" }}}
