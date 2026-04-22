if vim.b.current_syntax then
  return
end

vim.cmd([[
syn match mysqlErrorWarn "AWS_OSCAR_WARN"
syn match mysqlErrorError "AWS_OSCAR_ERROR"
hi def link mysqlErrorWarn WarningMsg
hi def link mysqlErrorError ErrorMsg
]])

vim.b.current_syntax = "mysql_error_log"
