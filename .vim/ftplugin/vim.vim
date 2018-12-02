" vim filetype configuration file

" TODO: add " as a commend in 'comments' env

"	fold options {{{

" make folding region to be \{\{\{
setlocal foldmethod=marker
setlocal foldlevelstart=0 " start fokded

" }}}

"	indentation
setlocal tabstop=4 " set tab to be 4 spaces
" indent length when starting new line
setlocal shiftwidth=4
