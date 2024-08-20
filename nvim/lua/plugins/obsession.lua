return {
    'tpope/vim-obsession',
    config = function()
        vim.keymap.set("n", "<leader>os", ":Obsession!<cr>", { silent = true })
    end
}
