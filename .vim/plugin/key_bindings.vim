let $vimd=$HOME."/.vim"

" .vimrc editing {{{
" open .vimrc in vertical split
nnoremap <silent> <localleader>ev :bo 70vsplit ${MYVIMRC}<CR>
" source .vimrc
nnoremap <silent> <localleader>sv :source $MYVIMRC<CR>
" }}}

" reference files {{{
let $refd=$vimd."/references"
noremap <silent> <leader>svr :bo 80vsplit ${refd}/vim_ref<CR>
noremap <silent> <leader>sar :bo 80vsplit ${refd}/asm_ref"<CR>
" }}}

" white spaces delete {{{
	function! DeleteTrailingSpaces()
		let l:pos = winsaveview() " cursor pos
		let l:search=@/
	    %s/\v\s+$//g
	    call winrestview(l:pos)
	    let @/=l:search
	endfunction
" delete all trailing spaces (delete spaces)
nnoremap <silent> <leader>ds :call DeleteTrailingSpaces()<cr>
" }}}
