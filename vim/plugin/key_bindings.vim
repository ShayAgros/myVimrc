" All genral key bindings

" exit command/insert mode with 'jk' squence
inoremap jk <esc>
cnoremap jk <C-C>

" make Enter start new line in normal mode
no <silent> <CR> o<ESC>

" .vimrc editing {{{
" open .vimrc in vertical split
nnoremap <silent> <localleader>ev :bo 70vsplit ${MYVIMRC}<CR>
" source .vimrc
nnoremap <silent> <localleader>sv :source $MYVIMRC<CR>
" }}}

" reference files {{{
let $refd="~/.vim/references"
noremap <silent> <leader>svr :bo 80vsplit ${refd}/vim_ref<CR>
noremap <silent> <leader>sar :bo 80vsplit ${refd}/asm_ref"<CR>
" }}}

" white spaces delete {{{
	function! DeleteTrailingSpaces()
		let l:line_num = 1
		for line in getline(1,"$")
			call setline(l:line_num, substitute(line,'\v\s+$',"","g"))
			let l:line_num = l:line_num + 1
		endfor
	endfunction
" delete all trailing spaces (delete spaces)
nnoremap <silent> <leader>ds :call DeleteTrailingSpaces()<cr>
" }}}
