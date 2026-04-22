let SessionLoad = 1
let s:so_save = &g:so | let s:siso_save = &g:siso | setg so=0 siso=0 | setl so=-1 siso=-1
let v:this_session=expand("<sfile>:p")
silent only
silent tabonly
cd ~/workspace/brazil/dev-kermit/src/OscarMysql80
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
let s:shortmess_save = &shortmess
if &shortmess =~ 'A'
  set shortmess=aoOA
else
  set shortmess=aoO
endif
badd +3689 sql/item_func.cc
badd +15 ~/workspace/dotfiles/myVimrc/nvim/init.lua
badd +1 ~/workspace/dotfiles/myVimrc/nvim/lua/addons/smartFileOpening.lua
argglobal
%argdel
edit sql/item_func.cc
let s:save_splitbelow = &splitbelow
let s:save_splitright = &splitright
set splitbelow splitright
wincmd _ | wincmd |
vsplit
1wincmd h
wincmd w
let &splitbelow = s:save_splitbelow
let &splitright = s:save_splitright
wincmd t
let s:save_winminheight = &winminheight
let s:save_winminwidth = &winminwidth
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
exe 'vert 1resize ' . ((&columns * 102 + 103) / 206)
exe 'vert 2resize ' . ((&columns * 103 + 103) / 206)
argglobal
balt ~/workspace/dotfiles/myVimrc/nvim/init.lua
let s:l = 3690 - ((28 * winheight(0) + 28) / 56)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 3690
normal! 0
lcd ~/workspace/brazil/dev-kermit
wincmd w
argglobal
if bufexists(fnamemodify("~/workspace/dotfiles/myVimrc/nvim/lua/addons/smartFileOpening.lua", ":p")) | buffer ~/workspace/dotfiles/myVimrc/nvim/lua/addons/smartFileOpening.lua | else | edit ~/workspace/dotfiles/myVimrc/nvim/lua/addons/smartFileOpening.lua | endif
if &buftype ==# 'terminal'
  silent file ~/workspace/dotfiles/myVimrc/nvim/lua/addons/smartFileOpening.lua
endif
balt ~/workspace/dotfiles/myVimrc/nvim/init.lua
let s:l = 25 - ((24 * winheight(0) + 28) / 57)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 25
normal! 07|
lcd ~/workspace/dotfiles/myVimrc
wincmd w
2wincmd w
exe 'vert 1resize ' . ((&columns * 102 + 103) / 206)
exe 'vert 2resize ' . ((&columns * 103 + 103) / 206)
tabnext 1
if exists('s:wipebuf') && len(win_findbuf(s:wipebuf)) == 0 && getbufvar(s:wipebuf, '&buftype') isnot# 'terminal'
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20
let &shortmess = s:shortmess_save
let &winminheight = s:save_winminheight
let &winminwidth = s:save_winminwidth
let s:sx = expand("<sfile>:p:r")."x.vim"
if filereadable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &g:so = s:so_save | let &g:siso = s:siso_save
set hlsearch
nohlsearch
let g:this_session = v:this_session
let g:this_obsession = v:this_session
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
