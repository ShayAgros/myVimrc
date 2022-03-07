""" Neovim LSP configurations

if !has('nvim-0.5.0')
	finish
endif

" LSP configurations
Plug 'neovim/nvim-lspconfig'
" Should allow seamless integration with tag subsystem
"Plug 'weilbith/nvim-lsp-smag'

" Display a status message when indexing code
Plug 'j-hui/fidget.nvim'

let g:lsp_log_verbose = 1
let g:lsp_log_file = '/tmp/lsp.log'

lua << EOF
local custom_lsp_attach = function(client)
	local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())

	vim.api.nvim_buf_set_keymap(0, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', {noremap = true})

	vim.api.nvim_buf_set_keymap(0, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', {noremap = true})
	vim.api.nvim_buf_set_keymap(0, 'n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', {noremap = true})
	vim.api.nvim_buf_set_keymap(0, 'n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', {noremap = true})

	vim.api.nvim_buf_set_option(0, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
	vim.api.nvim_buf_set_option(0, 'formatexpr', 'v:lua.vim.lsp.formatexpr()')
end

function setup_lsp_clients()

	local success, lspconfig = pcall(require, 'lspconfig')

	if not success then
		return
	end

	lspconfig.clangd.setup{

		on_attach = function(client)
			vim.lsp.handlers["textDocument/publishDiagnostics"] = function() end

			custom_lsp_attach(client)
		end,
		cmd = { "clangd", "--background-index", "-j", "4" },
		capabilities = capabilities
	}

	require'lspconfig'.pylsp.setup{
		on_attach = function(client)
			vim.lsp.handlers["textDocument/publishDiagnostics"] = function() end
			custom_lsp_attach(client)
		end,
		capabilities = capabilities,
	}

	require'lspconfig'.bashls.setup{
		on_attach = function(client)
			vim.lsp.handlers["textDocument/publishDiagnostics"] = function() end
			custom_lsp_attach(client)
		end,
		capabilities = capabilities,
	}
end

vim.api.nvim_command("augroup NvimLspAU")
vim.api.nvim_command("au!")
vim.api.nvim_command("autocmd User DoAfterConfigs ++nested lua setup_lsp_clients()")
-- display a progress bar when running LSP
vim.api.nvim_command('autocmd User DoAfterConfigs ++nested lua require"fidget".setup{}')
vim.api.nvim_command("augroup END")
EOF
