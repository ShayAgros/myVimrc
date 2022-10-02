" Configure vim airline plugin
" It is the status bar above and below each window

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Set airline theme
let g:airline_theme='minimalist'
let g:airline_powerline_fonts = 1

" This is needed it order to support powerline fonts
let g:powerline_pycmd = "py3"

" Make "airline" for buffers as well
let g:airline#extensions#tabline#enabled = 1
" Only display the unique tail of each buffer name
let g:airline#extensions#tabline#formatter = 'unique_tail'
let g:airline#extensions#tabline#show_buffers = 0

let g:airline#extensions#obsession#enabled = 1
let g:airline#extensions#obsession#indicator_text = '✍️'

"function! AirlineInit()
    "let g:airline_section_a =
