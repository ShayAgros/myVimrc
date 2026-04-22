function custom_previous_function()
    -- Check if there's an active LSP client for the current buffer
    local has_lsp = false
    for _, client in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
        has_lsp = true
        break
    end

    if has_lsp then
        -- Your LSP-based function
        local line_num = vim.api.nvim_win_get_cursor(0)[1] - 1
        vim.lsp.buf_request(0, 'textDocument/documentSymbol', {
            textDocument = vim.lsp.util.make_text_document_params()
        }, function(err, result, ctx, config)
                if err then
                    print("Error: " .. vim.inspect(err))
                    return
                end
                if result then
                    local current_line = line_num
                    local target_line = 0
                    -- Find the closest previous symbol
                    for _, symbol in ipairs(result) do
                        if symbol.range and 
                            symbol.range.start.line < current_line and 
                            symbol.range.start.line > target_line then
                            target_line = symbol.range.start.line
                        end
                    end
                    if target_line > 0 then
                        -- Add current position to jump list before moving
                        vim.cmd("normal! m'")
                        vim.api.nvim_win_set_cursor(0, {target_line + 1, 0})
                    end
                end
            end)
    else
        -- Execute the default [[ behavior
        vim.cmd("normal! [[")
    end
end

vim.api.nvim_buf_set_keymap(0, 'n', '[[', 
    '<cmd>lua custom_previous_function()<CR>', 
    {noremap = true, silent = true}
)
