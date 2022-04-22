" Configure Colorscheme (currently nightfox.nvim for neovim and )


if has('nvim')
	Plug 'EdenEast/nightfox.nvim'

else
	Plug 'junegunn/seoul256.vim'
endif

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
		echom "Requested colorscheme (" . a:colorscheme_name . ") doesn't exist, falling back to " . a:default
		exec "colorscheme " . a:default
	endif
endfunction

if has('nvim')
	let s:used_colorscheme = "nightfox"
else
	let g:seoul256_background = 236
	let s:used_colorscheme = "seoul256"
endif

augroup ColorSchemeSet
	au!
	autocmd User DoAfterConfigs ++nested call s:SetColorscheme(s:used_colorscheme, "desert")
augroup END
