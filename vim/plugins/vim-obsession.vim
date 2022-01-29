""" Vim Obsession plugin. Keeps track of of current session and opened files

Plug 'tpope/vim-obsession'

" for airline status bar
let g:airline#extensions#obsession#enabled = 1
let g:airline#extensions#obsession#indicator_text = '✍️'

" TODO: this need to have a function which checks whether a session for it
" exists. If not, it should prompt for choosing a session name
nnoremap <silent> <localleader>os :Obsession!<cr>
