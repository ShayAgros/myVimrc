" syntax file for journalctl log

syntax match JournalTS '^[A-Za-z]\{3\} [0-9]\+ [0-9]\+:[0-9]\+:[0-9]\+ [0-9]\{4\}' conceal

syntax match EnaDriverLog '\<ena:\?\>'

hi def link JournalTS Comment
hi def link EnaDriverLog	Macro

" vim: set filetype=vim:
