" All genral key bindings

" exit command/insert mode with 'jk' squence
inoremap jk <esc>
cnoremap jk <C-C>

" make Enter start new line in normal mode
nnoremap <silent> <CR> o<ESC>

" toggle paste mode
set pastetoggle=<leader>pt

" set line numbers
nnoremap <leader>N :setlocal number!<cr>

" refresh file
nnoremap <silent> <leader>rf :find %<CR>

" Yank into clipboard
nnoremap Y "+y
vnoremap Y "+y

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
" }}}

"	Default keybindings override {{{
"
" make deleting more intuitive to me
"
" D/X - cuts
" d/x - deletes (doesn't save it)
nnoremap d "_d
nnoremap D d
xnoremap d "_d
xnoremap D d

nnoremap x "_x
nnoremap c "_c
" }}}

"	windows (vertical/horizontal) bindings {{{

" move between windows with CTRL+direction
	"nnoremap <silent> <C-H> <C-W><C-H>
	"nnoremap <silent> <C-J> <C-W><C-J>
	"nnoremap <silent> <C-K> <C-W><C-K>
	"nnoremap <silent> <C-L> <C-W><C-L>

" Maps {,_,+,} to resizing a window split
	nnoremap <silent> { <C-w><
	nnoremap <silent> _ <C-W>-
	nnoremap <silent> + <C-W>+
	nnoremap <silent> } <C-w>>

" Maps \o to open a file vertically in the right-most
" side of the screen
	"nnoremap <silent> <leader>o :bo vsplit<CR>

" }}}

"	tab management bindings {{{

" move between tabs with CTRL+arrow
	nnoremap <silent> <C-right> :tabnext<CR>
	nnoremap <silent> <C-left> :tabprevious<CR>
	nnoremap <silent> W :tabnext<CR>
	nnoremap <silent> Q :tabprevious<CR>

" open a new tab in the same directory as the file
" I'm editing now
	nnoremap <silent> <leader>t	:tabnew %:h<CR>

" exit from normal/termianl window with \w
	"nnoremap <silent> <leader>w     :q<CR>
	if has('terminal')
		"tnoremap <silent> <leader>w     <C-W><C-C>
		tnoremap <silent> <C-W>c <C-W>:close!<CR>
		tnoremap <silent> W <C-W>:tabnext<CR>
		tnoremap <silent> Q <C-W>:tabprevious<CR>
	endif
" }}}

"	highlighting {{{
" stop highliting using \\
nnoremap <silent> <leader><leader> :noh<cr>

" highlight word under cursor
nnoremap <silent> * "syiw:execute "let @/ = \"\\\\M\\\\<".@s."\\\\>\"" <bar> set hlsearch<cr>
vnoremap <silent> * "sy:execute "let @/ = \"\\\\M\\\\<".@s."\\\\>\"" <bar> set hlsearch<cr>
"nnoremap <silent> * "syiw:execute "let @/ = '\\M\\<". substitute(substitute(@s,"^'",'\1',"g"),"'$","","g") ."\\>'" <bar> set hlsearch<cr>
"vnoremap <silent> * "sy:execute "let @/ = '\\M\\<".substitute(substitute(@s,"^'",'\1',"g"),"'$","","g")."\\>'" <bar> set hlsearch<cr>

nnoremap <silent> <c-w>* "syiw:execute "let @/ = \"\\\\c\\\\M\\\\<".@s."\\\\>\"" <bar> set hlsearch<cr>

" }}}

"	Location list {{{
" open and close location list
noremap <silent> <leader>lo :lopen<cr>
noremap <silent> <leader>lc :lclose<cr>
" }}}

"	Tags {{{
" change default split for c-]
noremap <silent> <c-w><c-]> <c-w><c-]><c-w>L
" }}}

"	Editing {{{

" move line up/down
nnoremap K "sddk"sP
nnoremap J "sdd"sp

" move screen right/left
nnoremap L zl
nnoremap H zh
" }}}
