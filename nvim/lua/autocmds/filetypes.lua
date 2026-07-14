-- Set filetype solely by file name / pattern {{{
-- Ordered: more specific patterns MUST come after generic ones (last registered wins)
local namesToTypes = {
    { "*.txt",              "markdown" },
    { "bt-*.txt",           "gdb_backtrace" },
    { "nx.log*",            "nx_log" },
    { "messages-*",         "gp-messages" },
    { "consolelog-*",       "consoleLog" },
    { "*.tmux_scrollback",  "tmux_scrollback" },
    { "mysql-error*",       "mysql_error_log" },
    { "grover.*",           "csd_log" },
    { "rds-application.*",  "hm_log" },
}

local ft_au = vim.api.nvim_create_augroup("ftAU", {})
for _, entry in ipairs(namesToTypes) do
    vim.api.nvim_create_autocmd( { "BufRead","BufNewFile" }, {
        group = ft_au,
        pattern = entry[1],
        callback = function () vim.opt_local.filetype = entry[2] end
    } )
end

-- Force latin1 for gdb backtrace dumps {{{
-- These files embed raw memory bytes (e.g. the 0xDE 0xAD 0xBE 0xEF page
-- marker gdb prints when rendering a char* into an InnoDB page). Those bytes
-- are not valid UTF-8, so decoding as UTF-8 desyncs byte/char offsets and
-- breaks syntax highlighting from that line onward. latin1 makes every byte a
-- valid character so offsets stay aligned.
--
-- Must re-read (edit ++enc): fileencoding is decided at read time, before the
-- BufRead filetype autocmd above even runs, so this can't be an ftplugin
-- setting. Buffer-local via `edit ++enc` rather than `set fileencodings`,
-- which is global and would leak latin1 onto every file opened afterwards in
-- the session. The &fenc guard prevents the re-read from looping.
vim.api.nvim_create_autocmd("BufReadPost", {
    group = ft_au,
    pattern = "bt-*.txt",
    callback = function ()
        if vim.bo.fileencoding ~= "latin1" then
            vim.cmd("edit ++enc=latin1")
        end
    end
})
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
