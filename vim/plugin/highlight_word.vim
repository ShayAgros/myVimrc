
"vnoremap <silent> <C-*> :<c-u>call <SID>Highlight_word(visualmode())<cr>

function! Highlight_word(word)
	echo a:word
	if hlexists("WordHighlight")
		syntax clear WordHighlight
	endif
	execute "syntax keyword WordHighlight " . a:word . " contained"
	highlight WordHighlightRed term=standout ctermfg=14 guifg=Red
	highlight def link WordHighlight WordHighlightRed
endfunction
