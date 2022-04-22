""" Extension of f<char> built-in command. Allows to press f several times to
""" get to the character you want at the current line

" We use lightspeed plugin for neovim 0.5.0 or newer which
" covers the functionality of this plugin
if has('nvim-0.5.0')
	finish
end

Plug 'rhysd/clever-f.vim'

let g:clever_f_across_no_line = 1
let g:clever_f_fix_key_direction = 1
let g:clever_f_timeout_ms = 3000
