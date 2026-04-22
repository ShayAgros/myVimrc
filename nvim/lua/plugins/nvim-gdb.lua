return {
    'sakhnik/nvim-gdb',
    build = ':!./install.sh',
    config = function()
        vim.api.nvim_create_user_command('UdbStart', function()
            local undo_file = vim.fn.input({
                prompt = 'Path to .undo file: ',
                default = vim.fn.getcwd() .. '/',
                completion = 'file',
            })
            if undo_file ~= '' then
                vim.cmd('GdbStart udb ' .. vim.fn.fnameescape(undo_file))
            end
        end, {})
    end,
}
