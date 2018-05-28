" Disable false movement keys
ino <down> <Nop>
ino <left> <Nop>
ino <right> <Nop>
ino <up> <Nop>
no <down> <Nop>
no <left> <Nop>
no <right> <Nop>
no <up> <Nop>

" faster moving around
noremap <silent> H gg
noremap <silent> L G

" try and see if it is more comfortable
inoremap <esc> <nop>
inoremap jk <esc>
" you're gonna have to find a better way to
" to cancel highliting
"vnoremap jk <esc>
cnoremap jk <Esc>

no <silent> <CR> o<ESC>
