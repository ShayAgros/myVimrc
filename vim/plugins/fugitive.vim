""" Provides great git integration through vim. Most notablly the :Gdiff HEAD~1
""" capability which allows to review patches

if v:version < 730 && !has('nvim')
	finish
endif

Plug 'tpope/vim-fugitive'

nnoremap <space>gs :Gdiff HEAD~1<cr>
nnoremap <space>gb :Git blame<cr>
