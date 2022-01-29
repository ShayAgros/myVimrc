""" Snippet completion engine. Used both by VIM and Neovim
""" It is intergrated into Neovim's so, it has to be present in the system

if v:version < 740 && !has('nvim')
	finish
endif

Plug 'SirVer/ultisnips'
" Optional, plugin collection and LSP completion integration
Plug 'honza/vim-snippets'
Plug 'quangnguyen30192/cmp-nvim-ultisnips'

" Trigger configuration
let g:UltiSnipsExpandTrigger="<c-d>"
let g:UltiSnipsJumpForwardTrigger="<c-d>"
let g:UltiSnipsJumpBackwardTrigger="<c-b>"

" Sets SnippetEdit open vertically
let g:UltiSnipsEditSplit='vertical'

" Set private snippets dir
let g:UltiSnipsSnippetDirectories=['~/.vim/UltiSnips']
