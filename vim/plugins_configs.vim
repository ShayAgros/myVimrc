" vim: set foldmethod=marker:
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

let g:netrw_list_hide= '.*\.\(cmd\|o\|swp\|ko\)$'

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

" Ultisnips {{{
" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
let g:UltiSnipsExpandTrigger="<c-d>"
let g:UltiSnipsJumpForwardTrigger="<c-d>"
let g:UltiSnipsJumpBackwardTrigger="<c-b>"

" Sets SnippetEdit open vertically
let g:UltiSnipsEditSplit='vertical'

" Set private snippets dir
let g:UltiSnipsSnippetsDir='~/.vim/UltiSnips'


" }}}

" Vim Clever {{{
" This plugins enhances the f command
let g:clever_f_across_no_line = 1
let g:clever_f_fix_key_direction = 1
let g:clever_f_timeout_ms = 3000
"}}}

" vim Tex {{{
" detect tex file as tex and not plaintex
let g:tex_flavor = 'latex'
let g:vimtex_compiler_latexmk = {
	\ 'backend' : 'jobs',
	\ 'background' : 1,
	\ 'build_dir' : '',
	\ 'callback' : 1,
	\ 'continuous' : 1,
	\ 'executable' : 'latexmk',
	\ 'options' : [
	\   '-verbose',
	\   '-file-line-error',
	\   '-synctex=1',
	\   '-interaction=nonstopmode',
	\	'-pdfxe',
	\ ],
	\}
let g:vimtex_compiler_latexmk_engines = {
	\	'_'		:	'-pdfxe'
	\}
let g:vimtex_view_general_viewer = 'mupdf'
let g:vimtex_view_method = 'mupdf'
"}}}

" YouCompleteMe {{{
let g:ycm_collect_identifiers_from_tags_files = 1
let g:ycm_seed_identifiers_with_syntax = 1
let g:ycm_max_diagnostics_to_display = 0
" }}}

"	Vim spell {{{
" ignore abbreviations when spell checking
augroup vimspell
	:au!
	:au BufEnter *	syn match AcronymNoSpell '\<\(\u\|\d\)\{3,}s\?\>' contains=@NoSpell
augroup END
"	}}}

"	Coc	{{{
"
if has('nvim') && has('nvim-0.3.1')

	let g:coc_global_extensions = [
		\'coc-json', 'coc-python',
		\'coc-snippets',
	\]

	" Make coc update faster. This would make linter
	" error messages show faster
	set updatetime=300

	nnoremap ge :CocCommand explorer<CR>

	" Remap keys for gotos
	nnoremap <silent> gd <Plug>(coc-definition)
	nnoremap <silent> gy <Plug>(coc-type-definition)
	nnoremap <silent> gi <Plug>(coc-implementation)
	nnoremap <silent> gr <Plug>(coc-references)

	" Show all diagnostics
	nnoremap <silent> <space>a  :<C-u>CocList diagnostics<cr>
	" Use `[g` and `]g` to navigate diagnostics
	nmap <silent> [g <Plug>(coc-diagnostic-prev)
	nmap <silent> ]g <Plug>(coc-diagnostic-next)

	" always show signcolumns
	set signcolumn=yes

endif " nvim 0.3.1
"	}}}

"	deoplit {{{
let g:deoplete#enable_at_startup = 1
"	}}}

" jedi {{{
let g:jedi#completions_enabled = 0
" }}}

"	Ack {{{
if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif
" }}}

"	LeaderF {{{
if has('nvim') && has('nvim-0.4.2')
	let g:Lf_WindowPosition = 'popup'
	let g:Lf_PreviewInPopup = 1
endif

let g:Lf_ShortcutF = "<leader>ff"
noremap <leader>fs :<C-U><C-R>=printf("Leaderf bufTag %s", "")<CR><CR>
noremap <leader>fh :<C-U><C-R>=printf("Leaderf help %s", "")<CR><CR>
noremap <leader>fg :<C-U><C-R>=printf("Leaderf! rg -e %s ", expand("<cword>"))<CR>
noremap <leader>fm :<C-U><C-R>=printf("Leaderf mru %s", "")<CR><CR>
noremap <leader>fb :<C-U><C-R>=printf("Leaderf buffer %s", "")<CR><CR>
" }}}

"	gruvbox {{{
let g:gruvbox_contrast_dark='hard'
let g:gruvbox_contrast_light='hard'


let g:gruvbox_sign_column='bg0'

" }}}
