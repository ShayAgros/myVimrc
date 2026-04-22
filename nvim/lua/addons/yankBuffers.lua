vim.api.nvim_create_user_command('YankBuffers', function()
  local paths = vim.tbl_filter(function(p) return p ~= '' end, 
    vim.tbl_map(function(b) return vim.api.nvim_buf_get_name(b) end, 
    vim.api.nvim_list_bufs()))
  vim.fn.setreg('+', table.concat(paths, '\n'))
  print('Copied ' .. #paths .. ' buffer paths')
end, {})
