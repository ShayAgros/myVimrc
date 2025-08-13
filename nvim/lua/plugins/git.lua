return {
    {
        'tpope/vim-fugitive',
        config = function()
            vim.keymap.set("n", "<space>gs", ":topleft Gvdiffsplit HEAD~1<CR>", { silent = true })
            vim.keymap.set("n", "<space>gb", ":Git blame<CR>", { silent = true })

            local git_au = vim.api.nvim_create_augroup("gitAU", {})
            -- Make K display the commit under cursor when in git rebase
            vim.api.nvim_create_autocmd({ "FileType" }, {
                group = git_au,
                pattern = "gitrebase",
                callback = function()
                    vim.keymap.set("n", "K", function()
                        local current_hash = vim.fn.expand("<cword>")

                        vim.cmd(string.format("G show --stat=80 -p %s", current_hash))
                    end)
                end
            })
        end
    },
    {
        'sindrets/diffview.nvim'
    }

}
