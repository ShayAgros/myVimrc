" syntax file for dmesg log

syntax match DmesgTS '^\[[^\]]\+\]' conceal
syntax match EnaDriverLog '\<ena:\?\>'

hi def link DmesgTS	Comment

hi def link EnaDriverLog	Macro

" vim: set filetype=vim:
