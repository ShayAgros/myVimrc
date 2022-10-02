" Add $HOME/.vim to default path
set runtimepath^=~/.vim
let &packpath = &runtimepath

" set python executables (why isn't it done by default?)
let g:python3_host_prog = substitute(system("which python3"), '\n', '', '')
let g:python_host_prog = substitute(system("which python2"), '\n', '', '')

" substitute more visually
set inccommand=split

tnoremap <C-j><C-k> <C-\><C-n>

autocmd BufReadPost *
  \ if line("'\"") >= 1 && line("'\"") <= line("$") |
  \   exe "normal! g`\"" |
  \ endif
