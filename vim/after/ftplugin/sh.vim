function! s:exec_in_terminal(cmd)
    let l:term_buf_list = filter(map(getbufinfo(), 'v:val.bufnr'), 'getbufvar(v:val, "&buftype") is# "terminal"')

    if empty(term_buf_list)
        if has('nvim')
            exec winwidth(0)/3 . "vsplit + term://zsh | wincmd p"
        else
        endif

        let l:term_buf_list = filter(map(getbufinfo(), 'v:val.bufnr'), 'getbufvar(v:val, "&buftype") is# "terminal"')
        let l:term_bufname = bufname(term_buf_list[0])

        call setbufvar(term_buf_list[0], "&autoread", 1)
    else
        let l:term_bufname = bufname(term_buf_list[0])
        " We check if the terminal is already in this tab, and if not, open it
        if index(tabpagebuflist(), term_buf_list[0]) == -1
            exec winwidth(0)/3 . "vsplit " . term_bufname . " | wincmd p"
        endif

        " TODO: the bufwinid just returns the first window id in which
        " the buffer appears. This doesn't necessarilly means the window the
        " user sees at the moment.
        " You can use getwininfo() command to extract the tab number of each
        " such window and match to the one of the current window (which is equal
        " to tabpagenr()). This shouldn't be too difficult but you've spend
        " quite enough time on it already so drop it
        let l:term_winid = bufwinid(term_bufname)
        call win_execute(term_winid, "normal! G")
    endif

    let l:terminal_job_id = getbufvar(term_buf_list[0], "terminal_job_id")

    call chansend(terminal_job_id, a:cmd . "\<cr>")
endfunction

function! RunBashProgram()
    let l:cfilename = expand('%')

    call s:exec_in_terminal(cfilename)
endfunction

nnoremap <silent> <buffer> <space>c :call RunBashProgram()<cr>
