return {
    'kylechui/nvim-surround',
    config = function()
        local surround = require("nvim-surround")

        surround.setup {
            keymaps = {
                visual = "<leader>S"
            }
        }
    end,
    lazy = false,
}
