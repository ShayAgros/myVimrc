" Syntax for CloudWatch logs

"syntax match CWTimeFrame
"syntax match Comment '\([0-9]\+-\)\+[0-9]\+\s'
syntax match CWTimeFrame '[0-9]\+-[0-9]\+-[0-9]\+\s' conceal
syntax match CWTimeFrame '\([0-9]\+:\)\{3\}\s' conceal

syntax match VFNum 'vf\[[0-9]\+\]'ms=s+3,me=e-1

syntax match FunctionName ':\s[a-z_]\+:\s'ms=s+2,me=e-2
syntax match ErrorString '\[ENA\]\[ERR\]'

syntax match DirtyReset 'reset_reason_str\[\(NORMAL\|SHUTDOWN\)\@![A-Z_]\+\]'ms=s+17,me=e-1
syntax match DriverVersion 'driver_version[0x[0-9a-f]\+]'ms=s+17,me=e-1

syntax match WarningString '\[ENA\]\[WARN\]'

hi def link CWTimeFrame		Comment
hi def link VFNum			Macro
hi def link FunctionName	String

hi def link ErrorString		Error
hi def link WarningString	Error
hi def link DirtyReset	Error
