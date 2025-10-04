" syntax/tmux_scrollback.vim

" Format 1: [CURRENT_WORK_PATH] RET_CODE_OF_PREVIOUS_COMMAND ⭆
" Match the path in square brackets (should be green)
syntax match tmuxScrollbackPath '\[.\{-}\]' contained

" Match return code 0 (should be green)
syntax match tmuxScrollbackReturnCodeZero ' 0 ⭆' contained

" Match non-zero return codes (should be red)
syntax match tmuxScrollbackReturnCodeNonZero ' [1-9][0-9]* ⭆' contained

" Match the entire first prompt format
syntax match tmuxScrollbackPrompt1 '\[.\{-}\] \d\+ ⭆' contains=tmuxScrollbackPath,tmuxScrollbackReturnCodeZero,tmuxScrollbackReturnCodeNonZero

" Format 2: ➜ CUR_DIR_NAME git:(CUR_GIT_BRANCH) or ➜ CUR_DIR_NAME
" Match the arrow symbol
syntax match tmuxScrollbackArrow '➜' contained

" Match the directory name (should be cyan)
syntax match tmuxScrollbackDirName ' \S\+' contained

" Match the git branch info (should be red)
syntax match tmuxScrollbackGitBranch ' git:(\S\+)' contained

" Match the entire second prompt format
syntax match tmuxScrollbackPrompt2 '➜ \S\+\( git:(\S\+)\)\?' contains=tmuxScrollbackArrow,tmuxScrollbackDirName,tmuxScrollbackGitBranch

" Define highlight groups with custom RGB colors
highlight default tmuxScrollbackPath ctermfg=Green guifg=#1E8304
highlight default tmuxScrollbackReturnCodeZero ctermfg=Green guifg=#1E8304
highlight default tmuxScrollbackReturnCodeNonZero ctermfg=Red guifg=#8A0202
highlight default tmuxScrollbackArrow ctermfg=Blue guifg=#0000ff
highlight default tmuxScrollbackDirName ctermfg=Cyan guifg=#00ffff
highlight default tmuxScrollbackGitBranch ctermfg=Red guifg=#8A0202

