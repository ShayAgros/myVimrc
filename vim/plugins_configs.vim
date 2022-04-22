" vim: set foldmethod=marker:
" This file contains plugin specific configs
" and keymappings

" FZF {{{
nnoremap <silent> <space>/ :execute 'Ag ' . input('Ag/')<CR>
nnoremap <silent> <space>. :Ag<CR>

"nnoremap <silent> <space>; :BLines<CR>
"vnoremap <silent> <space>; "zy:BLines <C-R>z<CR>

nnoremap <silent> <space>o :BTags<CR>
"vnoremap <silent> <space>o "zy:BTags <C-R>z<CR>
nnoremap <silent> <space>O :Tags<CR>
vnoremap <silent> <space>O "zy:Tags <C-R>z<CR>

nnoremap <silent> <space>A :Windows<CR>

function! SearchWordWithAg()
    execute 'Ag ' expand('<cword>')
endfunction

command! -bang -nargs=+ -complete=dir Rag
        \ call fzf#vim#ag_raw(<q-args> . ' ~/Documents/Projects/',
        \ fzf#vim#with_preview({'options': '--delimiter : --nth 4..'}), <bang>0)

let g:fzf_tags_command = '~/workspace/Software/ctags/ctags-p5.9.20210307.0/ctags -x'

if !has('nvim')
	noremap <space><space> :Files<CR>
	nnoremap <silent> <space>a :Buffers<CR>
	nnoremap <silent> <space>s :call SearchWordWithAg()<CR>
	vnoremap <silent> <space>s "zy:Ag <C-R>z<CR>
endif

" }}}
