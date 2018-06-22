" abbrevations
augroup c_abbrev
:	autocmd!
:augroup END

" indentation
augroup c_indent
:	autocmd!
:	autocmd FileType c,cpp set shiftwidth=8 tabstop=8
augroup END

" pending operations
augroup c_penops
:	autocmd!
:	autocmd FileType c,cpp onoremap in( :<c-u>normal! f(vi(<cr>
:	autocmd FileType c,cpp  set formatoptions=croql cindent comments=sr:/*,mb:*,ex:*/,://
augroup END

" key mapping
augroup c_mapping
:	autocmd!
:	autocmd FileType c,cpp inoremap <buffer> <c-f> (){<cr>}<esc>k$F(a
:	autocmd FileType c,cpp nnoremap <buffer> <leader>' [[v][zf
:	autocmd FileType c,cpp nnoremap <buffer> <leader>eh :execute "bo 80vsplit " . expand("%:r") . ".h"<CR>
":	autocmd FileType c,cpp :inoremap <buffer> <silent> <cr> <esc>:call CCR()<cr>
":	autocmd FileType c,cpp :inoremap <buffer> <silent> <cr> <esc>
augroup END


" You need to check that the curser is at the end of line
" BUGS TO FIX: 1) The new line is unindented
"		2) The search doesn't recognize the letter it's on
"		3) The search is not fo the current line only
function! CCR()
	let last_saved=@@
	let last_searched=@/
	" find current line content
	silent execute "normal! ma?[^ ]\nvy"
	noh
	if @@ ==# '{'
		silent execute "normal! $a\<cr>}\<esc>`aa\<cr>"
	else
		silent execute "normal! $a\<cr>"
	endif
	echo @@
	let @@=last_saved
	let @/=last_searched
endfunction

