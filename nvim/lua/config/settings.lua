-- line numbers {{{
-- Show line number
vim.opt.number = true
-- Make them relative
vim.opt.relativenumber= true

-- }}}

-- Don't span long lines into several visual ones
vim.opt.wrap = false


-- backup and swap files {{{
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.cache/nvim/undodir"
vim.opt.undofile = true

-- If this many milliseconds nothing is typed the swap file will be
-- written to disk
vim.opt.updatetime = 50
-- }}}

-- Search {{{
vim.opt.incsearch = true
vim.opt.smartcase = true
vim.opt.ignorecase = true
-- }}}

vim.opt.termguicolors = true

-- Always keep 8 lines from each side of the current symbol
-- for context
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
-- Took it from a config I used. Not sure why this file name is
-- good but let's try it
vim.opt.isfname:append("@-@")

-- Modify the terminal title according to nvim
vim.opt.title = true

-- Display the partial (keybinding) commands you type
-- at lower left size of the screen
vim.opt.showcmd = true

--- Window management {{{
-- make new windows open on the right or on top of
-- the current window
vim.opt.splitbelow = true
vim.opt.splitright = true
-- }}}

-- file and text formatting {{{

-- make backspace delete newlines
vim.opt.backspace = "indent,eol,start"
-- define newLine format
vim.opt.fileformats="unix,dos"

-- set auto formatting
--  t - auto-wrap text using 'textwidth'
--  c - same as t, but with comments 'textwidth'
--  r - create comment leader if pressed return in comment
--  o - same but with 'o' normal command
vim.opt.formatoptions="tcrol"

-- }}}

-- Indentation {{{
-- every tab is 4 spaces by default
vim.opt.shiftwidth = 4
-- when autoindenting, use 4 spaces
vim.opt.tabstop = 4

-- Use spaces over tabs by default
vim.opt.expandtab = true
-- }}}

--  Sessions {{{
--  Save the following when running 'mksession'
--    blank     | empty windows
--    buffers   | hidden and uloaded buffers,not just those
--                in windows
--    curdir    | the current directory
--    tabpages  | all tab pages
--    winsize   | window sizes
vim.opt.sessionoptions="blank,buffers,curdir,tabpages,winsize"
-- }}}
