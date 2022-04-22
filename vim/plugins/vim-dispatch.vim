""" A plugin to run compilation in the background

Plug 'tpope/vim-dispatch'

" Compile code with dispatch (some language might override this)
nnoremap <silent> <buffer> <space>c :Make<cr>
