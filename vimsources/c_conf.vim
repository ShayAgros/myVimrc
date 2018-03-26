" abbrevations
augroup c_abbrev
:	autocmd!
:	autocmd FileType c,cpp :inoremap <buffer> { {<NL>}<Esc>k$o
:augroup END

" pending operations
augroup c_penops
:	autocmd!
:	autocmd FileType c,cpp onoremap in( :<c-u>normal! f(vi(<cr>
:	autocmd FileType c,cpp  set formatoptions=croql cindent comments=sr:/*,mb:*,ex:*/,://
augroup END

" key mapping
augroup c_mapping
:	autocmd!
:	autocmd FileType c,cpp inoremap <c-f> (){<cr>}<esc>k$F(a
:	autocmd FileType c,cpp nnoremap <leader>' [[v][zf
augroup END
