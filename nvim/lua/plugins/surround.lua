return {
    'kylechui/nvim-surround',
    config = function()
        require("nvim-surround").setup({})
        -- v4+ keymaps are configured separately, not in setup
        vim.keymap.set("v", "<leader>S", "<Plug>(nvim-surround-visual)", { desc = "Surround visual selection" })
    end,
    lazy = false,
}
