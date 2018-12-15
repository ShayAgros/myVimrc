" This file contains plugin specific configs
" and keymappings

"	Tagbar {{{
" toggle Tagbar
nmap <silent> <F8> :TagbarToggle<CR>

" }}}

"	NERDtree {{{
" toggle NERDtree
nmap <silent> <F12> :NERDTreeToggle<CR>
" }}}

"	vim-tasks {{{
" set basic icons
let g:TasksMarkerBase = '☐'
let g:TasksMarkerDone = '✔'
let g:TasksMarkerCancelled = '✘'
let g:TasksDateFormat = '%Y-%m-%d %H:%M'
let g:TasksAttributeMarker = '@'
let g:TasksArchiveSeparator = '＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿'

" enable vim dictionary
augroup	vim-tasks-au
:	autocmd!
:	autocmd FileType tasks setlocal spell spelllang=en_us
augroup END
" }}}
