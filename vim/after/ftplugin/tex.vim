inoremap <buffer> <C-@> <c-o>:call ToggleHebrew()<cr>
nnoremap <buffer> <C-@> :call ToggleHebrew()<cr>

func! ToggleHebrew()
  if &keymap=="hebrew"
    "set norl
    set keymap=
    inoremap ( (
    inoremap ) )
  else
    "set rl
    set keymap=hebrew
    inoremap ( )
    inoremap ) (
  end
endfunc

setlocal formatoptions=ro
setlocal textwidth=0

set tabstop=4
set shiftwidth=4
