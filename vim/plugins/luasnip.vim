" Snippet engine that is used with Neovim
" The reason not to use Ultisnip is to have the content aware and dynamic
" snippets

if !has('nvim-0.5.0')
	finish
endif

Plug 'L3MON4D3/LuaSnip'
Plug 'honza/vim-snippets'
Plug 'molleweide/LuaSnip-snippets.nvim'

lua << EOF

function setup_luasnips()
	local success, luasnip = pcall(require, 'luasnip')

	if not success then
		return
	end
	require("luasnip.loaders.from_snipmate").lazy_load()
--	luasnip.snippets = require("luasnip_snippets").load_snippets
    -- located in ~/.vim
--    local success, snippets = pcall(require, 'luasnip_snippets')
--	if not success then
--		print("Failed to find custom snippets")
--	end
	home_dir = vim.env.HOME
	dofile(home_dir .. "/.vim/luasnip_snippets.lua")
end

vim.api.nvim_command("augroup luasnitAU")
vim.api.nvim_command("au!")
vim.api.nvim_command("autocmd User DoAfterConfigs ++nested lua setup_luasnips()")
vim.api.nvim_command("augroup END")

EOF
