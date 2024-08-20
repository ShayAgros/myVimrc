local Plug = vim.fn['plug#']

Plug "nvim-lua/plenary.nvim"
Plug "nvim-tree/nvim-web-devicons" -- not strictly required, but recommended
Plug "MunifTanjim/nui.nvim"
Plug "3rd/image.nvim" -- Optional image support in preview window: See `# Preview Mode` for more information

Plug "nvim-neo-tree/neo-tree.nvim"

vim.keymap.set('n', '<F12>', "<cmd> silent Neotree toggle reveal left<cr>", {})
