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

" try and see if this is more comfortable
inoremap <esc> <nop>
inoremap jk <esc>
vnoremap jk <esc>
cnoremap jk <esc>

no <silent> <CR> o<ESC>
