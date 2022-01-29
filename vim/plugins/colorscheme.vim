" Configure Colorscheme (currently nightfox.nvim)

Plug 'EdenEast/nightfox.nvim'

let g:nightfox_color_delimiter = "red"
let g:nightfox_italic_comments = 1

" Set the colorscheme
function! s:HasColorscheme(name) abort
    let pat = 'colors/'.a:name.'.vim'
    return !empty(globpath(&rtp, pat))
endfunction

function! s:SetColorscheme(colorscheme_name, default) abort
	" set colorscheme
	if s:HasColorscheme(a:colorscheme_name)
		exec "colorscheme " . a:colorscheme_name
	else
		echom "Requested colorscheme (" . a:colorscheme_name . ") doesn't exist"
		exec "colorscheme " . a:default
	endif
endfunction

augroup ColorSchemeSet
	au!
	autocmd User DoAfterConfigs ++nested call s:SetColorscheme("nightfox", "desert")
augroup END
