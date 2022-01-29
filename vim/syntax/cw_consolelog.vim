syntax match CWTimeFrame '[0-9]\+-[0-9]\+-[0-9]\+\s' conceal
syntax match CWTimeFrame '\([0-9]\+:\)\{3\}\s' conceal

syntax match EnaDriverLog '\<ena\>\|\<testing_ena\>'
syntax match PcieBDF '\([0-9]\+:\)\{2\}[0-9]\+\.[0-9]'
syntax match KerenelTS '\[\s*[0-9]\+\.[0-9]\+\]'
syntax match ResetString 'Trigger reset is on'
syntax match EnaInitMessage 'Elastic Network Adapter (ENA) v[0-9]\+\.[0-9]\+\.[0-9]\+[a-z]\?'

hi def link CWTimeFrame		Comment
hi def link KerenelTS		Comment

hi def link EnaDriverLog	Macro
hi def link EnaInitMessage	String
hi def link ResetString		Error
"hi def link WarningString	Error
"hi def link CriticalIssues	Error
