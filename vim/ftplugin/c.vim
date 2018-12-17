" C specific configurations

setlocal comments=sr:/*,mb:*,ex:*/,://

"	indentation & indentation {{{
" every tab is 8 spaces
set shiftwidth=8 
" when autoindenting, use 8 spaces
set tabstop=8
" use C indentation
set cindent
set formatoptions=croql  
" }}}

"	foldings {{{
" use zf to create manual foldings
setlocal foldmethod=manual
" don't start folded
setlocal foldlevelstart=99 " start fokded
"	}}}

"	key bindings {{{
" fold current function
nnoremap <buffer> <leader>' [[v][zf

" open header file if it's in the same folder TODO: change it to be
" more global
nnoremap <buffer> <leader>eh :execute "bo 80vsplit " . expand("%:r") . ".h"<CR>

" delete all trailing spaces (delete spaces)
nnoremap <silent> <buffer> <leader>ds :call DeleteTrailingSpaces()<cr>
"	}}}

"	abbrevations {{{
iab #d #define
iab #i #include
iab #b /********************************************************
iab #l /*------------------------------------------------------*/
"	}}}

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
