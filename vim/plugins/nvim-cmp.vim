""" Neovim auto-completion plugin and configurations

if !has('nvim-0.5.0')
	finish
endif

" autocmolete plugins
"
" Already defined in LSP plugin folder as well, but add it here as well just in
" case
Plug 'neovim/nvim-lspconfig'

Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'

" For luasnip users (also duplicated in another folder)
Plug 'L3MON4D3/LuaSnip'
Plug 'saadparwaiz1/cmp_luasnip'

" Options  needed to make lsp-cmp work
" menu: Use a popup menu to show the possible completions
" menuone: make popup for one option as well
" noselect: don't select automatically
set completeopt=menu,menuone,noselect

lua << EOF

local has_words_before = function()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

	function cmpInit()
		local success, cmp = pcall(require, 'cmp')

		if not success then
			return
		end

		local luasnip = require("luasnip")

		cmp.setup({
			snippet = {
			  expand = function(args)
				require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
			  end,
			},
			mapping = cmp.mapping.preset.insert({
			  ['<C-b>'] = cmp.mapping.scroll_docs(-4),
			  ['<C-f>'] = cmp.mapping.scroll_docs(4),
			  ['<C-Space>'] = cmp.mapping.complete(),
			  ['<C-e>'] = cmp.mapping.abort(),
			  ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.

			  ['<C-d>'] = cmp.mapping(function(fallback)
			  		if luasnip.expand_or_jumpable() then
						luasnip.expand_or_jump()
                    elseif cmp.visible() then
                        cmp.select_next_item()
                    elseif has_words_before() then
                        cmp.complete()
					else
						fallback()
					end

			  end, {"i", "s"}),

			  ['<C-s>'] =  cmp.mapping(function(fallback)
				  if cmp.visible() then
					  cmp.select_prev_item()
				  elseif luasnip.jumpable(-1) then
					  luasnip.jump(-1)
				  else
					  fallback()
				  end
			  end, {"i", "s"}),
			}),

			sources = cmp.config.sources(
				{
				  { name = 'nvim_lsp' },
				  { name = 'luasnip' }, -- For luasnip users.
				  { name = 'path' },
				},
				{
				  { name = 'buffer' },
				})
			})

			cmp.setup.cmdline('/', {
				mapping = cmp.mapping.preset.cmdline(),
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
