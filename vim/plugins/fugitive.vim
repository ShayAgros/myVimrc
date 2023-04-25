""" Provides great git integration through vim. Most notablly the :Gdiff HEAD~1
""" capability which allows to review patches

if v:version < 730 && !has('nvim')
	finish
endif

Plug 'tpope/vim-fugitive'

nnoremap <silent> <space>gs :topleft Gvdiffsplit HEAD~1<cr>
nnoremap <silent> <space>gb :Git blame<cr>
