
-- Jump to the last position in a file {{{
local general_au = vim.api.nvim_create_augroup("generalAU", {})
vim.api.nvim_create_autocmd({ "BufReadPost" }, {
    group = general_au,
    callback = function()
        local last_visited_line = vim.fn.line('\'"')
        local file_last_line = vim.fn.line('$')

        if last_visited_line >= 1 and last_visited_line < file_last_line then
            vim.fn.execute("normal! g`\"")
        end
    end,
})
-- }}}
