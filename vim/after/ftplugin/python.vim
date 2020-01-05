
" Indentation {{{

" every tab is 4 spaces
set shiftwidth=4 
" when autoindenting, use 4 spaces
set tabstop=4

set noexpandtab

" }}}

" Key bindings {{{

" run the code when hitting Space+c
nnoremap <space>c :CocCommand python.execInTerminal<cr>
" }}}
