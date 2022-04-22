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
	vim.api.nvim_buf_set_keymap(0, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', {noremap = true})

	vim.api.nvim_buf_set_keymap(0, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', {noremap = true})
	vim.api.nvim_buf_set_keymap(0, 'n', '<leader>gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', {noremap = true})
	vim.api.nvim_buf_set_keymap(0, 'n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', {noremap = true})

	vim.api.nvim_buf_set_option(0, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
	vim.api.nvim_buf_set_option(0, 'formatexpr', 'v:lua.vim.lsp.formatexpr()')
end

function setup_lsp_clients()

	local success, lspconfig = pcall(require, 'lspconfig')

	if not success then
		return
	end

	local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())

	lspconfig.clangd.setup{

		on_attach = function(client)
			vim.lsp.handlers["textDocument/publishDiagnostics"] = function() end

			custom_lsp_attach(client)
		end,
		cmd = { "clangd", "--background-index", "-j", "4" },
		capabilities = capabilities
	}

--	require'lspconfig'.pylsp.setup{
    require 'lspconfig'.pyright.setup {
		on_attach = function(client)
			vim.lsp.handlers["textDocument/publishDiagnostics"] = function() end
			custom_lsp_attach(client)
		end,
		capabilities = capabilities,
	}

	require'lspconfig'.bashls.setup{
		on_attach = function(client)
	--		vim.lsp.handlers["textDocument/publishDiagnostics"] = function() end
			custom_lsp_attach(client)
		end,
		capabilities = capabilities,
	}
end

function configure_fidget()
	local success, fidget = pcall(require, 'fidget')

	if not success then
		return
	end

	fidget.setup{}
end

function my_get_symbol_info()
	local buffer_number = vim.api.nvim_get_current_buf()
	local parameter = vim.lsp.util.make_position_params()
	local buffer_clients = vim.lsp.get_active_clients()

	local all_locations = {}

	for _, client in ipairs(buffer_clients) do
		local response = client.request_sync("textDocument/definition", parameter, nil, buffer_number)
		table.insert(all_locations, response.result)
	end

	print("queried " .. tostring(#buffer_clients) .. " clients in buffer number " .. tostring(buffer_number))
	print("there are", #vim.lsp.get_active_clients(), "client in this buffer")
	print(vim.inspect(parameter))

	if #all_locations > 0 then
		print("Got a response")
		print(vim.inspect(all_locations))
	end
end

vim.api.nvim_command("augroup NvimLspAU")
vim.api.nvim_command("au!")
vim.api.nvim_command("autocmd User DoAfterConfigs ++nested lua setup_lsp_clients()")
-- display a progress bar when running LSP
vim.api.nvim_command('autocmd User DoAfterConfigs ++nested lua configure_fidget()')
vim.api.nvim_command("augroup END")
EOF
