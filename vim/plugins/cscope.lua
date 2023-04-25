-- Configuration file for cscope configuration
-- Starting neovim 0.9 cscope is no longer built it and so needs to be
-- installed via plugin

local Plug = vim.fn['plug#']

if vim.fn.has('nvim-0-9') then
  Plug 'dhananjaylatkar/cscope_maps.nvim'
end

local function configure_cscope()
	local success, cscope = pcall(require, 'cscope_maps')
	if not success then
		return
	end

  cscope.setup{}
  --if vim.fn.has('nvim-0-9') then
    --vim.api.nvim_create_user_command('cscope', 'echo "hello World!', {})
  --end
end

local cscope_au = vim.api.nvim_create_augroup("cscopeAU", {})
vim.api.nvim_create_autocmd({ "User" }, {
  pattern = { "DoAfterConfigs" },
  group = cscope_au,
  callback = configure_cscope
})
