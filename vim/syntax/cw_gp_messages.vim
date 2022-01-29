" syntax file for gp-messages CloudWatch log


syntax match CarbonLog '[0-9]\+-[0-9]\+-[0-9]\+\s\([0-9]\+:\)\{3\}\s*(none) \(kern\|user\).[a-z]\+.*'
syntax match RockhopperLog '[0-9]\+-[0-9]\+-[0-9]\+\s\([0-9]\+:\)\{3\}\s*(none) local0.info rockhopper\[[0-9]\+\]:.*'

syntax match LinuxKernelLog 'kern.[a-z]\+ kernel: \[\s*[0-9]\+\.[0-9]\+\].*' contained containedin=CarbonLog
syntax match LinuxUserLog '(none) user.[a-z]\+ [a-zA-Z-\.]\+: .*' contained containedin=CarbonLog

syntax match CWTimeFrameCarbon '[0-9]\+-[0-9]\+-[0-9]\+\s\([0-9]\+:\)\{3\}\s' conceal contained containedin=CarbonLog
syntax match CWTimeFrameRH '[0-9]\+-[0-9]\+-[0-9]\+\s\([0-9]\+:\)\{3\}\s' conceal contained containedin=RockhopperLog

" messages of the form kern.err
"syntax match LinuxKernelErrorLog '\<kern\.err\+\>'ms=s+5 containedin=LinuxKernelErrorLog contained

syntax match EnaDriverLog '\<ena\>' containedin=LinuxKernelLog contained
syntax match AlEthLog '\<al_eth\>' containedin=LinuxKernelLog contained
syntax match PcieBDF '\([0-9]\+:\)\{2\}[0-9]\+\.[0-9]' containedin=LinuxKernelLog contained
syntax match KerenelTS '\[\s*[0-9]\+\.[0-9]\+\]' containedin=LinuxKernelLog contained

syntax match NxclTimeoutRetry 'nxcl_send_request: read timeout'me=e-14 containedin=LinuxUserLog contained 
syntax match NxclTimeoutError 'nxcl_send_request: timeout'me=e-9 containedin=LinuxUserLog contained 

syntax match FunctionName 'CPU\[[0-9]\]:\s[a-z_]\+:\s'ms=s+8,me=e-2 contained containedin=RockhopperLog
syntax match ErrorString '\[ENA\]\[ERR\]' contained containedin=RockhopperLog
syntax match WarningString '\[ENA\]\[WARN\]' contained containedin=RockhopperLog
syntax match VFNum 'vf\[[0-9]\+\]'ms=s+3,me=e-1 contained containedin=RockhopperLog

syntax match CriticalIssues 'user\.crit'

"syntax match Kernel

hi def link CWTimeFrameCarbon	Comment


		"0	    0	    Black
		"1	    4	    DarkBlue
		"2	    2	    DarkGreen
		"3	    6	    DarkCyan
		"4	    1	    DarkRed
		"5	    5	    DarkMagenta
		"6	    3	    Brown, DarkYellow
		"7	    7	    LightGray, LightGrey, Gray, Grey
		"8	    0*	    DarkGray, DarkGrey
		"9	    4*	    Blue, LightBlue
		"10	    2*	    Green, LightGreen
		"11	    6*	    Cyan, LightCyan
		"12	    1*	    Red, LightRed
		"13	    5*	    Magenta, LightMagenta
		"14	    3*	    Yellow, LightYellow
		"15	    7*	    White
highlight CWTimeFrameRH_SYN guifg=DarkGray
"hi CWTimeFrameRH_SYN ctermfg=Red ctermfg=Red
hi def link CWTimeFrameRH CWTimeFrameRH_SYN

hi def link VFNum			Macro
hi def link EnaDriverLog	Macro
hi def link AlEthLog		Macro

"hi PCIE_BDF_SYN		ctermfg=LightGreen
"hi def link PcieBDF PCIE_BDF_SYN

hi def link NxclTimeoutRetry		Special
hi def link NxclTimeoutError		Error

hi def link FunctionName	String
hi def link FunctionName	String
hi def link ErrorString		Error
hi def link WarningString	Error
hi def link CriticalIssues	Error
"hi CriticalIssues cterm=underline
"hi def link LinuxKernelErrorLog	Error
