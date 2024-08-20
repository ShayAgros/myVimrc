require("config.settings")
require("config.keymaps")
require("config.abbrevations")

-- configure the package manager which is called lazy
require("config.lazy")

-- Configure custom plugins I wrote
require("addons.copyWebLink")
require("addons.CWLogsOps")

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
