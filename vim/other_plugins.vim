if has('nvim')
	if has('nvim-0.5.0')
		" Telescope
		Plug 'nvim-lua/plenary.nvim'
		Plug 'nvim-telescope/telescope.nvim'
		Plug 'kyazdani42/nvim-web-devicons'
		Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }
	endif
endif

" Creates commands like SudoWrite and Rename which allow to manipulate files
Plug 'tpope/vim-eunuch'

" Allows you to open files like filename:<line number>
Plug 'wsdjeg/vim-fetch'

Plug 'junegunn/fzf', { 'do': './install --bin' }
Plug 'junegunn/fzf.vim'

" Allows to creates autoformatted tables. Useful when adding tables to
" commit messages
Plug 'dhruvasagar/vim-table-mode'

" You probably don't need this as you only need the syntax highlighting for
" Markdown and TreeSitter already handles it (though not in VIM .. but what MD
" files do you edit there ?)
"Plug 'gabrielelana/vim-markdown'

" Add a comment to text blocks
Plug 'scrooloose/nerdcommenter'

" Surround blocks with custom characthers
Plug 'tpope/vim-surround'
" enhances vim-surround by adding '.' capability
Plug 'tpope/vim-repeat'
