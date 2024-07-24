-- Make jk exit insert and terminal mode
vim.keymap.set("i", "jk", "<esc>")
vim.keymap.set("c", "jk", "<c-c>")

-- Make enter start a new line in normal mode
vim.keymap.set("n", "<cr>", "o<esc>")

-- remove highlighted words
vim.keymap.set("n", "<leader><leader>", ":noh<cr>", { silent = true })

-- Yank into clipboard
vim.keymap.set("n", "Y", '"+y')
vim.keymap.set("v", "Y", '"+y')

-- Move right when in insert mode
vim.keymap.set("i", "<C-f>", "<right>")

-- vimrc edits {{{
-- open init.lua
vim.keymap.set("n", "<localleader>ev", string.format(":bo vsplit %s<cr>", vim.env.MYVIMRC), { silent = true })
--  source .vimrc
vim.keymap.set("n", "<localleader>vv", string.format(":source %s<cr>", vim.env.MYVIMRC), { silent = true })
-- }}}

-- Stop putting everything into the copy space {{{
vim.keymap.set("n", "D", 'd')
vim.keymap.set("n", "d", '"_d')
vim.keymap.set("x", "D", 'd')
vim.keymap.set("x", "d", '"_d')
vim.keymap.set("n", "x", '"_x')
vim.keymap.set("n", "c", '"_c')
-- }}}

-- Tab movement {{{
vim.keymap.set("n", "<C-L>", ":tabnext<CR>", { silent = true })
vim.keymap.set("n", "<C-H>", ":tabprevious<CR>", { silent = true })
vim.keymap.set("n", "W", ":tabmove +1<CR>", { silent = true })
vim.keymap.set("n", "Q", ":tabmove -1<CR>", { silent = true })

vim.keymap.set("n", "<leader>t", ":tabnew<CR>", { silent = true })
-- }}}

-- Override default search behavior {{{
local function highlight_word()
    local word = vim.fn.expand("<cword>")

    vim.fn.setreg("/", word)
    vim.opt.hlsearch = true

    vim.fn.histadd("searc", word)
end

vim.keymap.set("n", "*", function () highlight_word() end)
-- }}}

-- Move screen horizontally {{{
vim.keymap.set("n", "L", "3zl")
vim.keymap.set("n", "H", "3zh")
-- }}}

-- quickfix {{{
local function toggle_quickfixlist()
    local buffer_list = vim.fn.tabpagebuflist()
    local qf_win_found = false

    for _, buf_nr in ipairs(buffer_list) do
        if vim.fn.getbufvar(buf_nr, "&buftype") == "quickfix" then
            qf_win_found = true
            break
        end
    end

    if not qf_win_found then
        vim.cmd("botright copen")
        vim.cmd("wincmd p")
    else
        vim.cmd("cclose")
    end
end

vim.keymap.set("n", "<M-j>", ":cn<cr>", { silent = true })
vim.keymap.set("n", "<M-k>", ":cp<cr>", { silent = true })
vim.keymap.set("n", "<M-f>", ":cf<cr>", { silent = true })
vim.keymap.set("n", "<M-q>", function() toggle_quickfixlist() end)
-- }}}
