
" Indentation {{{

" every tab is 4 spaces
set shiftwidth=4 
" when autoindenting, use 4 spaces
set tabstop=4

set expandtab

" }}}

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

" run the code when hitting Space+c
function! RunPythonProgram()
    let l:virt_env_dir = system("echo -n ${VIRTUALENVWRAPPER_HOOK_DIR}")
    let l:project_virt_env = system("echo -n ${VIRTUAL_ENV}")
    let l:cfilename = expand('%')

    if exists("g:python_main_program")
        let l:cfilename = g:python_main_program
    endif

    if empty(virt_env_dir)
        " if it's emty, then we don't have python virtual envs
        " setup
        call s:exec_in_terminal("python3 " . cfilename)
        return
    endif

    if empty(project_virt_env)
        " Try to guess by the project's name
        " TODO: implement
        call s:exec_in_terminal("python3 " . cfilename)
        return
    endif

    let python_exec = l:project_virt_env . "/bin/python3"
    call s:exec_in_terminal(python_exec . " " . cfilename)
endfunction

"call RunPythonProgram()
"call s:exec_in_terminal("sleep 2 ; seq 1 1000")

nnoremap <silent> <buffer> <space>c :call RunPythonProgram()<cr>
