if vim.b.current_syntax then
  return
end

vim.cmd([[
syn match csdLogError "ERRO/3"
syn match csdLogGlobalDiag "global diag:"
syn match csdLogFailover "CSD_SN_NETWORK\s\+FAILOVER" contains=csdLogFailoverKeyword
syn match csdLogFailoverKeyword "FAILOVER" contained
hi def link csdLogError ErrorMsg
hi def link csdLogGlobalDiag Directory
hi def link csdLogFailoverKeyword ErrorMsg
]])

vim.b.current_syntax = "csd_log"
