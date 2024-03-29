""" Neovim LSP configurations

if !has('nvim-0.5.0')
	finish
endif

" LSP configurations
Plug 'neovim/nvim-lspconfig'

Plug 'RishabhRD/popfix'
Plug 'RishabhRD/nvim-lsputils'
" Should allow seamless integration with tag subsystem
"Plug 'weilbith/nvim-lsp-smag'

" Display a status message when indexing code
Plug 'j-hui/fidget.nvim'

Plug 'ray-x/lsp_signature.nvim'

let g:lsp_log_verbose = 1
let g:lsp_log_file = '/tmp/lsp.log'

lua << EOF
local custom_lsp_attach = function(client)
	vim.api.nvim_buf_set_keymap(0, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', {noremap = true})
    -- assume that we're using utf-8 files. This might be wrong for some future file
	vim.api.nvim_buf_set_keymap(0, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', {noremap = true})
	vim.api.nvim_buf_set_keymap(0, 'n', '<leader>gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', {noremap = true})
	vim.api.nvim_buf_set_keymap(0, 'n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', {noremap = true})
	vim.api.nvim_buf_set_keymap(0, 'n', 'glr', '<cmd>lua vim.lsp.buf.rename()<CR>', {noremap = true})
	vim.api.nvim_buf_set_keymap(0, 'n', 'gld', '<cmd>lua vim.diagnostic.hide()<CR>', {noremap = true})
	vim.api.nvim_buf_set_keymap(0, 'n', 'gla', '<cmd>lua vim.lsp.buf.code_action()<CR>', {noremap = true})

	vim.api.nvim_buf_set_keymap(0, 'n', 'gln', '<cmd>lua vim.diagnostic.goto_next()<CR>', {noremap = true})
	vim.api.nvim_buf_set_keymap(0, 'n', 'glp', '<cmd>lua vim.diagnostic.goto_prev()<CR>', {noremap = true})

	vim.api.nvim_buf_set_option(0, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
	vim.api.nvim_buf_set_option(0, 'formatexpr', 'v:lua.vim.lsp.formatexpr()')
end

local function configure_lsp_utils()
	vim.lsp.handlers['textDocument/codeAction'] = require'lsputil.codeAction'.code_action_handler
    vim.lsp.handlers['textDocument/references'] = require'lsputil.locations'.references_handler
    vim.lsp.handlers['textDocument/definition'] = require'lsputil.locations'.definition_handler
    vim.lsp.handlers['textDocument/declaration'] = require'lsputil.locations'.declaration_handler
    vim.lsp.handlers['textDocument/typeDefinition'] = require'lsputil.locations'.typeDefinition_handler
    vim.lsp.handlers['textDocument/implementation'] = require'lsputil.locations'.implementation_handler
    vim.lsp.handlers['textDocument/documentSymbol'] = require'lsputil.symbols'.document_handler
    vim.lsp.handlers['workspace/symbol'] = require'lsputil.symbols'.workspace_handler
end

function setup_lsp_clients()

	local success, lspconfig = pcall(require, 'lspconfig')

	if not success then
		return
	end

	local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())

	lspconfig.clangd.setup{

		on_attach = function(client)

--			vim.lsp.handlers["textDocument/publishDiagnostics"] = function() end

			custom_lsp_attach(client, bufnr)
            client.offset_encoding = "utf-8"

			local success, lsp_signature = pcall(require, 'lsp_signature')
			if success then
				lsp_signature.on_attach({hint_enable = true,
										 floating_window = false,
										 hint_prefix = "💡 ",}, bufnr)
			end
		end,
		cmd = { "clangd", "--background-index", "-j", "4", "--log=info" },
		capabilities = capabilities
	}

--	require'lspconfig'.pylsp.setup{
    local util = require 'lspconfig.util'
    require 'lspconfig'.pyright.setup {
		on_attach = function(client)
--			vim.lsp.handlers["textDocument/publishDiagnostics"] = function() end
			custom_lsp_attach(client)
		end,
		capabilities = capabilities,

        root_dir = util.root_pattern(".git")
	}

	require'lspconfig'.bashls.setup{
		on_attach = function(client)
	--		vim.lsp.handlers["textDocument/publishDiagnostics"] = function() end
			custom_lsp_attach(client)
		end,
		capabilities = capabilities,
	}

	local sumneko_binary_path = vim.fn.exepath('lua-language-server')
	local sumneko_root_path = vim.fn.fnamemodify(sumneko_binary_path, ':h:h')
	local runtime_path = vim.split(package.path, ';')
	require'lspconfig'.lua_ls.setup {
		cmd = {sumneko_binary_path, "-E", sumneko_root_path .. "/main.lua"};
		on_attach = function(client)
			custom_lsp_attach(client)
		end,
		capabilities = capabilities,
		settings = {
			Lua = {
				runtime = {
					-- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
					version = 'LuaJIT',
					path = runtime_path,
				},
				diagnostics = {
					-- Get the language server to recognize the `vim` global
					globals = {'vim'},
				},
				workspace = {
  				-- Make the server aware of Neovim runtime files
					library = vim.api.nvim_get_runtime_file("", true),
				},
				telemetry = {
					enable = false,
				},
			}
		}
	}

	require'lspconfig'.tsserver.setup{
		on_attach = function(client)
			custom_lsp_attach(client)
		end,
	}

	configure_lsp_utils()
end

function configure_fidget()
	local success, fidget = pcall(require, 'fidget')

	if not success then
		return
	end

	fidget.setup{}
end

function configure_lsp_signature()
	local success, lsp_signature = pcall(require, 'lsp_signature')

	if not success then
		return
	end

	lsp_signature.setup{
		floating_window = false
	}
end

vim.cmd([[
	augroup NvimLspAU
	au!
	autocmd user DoAfterConfigs ++nested lua setup_lsp_clients()
	autocmd User DoAfterConfigs ++nested lua configure_fidget()
	augroup END
]])
--vim.api.nvim_command("augroup NvimLspAU")
--vim.api.nvim_command("au!")
--vim.api.nvim_command("autocmd user DoAfterConfigs ++nested lua setup_lsp_clients()")
-- display a progress bar when running LSP
--vim.api.nvim_command('autocmd User DoAfterConfigs ++nested lua configure_fidget()')
--vim.api.nvim_command("augroup END")
EOF
