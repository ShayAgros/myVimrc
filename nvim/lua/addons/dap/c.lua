local ok, dap = pcall(require, 'dap')
if not ok then
    return
end

dap.adapters.gdb = {
    id = 'gdb',
    type = 'executable',
    command = 'gdb',
    args = { '--quiet', '--interpreter=dap' },
}

dap.adapters.udb = function(callback, config)
    callback({
        type = 'pipe',
        pipe = '${pipe}',
        executable = {
            command = 'udb',
            args = { config.program, '--interpreter=mi' },
        }
    })
end

dap.configurations.c = {
    {
        name = 'Run executable (GDB)',
        type = 'gdb',
        request = 'launch',
        program = function()
            local path = vim.fn.input({
                prompt = 'Path to executable: ',
                default = vim.fn.getcwd() .. '/',
                completion = 'file',
            })
            return (path and path ~= '') and path or dap.ABORT
        end,
    },
    {
        name = 'Run executable with arguments (GDB)',
        type = 'gdb',
        request = 'launch',
        program = function()
            local path = vim.fn.input({
                prompt = 'Path to executable: ',
                default = vim.fn.getcwd() .. '/',
                completion = 'file',
            })
            return (path and path ~= '') and path or dap.ABORT
        end,
        args = function()
            local args_str = vim.fn.input({ prompt = 'Arguments: ' })
            return vim.split(args_str, ' +')
        end,
    },
    {
        name = 'Attach to process (GDB)',
        type = 'gdb',
        request = 'attach',
        pid = require('dap.utils').pick_process,
    },
    {
        name = 'Debug undo file (UDB)',
        type = 'udb',
        request = 'launch',
        program = function()
            return vim.fn.input({
                prompt = 'Path to .undo file: ',
                default = vim.fn.getcwd() .. '/',
                completion = 'file',
            })
        end,
    },
}

dap.configurations.cpp = dap.configurations.c
