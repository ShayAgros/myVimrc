if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Failed to download and configure plugins
if !empty(glob('~/.vim/autoload/plug.vim'))

call plug#begin('~/.vim/plugged')

if has('nvim')
	if has('nvim-0.3.1')
		Plug 'neoclide/coc.nvim', {'branch': 'release'}
	endif
endif

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-eunuch'

Plug 'rhysd/clever-f.vim'
Plug 'Townk/vim-autoclose'
Plug 'wsdjeg/vim-fetch'

Plug 'mileszs/ack.vim'

if v:version >= 800
	Plug 'kkoomen/vim-doge'
endif

" Tex
"Plug 'xuhdev/vim-latex-live-preview'
Plug 'pyarmak/vim-pandoc-live-preview'
Plug 'lervag/vimtex'

Plug 'junegunn/fzf', { 'do': './install --bin' }
Plug 'junegunn/fzf.vim'

" Text formatting {{{
Plug 'dhruvasagar/vim-table-mode'
"}}}

"	note taking and text documents {{{
Plug 'gabrielelana/vim-markdown'
Plug 'shayagros/vim-tasks'
"Plug 'vimwiki/vimwiki'
" }}}

" Surrounding text with comments/chars {{{
Plug 'scrooloose/nerdcommenter'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
" }}}

" Tags and files windows {{{
Plug 'majutsushi/tagbar'
" }}}

" Themes amd colors {{{
Plug 'neutaaaaan/iosvkem'
Plug 'drewtempelmeyer/palenight.vim'
Plug 'ayu-theme/ayu-vim'
Plug 'jaredgorski/SpaceCamp'
Plug 'morhetz/gruvbox'
" }}}

"	Syntax {{{
Plug 'mboughaba/i3config.vim'
" }}}

"	Ultra snip {{{
if has('nvim')
	Plug 'SirVer/ultisnips'

	" Optional
	Plug 'honza/vim-snippets'
	" }}}

endif
call plug#end()

endif
