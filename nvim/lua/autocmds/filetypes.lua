-- Set filetype solely by file name / pattern {{{
local namesToTypes = {
    ["*.txt"] = "markdown",
    ["nx.log*"] = "nx_log",
    ["messages-*"] = "gp-messages",
    ["consolelog-*"] = "consoleLog",
    ["*.tmux_scrollback"] = "tmux_scrollback"
}

local ft_au = vim.api.nvim_create_augroup("ftAU", {})
for filename, filetype in pairs(namesToTypes) do
    vim.api.nvim_create_autocmd( { "BufRead","BufNewFile" }, {
        group = ft_au,
        pattern = filename,
        callback = function () vim.opt_local.filetype = filetype end
    } )
end

-- }}}

-- Add MTR include files to the path {{{
local function maybe_set_mtr_ft()
    local dir_name = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
    local git_root = vim.fn.system('git -C ' .. dir_name .. ' rev-parse --show-toplevel 2>/dev/null'):gsub('\n$', '')

    if vim.v.shell_error == 0 then
        local mysql_test_path = git_root .. '/mysql-test'
        -- Check if the directory exists
        if vim.fn.isdirectory(mysql_test_path) == 1 then
            vim.opt.path:append(mysql_test_path)
        end
    end
end

vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
    pattern = {"*.inc", "*.test", "*.result"},
    callback = maybe_set_mtr_ft
})
-- }}}
