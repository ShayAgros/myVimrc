-- Neovim LSP configurations

if not vim.fn.has('nvim-0.5.0') then
  do return end
end

-- Taken from https://dev.to/vonheikemen/neovim-using-vim-plug-in-lua-3oom
local Plug = vim.fn['plug#']

-- LSP configurations (pre-configured LSPs)
Plug 'neovim/nvim-lspconfig'

-- Both are needed for extended code actions
--Plug 'RishabhRD/popfix'
--Plug 'RishabhRD/nvim-lsputils'

-- Display a status message when indexing code
Plug 'j-hui/fidget.nvim'

-- Show function signature when you type
Plug 'ray-x/lsp_signature.nvim'

local function configure_lsp_keybindings()
  local lsp_func = function(func) return function() func() end end
  vim.keymap.set('n', 'K', lsp_func(vim.lsp.buf.hover), { buffer = true })
	vim.keymap.set('n', 'gld', lsp_func(vim.lsp.buf.definition), { buffer = true })
	vim.keymap.set('n', 'gli', lsp_func(vim.lsp.buf.implementation), { buffer = true })
	vim.keymap.set('n', 'glr', lsp_func(vim.lsp.buf.references), { buffer = true })
	vim.keymap.set('n', 'glr', lsp_func(vim.lsp.buf.rename), { buffer = true })
	vim.keymap.set('n', 'glt', lsp_func(vim.diagnostic.hide), { buffer = true })
	vim.keymap.set('n', 'gla', lsp_func(vim.lsp.buf.code_action), { buffer = true })
end

local function generic_on_attach()
  configure_lsp_keybindings()

  local success, lsp_signature = pcall(require, 'lsp_signature')
  if success then
    lsp_signature.on_attach({hint_enable = true,
      floating_window = false,
      hint_prefix = "💡 ",})
  end
end

local function setup_c_lsp()
  local lspconfig = require 'lspconfig'

  lspconfig.clangd.setup {
    on_attach = function ()
      generic_on_attach()
      -- Fallback to vim's default tag implementation (ctags) instead of
      -- relying on LSP. I already have a key map for LSP definition, and clangd
      -- is not completely truthful about its ability to find the right
      -- implementation
      vim.bo.tagfunc = ""
    end,
    capabilities = require('cmp_nvim_lsp').default_capabilities(),
  }
end

local function setup_python_lsp()
  local lspconfig = require 'lspconfig'
  local util = require 'lspconfig.util'

  lspconfig.pyright.setup {
    cmd = { "pyright-langserver", "--stdio", "--verbose" },
    on_attach = generic_on_attach,

    capabilities = require('cmp_nvim_lsp').default_capabilities(),
    root_dir = util.root_pattern(".git")
  }
end

local function setup_lua_lsp()
  local lspconfig = require 'lspconfig'
	local sumneko_binary_path = vim.fn.exepath('lua-language-server')
	local sumneko_root_path = vim.fn.fnamemodify(sumneko_binary_path, ':h:h')
	local runtime_path = vim.split(package.path, ';')

  lspconfig.lua_ls.setup {
    cmd = {sumneko_binary_path, "-E", sumneko_root_path .. "/main.lua"};

    on_attach = generic_on_attach,

    capabilities = require('cmp_nvim_lsp').default_capabilities(),

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
end

local function setup_lsps()
	local success, lspconfig = pcall(require, 'lspconfig')
	if not success then
		return
	end

  setup_c_lsp()
  setup_python_lsp()
  setup_lua_lsp()

  -- generic lsp implementation
  for _, server in ipairs({"bashls", "tsserver"}) do
    lspconfig[server].setup {
      on_attach = generic_on_attach,
      capabilities = require('cmp_nvim_lsp').default_capabilities(),
    }
  end

  -- status icon for LSP loading
  local fidget
	success, fidget = pcall(require, 'fidget')
  if success then
    fidget.setup{}
  end

  local lsp_signature
	success, lsp_signature = pcall(require, 'lsp_signature')
  if success then
    lsp_signature.setup{
      floating_window = false
    }
  end

end

local lsp_au = vim.api.nvim_create_augroup("lspAU", {})
vim.api.nvim_create_autocmd({ "User" }, {
  pattern = { "DoAfterConfigs" },
  group = lsp_au,
  callback = setup_lsps,
})
