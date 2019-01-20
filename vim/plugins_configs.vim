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

"	airline {{{
" Tell powerline to use powerline symbolas
let g:airline_powerline_fonts = 1

" Set airline theme
let g:airline_theme='minimalist'

" This is needed it order to support powerline fonts
let g:powerline_pycmd = "py3"
" }}}

"	vim wiki {{{
let g:vimwiki_list = [{'path': '~/.vim/vimwiki'}]

let g:vimwiki_map_prefix = '<Leader>v'

inoremap <C-CR> <Esc>:VimwikiReturn 2 2<CR>
" }}}
