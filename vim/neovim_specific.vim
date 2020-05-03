" Add $HOME/.vim to default path
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath

" set python executables
let g:python3_host_prog='/bin/python3'
let g:python_host_prog='/bin/python2'

" substitute more visually
set inccommand=split

tnoremap <C-j><C-k> <C-\><C-n>

autocmd BufReadPost *
  \ if line("'\"") >= 1 && line("'\"") <= line("$") |
  \   exe "normal! g`\"" |
  \ endif
