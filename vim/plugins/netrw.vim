""" Configuration of the built-in netrw file-manager in VIM

"" folders are expanded instead of 'being entered'
let g:netrw_liststyle = 3
" remove ugly netrw banner
let g:netrw_banner = 0
" open file instead of the previous one
let g:netrw_browse_split = 4
" set netrw window to be of fixed size
let g:netrw_winsize = 20

" split window to the right
let g:netrw_altv = 1

let g:netrw_list_hide= '.*\.\(cmd\|o\|swp\|ko\)$'
