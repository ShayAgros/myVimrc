-- plugin manager for installing LSP servers

-- Taken from https://dev.to/vonheikemen/neovim-using-vim-plug-in-lua-3oom
local Plug = vim.fn['plug#']

Plug 'williamboman/mason.nvim'
Plug 'williamboman/mason-lspconfig.nvim'

local function configure_mason()
	local success, mason = pcall(require, 'mason')

	if not success then
		return
	end

  mason.setup()

  require("mason-lspconfig").setup()
end

local mason_au = vim.api.nvim_create_augroup("masonAU", {})
vim.api.nvim_create_autocmd({ "User" }, {
  pattern = { "DoAfterConfigs" },
  group = mason_au,
  callback = configure_mason
})
