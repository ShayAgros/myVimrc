require("config.settings")
require("config.keymaps")
require("config.abbrevations")

-- configure the package manager which is called lazy
require("config.lazy")

-- Configure custom plugins I wrote
require("addons.copyWebLink")
require("addons.CWLogsOps")

-- Instance configuration
require ("addons.instance_sync")

require ("addons.smartFileOpening")

local termfeatures = vim.g.termfeatures or {}
termfeatures.osc52 = false
vim.g.termfeatures = termfeatures
vim.g.clipboard = 'osc52'

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

-- Map file extentions to filetypes
local namesToTypes = {
    ["*.txt"] = "markdown",
    ["nx.log*"] = "nx_log",
    ["messages-*"] = "gp-messages",
    ["consolelog-*"] = "consoleLog",
}

local ft_au = vim.api.nvim_create_augroup("ftAU", {})
for filename, filetype in pairs(namesToTypes) do
    vim.api.nvim_create_autocmd( { "BufRead","BufNewFile" }, {
        group = ft_au,
        pattern = filename,
        callback = function () vim.opt_local.filetype = filetype end
    } )
end

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
    callback = function () maybe_change_git_project() end
} )

-- Add MTR include files to the path
vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
    pattern = {"*.inc", "*.test", "*.result"},
    callback = function()
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
})

-- vim.opt.undofile = true

-- Add this to transform long paths
-- vim.api.nvim_create_autocmd('BufWritePre', {
--   callback = function()
--     local path = vim.fn.expand('%:p')
--     -- Replace everything up to 'patches' with 'PATCHES'
--     local shortened = path:gsub('.*/patches/', 'PATCHES/'):gsub("/","%%")
--
--     print("new file name is " .. shortened)
--     -- vim.fn.wundo(shortened)
--
--     -- vim.cmd("wundo " .. shortened)
--     -- vim.opt.undofile = true
--     vim.bo.undofile = false
--     -- vim.b.undofile_name = shortened
--   end
-- })
