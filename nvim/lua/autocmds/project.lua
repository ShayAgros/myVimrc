-- Change to git/brazil project directory {{{
local function maybe_change_git_project()
    local file_name = vim.api.nvim_buf_get_name(0)

    -- This should check whether we're in a real
    -- file and not a temp buffer
    local f = io.open(file_name, "r")
    if f then
        f:close()
    else
        return
    end

    local root_dir = vim.fs.root(0, "packageInfo") or vim.fs.root(0, ".git")
    if root_dir then
        vim.cmd("lcd " .. root_dir)
    end

    if vim.fs.root(0, "packageInfo") then
        vim.b.in_brazil = true
    end
end

local gitDir_au = vim.api.nvim_create_augroup("gitDirAU", {})
vim.api.nvim_create_autocmd( { "BufWinEnter" }, {
    group = gitDir_au,
    callback = maybe_change_git_project
    })
-- }}}

-- Set git root path and register {{{
vim.api.nvim_create_autocmd({ "BufEnter" }, {
    group = gitDir_au,
    callback = function()
        vim.b.File_git_path = vim.fs.root(0, ".git")
        vim.fn.setreg('g', vim.b.File_git_path or "")
    end,
})

vim.api.nvim_create_autocmd({ "FocusGained" }, {
    group = gitDir_au,
    callback = function()
        vim.fn.setreg('g', vim.b.File_git_path or "")
    end,
})
-- }}}
