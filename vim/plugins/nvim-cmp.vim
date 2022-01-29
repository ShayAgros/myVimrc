""" Neovim auto-completion plugin and configurations

if !has('nvim-0.5.0')
	finish
endif

" autocmolete plugins
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'

" Options  needed to make lsp-cmp work
" menu: Use a popup menu to show the possible completions
" menuone: make popup for one option as well
" noselect: don't select automatically
set completeopt=menu,menuone,noselect

lua << EOF
	function cmpInit()
		local cmp = require'cmp'

		cmp.setup({
--			snippet = {
--			  expand = function(args)
--				vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
--			  end,
--			},

			mapping = {
				  ['<C-e>'] = cmp.mapping({
					i = cmp.mapping.abort(),
					c = cmp.mapping.close(),
				  }),
				  ['<C-Space>'] = cmp.mapping.confirm({ select = true }),
				},

			sources = cmp.config.sources(
				{
				  { name = 'nvim_lsp' },
				  { name = 'ultisnips' }, -- For ultisnips users.
				  { name = 'path' },
				},
				{
				  { name = 'buffer' },
				})
			})

			cmp.setup.cmdline('/', {
				sources = {
				  { name = 'buffer' }
				}
			  })
	end

	vim.api.nvim_command("augroup NvimCmpAU")
	vim.api.nvim_command("au!")
	vim.api.nvim_command("autocmd User DoAfterConfigs ++nested lua cmpInit()")
	vim.api.nvim_command("augroup END")
EOF
