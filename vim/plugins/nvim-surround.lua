-- Similar to VIM surround but for neovim. Surrounds blocks of text with
-- char-pairs (e.g. parenthesis)

local Plug = vim.fn['plug#']

Plug 'kylechui/nvim-surround'

local function configure_nvim_surround()
	local success, surround = pcall(require, 'nvim-surround')
	if not success then
		return
	end

  surround.setup{}
end

local nvim_surround_au = vim.api.nvim_create_augroup("NvimSurroundAU", {})
vim.api.nvim_create_autocmd({ "User" }, {
  pattern = { "DoAfterConfigs" },
  group = nvim_surround_au,
  callback = configure_nvim_surround
})
