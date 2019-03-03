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
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail'
let g:airline#extensions#tabline#show_buffers = 0

" Set airline theme
let g:airline_theme='minimalist'

" This is needed it order to support powerline fonts
let g:powerline_pycmd = "py3"
" }}}

"	vim wiki {{{
let g:vimwiki_list = [{'path': '~/.vim/vimwiki'}]

let g:vimwiki_map_prefix = '<Leader>v'

inoremap <C-CR> <Esc>:VimwikiReturn 2 2<CR>

augroup vimwiki_additional
:	au!
:	autocmd BufEnter *.wiki syntax match pythonCode ">>.*"
:	autocmd BufEnter *.wiki highlight link pythonCode Keyword
augroup END
" }}}

"	netrw {{{
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

let g:netrw_list_hide= '.*\.o.*$,.*\.swp$'

" start Explorer by default
"augroup ProjectDrawer
  "autocmd!
  "autocmd VimEnter * :Vexplore
"augroup END
"	}}}

"	vim-latex-live-preview {{{

let g:livepreview_previewer = 'zathura'

" }}}

"	Syntastic {{{

" Errors are populated in location list automatically
let g:syntastic_always_populate_loc_list = 1

" set error and warning symbols
let g:syntastic_error_symbol = "\u2717"
let g:syntastic_warning_symbol = "\u26A0"
let g:syntastic_style_error_symbol = "\uF8EA"
let g:syntastic_style_warning_symbol = "\uF8EA"

let g:syntastic_filetype_map = {
		\ "plaintex": "tex" }

noremap <silent> <leader>sh :SyntasticReset<CR>
" Toggle Syntastic mode
noremap <silent> <leader>st :SyntasticReset<CR>

" }}}

" Ultra snip {{{
" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
let g:UltiSnipsExpandTrigger="<C-j>"
let g:UltiSnipsJumpForwardTrigger="<c-k>"
let g:UltiSnipsJumpBackwardTrigger="<c-j>"

" }}}

" Vim Clever {{{
" This plugins enhances the f command
let g:clever_f_across_no_line = 1
let g:clever_f_fix_key_direction = 1
let g:clever_f_timeout_ms = 3000
"}}}
