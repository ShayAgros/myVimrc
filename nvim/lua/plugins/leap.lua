return {
    url = 'https://codeberg.org/andyg/leap.nvim',
    dependencies = {
        'tpope/vim-repeat'
    },
    config = function ()
        vim.keymap.set('n', 's', '<Plug>(leap)')
        vim.keymap.set({'n', 'x', 'o'}, 'S',  '<Plug>(leap-backward)')
    end
}
