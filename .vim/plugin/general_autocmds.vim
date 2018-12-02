
" When create parent directory when saving a file
autocmd BufWritePre *
	\ if !isdirectory(expand("<afile>:p:h")) |
		\ call mkdir(expand("<afile>:p:h"), "p") |
	\ endif



