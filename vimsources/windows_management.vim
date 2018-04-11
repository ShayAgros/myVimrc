nnoremap <silent> <C-right> :tabnext<CR>
nnoremap <silent> <C-left> :tabprevious<CR>
nnoremap <silent> <leader>t	:tabnew<CR>
nnoremap <silent> <leader>w     :q<CR>

"imap <C-left> <ESC>:tabprevious<CR>
"imap <C-right> <ESC>:tabnext<CR>
"imap <C-t>      :tabnew<CR>
"imap <C-w>      :tabclose

" Windows movement
nnoremap <silent> <C-J> <C-W><C-J>
nnoremap <silent> <C-K> <C-W><C-K>
nnoremap <silent> <C-L> <C-W><C-L>
nnoremap <silent> <C-H> <C-W><C-H>

" Maps {,_,+,} to resizing a window split
nnoremap <silent> { <C-w><
nnoremap <silent> _ <C-W>-
nnoremap <silent> + <C-W>+
nnoremap <silent> } <C-w>>

" Maps Alt-[s.v] to horizontal and vertical split respectively
nnoremap <silent> & :bo split<CR>
nnoremap <silent> <leader>o :bo vsplit<CR>

" Resize splits to default
nnoremap <silent> <leader>rw <C-w>=
