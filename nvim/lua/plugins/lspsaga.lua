return {
    'nvimdev/lspsaga.nvim',
    config = function()
        require('lspsaga').setup({
            -- The lightbulb sign glyph is controlled by ui.code_action (NOT
            -- lightbulb.sign_text — that field doesn't exist / isn't read by
            -- lspsaga's sign_define call).
            --
            -- The real fix for sign-column resize shudder with wide emoji
            -- lives in plugins/snacks.lua (statuscolumn.icon padded by
            -- display width instead of character count), so the classic
            -- lightbulb emoji is safe to use here again.
            ui = {
                code_action = "💡",
            },
        })
    end,
    dependencies = {
        'nvim-treesitter/nvim-treesitter', -- optional
        'nvim-tree/nvim-web-devicons',     -- optional
    }
}
