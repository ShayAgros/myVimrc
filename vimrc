set nocompatible " don't make vim 'vi compatible'

" Sources {{{
" Load general configs that should come first
source ~/vimsources/general_configs.vim

" Load vundle = plugin manager
source ~/.vim/vundle_plugins.vim
" source related configs
source ~/.vim/plugins_configs.vim
" }}}

nmap <silent> <F8> :TagbarToggle<CR>
" cwin

" allow viewing man pages in vim
runtime! ftplugin/man.vim

hi Search cterm=NONE ctermfg=black ctermbg=blue

"hi Comment ctermfg=green

" set colorscheme
colorscheme palenight

inoremap <C-d> printk("Shay, %s(%d): ",__func__,__LINE__);<esc>T:a
hi TabLine ctermfg=Blue ctermbg=Black

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

" set the timeout between key sequences (making it so
" small would make jk not be so annoying when typed
set timeoutlen=300
