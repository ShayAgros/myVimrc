nnoremap <silent> <leader>g :set operatorfunc=<SID>GrepOperator<cr>g@

vnoremap <silent> <leader>g :<c-u>call <SID>GrepOperator(visualmode())<cr>

" BUG: failes for hello1 (searches hello)
function! s:GrepOperator(type)
	let saved_unnamed_register = @@
	if a:type ==# 'v'
		execute "normal! `<v`>y"
	elseif a:type ==# 'char'
		execute "normal! `[y`]"
	else
		return
	endif
	silent execute "grep! -R " . shellescape(@@) . " ."
	execute "normal! \<C-l>"
    	bo copen
	echom 'searched for "' . @@ . '"'
	let @@ = saved_unnamed_register
endfunction
