"" Should make it easier to navigate between multiple buffers

if !has('nvim-0.5.0')
	finish
endif

Plug 'nvim-lua/plenary.nvim'
Plug 'ThePrimeagen/harpoon'
            
lua << EOF
function setup_harpoon()
	local success, harpoon = pcall(require, 'harpoon')

	if not success then
		return
	end

    local telescope
    success, telescope = pcall(require, 'telescope')
    if success then
        vim.api.nvim_set_keymap("n", "<Space>hl", ":Telescope harpoon marks<CR>", { silent = true })
    end

	vim.api.nvim_set_keymap("n", "<Space>hs", ":lua require('harpoon.ui').toggle_quick_menu()<CR>", { silent = true })
	vim.api.nvim_set_keymap("n", "<Space>ha", ":lua require('harpoon.mark').add_file()<CR>", { silent = true })
end

vim.api.nvim_command("augroup HarpoonAU")
vim.api.nvim_command("au!")
vim.api.nvim_command("autocmd User DoAfterConfigs ++nested lua setup_harpoon()")
vim.api.nvim_command("augroup END")
EOF
