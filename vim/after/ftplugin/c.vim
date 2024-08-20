" C specific configurations

setlocal comments=sr:/*,mb:*,ex:*/,://

" Don't use syntastic cheks by default
let b:syntastic_mode = "passive"

" don't search in *.patch files
if exists("g:my_telescope_supported") && g:my_telescope_supported == 1
lua << EOF
    ag_additional_args = {"--ignore", "*.patch"}
EOF
endif

"	indentation {{{

setlocal list
setlocal listchars=tab:T-

let s:myfname=expand("%:p")

" CRT project has 4 space tabs (maybe this should be done automatically)
if stridx(s:myfname, "/crt/") >= 0
	" every tab is 8 spaces
	set shiftwidth=4
	" when autoindenting, use 8 spaces
	set tabstop=4
	set expandtab

	" Configure compilation command
    "let b:dispatch="make -C aws-c-io/build"
    "nnoremap <silent> <space>cs :call jobstart("tmux split-window -d -p 20 'cd aws-c-io ; ~/workspace/scripts/send_changed_files.sh -i 1'")<cr>

    " don't search in crt (where I installed the result of building) directory
    if exists("g:my_telescope_supported") && g:my_telescope_supported == 1
lua << EOF
    ag_additional_args = vim.tbl_flatten{ag_additional_args, {"--ignore", "./sdk"}}
EOF
    endif
else
	" every tab is 8 spaces
	set shiftwidth=8
	" when autoindenting, use 8 spaces
	set tabstop=8

	" FIXME: I might be in a directory with a Makefile while the file I'm in
	" isn't. Probably makes sense to check if the current file has anything to
	" do with the Makefile I have in my cwd()
	" If our home directory doesn't have a Makefile, try to compile the file as
	" a standalone executable
	if empty(glob(getcwd() . "/Makefile"))
		let b:dispatch="gcc % -o " . expand("%:r")
	endif
endif

if has('nvim')
lua << EOF
	project_settings = require("project_settings")
	project_settings:configure_c_project()
EOF
endif

" use C indentation
set cindent
set formatoptions=croql

" In multiline argument list, start the next line right under the first argument
" in previous line
set cino=(0
" }}}

"	foldings {{{
" use zf to create manual foldings
setlocal foldmethod=manual
" don't start folded
setlocal foldlevelstart=99 " start folded
"	}}}

"	key bindings {{{
" fold current function
nnoremap <buffer> <leader>' [[v][zf

" open header file if it's in the same folder TODO: change it to be
" more global
nnoremap <buffer> <leader>eh :execute "bo 80vsplit " . expand("%:r") . ".h"<CR>

" delete all trailing spaces (delete spaces)
nnoremap <silent> <buffer> <leader>ds :call DeleteTrailingSpaces()<cr>
"	}}}

"	abbrevations {{{
iab #d #define
iab #i #include
iab #b /********************************************************
iab #l /*------------------------------------------------------*/
"	}}}

" Dirty huck to enable LSP on buffers opened with neovim itself.
" If Neovim starts with C file, the LSP doesn't attach for some reason, so do it
" later
func ShayStartLsp(timer)
	echom "Executing LspStart"
	:LspStart
endfunc

if g:first_init == 0
	if exists(":LspStart")
		let g:first_init = 1
		let timer = timer_start(1000, 'ShayStartLsp')
	endif
endif


" BUGS TO FIX: 1) The new line is unindented
"		2) The search doesn't recognize the letter it's on
"		3) The search is not fo the current line only
function! CCR()
	let last_saved=@@
	let last_searched=@/
	" find current line content
	silent execute "normal! ma?[^ ]\nvy"
	noh
	if @@ ==# '{'
		silent execute "normal! $a\<cr>}\<esc>`aa\<cr>"
	else
		silent execute "normal! $a\<cr>"
	endif
	echo @@
	let @@=last_saved
	let @/=last_searched
endfunction
