" Configurations for the file project info file

" Find the character range between two spaces for the word under cursor
function! s:FindWordRange()
	let current_line = getline(".")
	let ix = 0
	let prev_ix = 0
	let current_col = col('.')

	" find start
	let ix = matchend(current_line, '\s\+', ix)
	while ix >= 0 && ix <= current_col
		let prev_ix = ix
		let ix = matchend(current_line, "\s+", ix)
	endwhile

	" find end
	let ix = match(current_line, '\s\+', current_col)
	if ix < 0
		let ix = len(current_line) - 1
	endif
	
	return [prev_ix, ix]
endfunction

function! s:OpenObject()
	let ticket_num = filter(synstack(line('.'), col('.')), 'synIDattr(v:val, "name") == "SimTicket"')
	if !empty(ticket_num)
		let word_range = s:FindWordRange()

		let ticket = getline(".")[word_range[0]:word_range[1]]
		echo "Opening ticket " . ticket
		call jobstart("/usr/bin/sensible-browser https://sim.amazon.com/issues/" . ticket)
	endif
endfunction

nnoremap <silent> <C-o> :call <SID>OpenObject()<cr>
