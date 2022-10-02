" Syntax highlight for the project metadata project metadata file

syntax match SimLabel '\<SIM:\s[A-Z]\+-[0-9]\+\>'
syntax match SimTicket '[A-Z]\+-[0-9]\+' contained containedin=SimLabel

highlight SimTicket_SYN guifg=LightYellow
hi def link SimTicket		SimTicket_SYN
