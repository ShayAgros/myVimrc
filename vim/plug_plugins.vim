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
elseif v:version >= 800
	Plug 'Valloric/YouCompleteMe'
endif

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-eunuch'
Plug 'kien/ctrlp.vim'

Plug 'rhysd/clever-f.vim'
Plug 'Townk/vim-autoclose'
Plug 'wsdjeg/vim-fetch'

" Tex
"Plug 'xuhdev/vim-latex-live-preview'
Plug 'pyarmak/vim-pandoc-live-preview'
Plug 'lervag/vimtex'

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
"Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'tpope/vim-vinegar'
" }}}

" Themes amd colors {{{
Plug 'neutaaaaan/iosvkem'
Plug 'drewtempelmeyer/palenight.vim'
Plug 'ayu-theme/ayu-vim'
Plug 'jaredgorski/SpaceCamp'
" }}}

"	Syntax {{{
Plug 'mboughaba/i3config.vim'
" }}}

"	Ultra snip {{{
Plug 'SirVer/ultisnips'

" Optional
Plug 'honza/vim-snippets'
" }}}

call plug#end()

endif
