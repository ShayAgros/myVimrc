-- Display tabs as T-
vim.opt_local.list = true
vim.opt_local.listchars = "tab:T-"

-- every tab is 8 spaces
vim.opt_local.shiftwidth=8
-- when autoindenting, use 8 spaces
vim.opt_local.tabstop=8
vim.opt_local.expandtab = false

-- use C indentation
vim.opt_local.cindent = true
-- How to format the indentation:
--      c - autowrap comments using 'textwidth'
--      r - automatically insert the current comment leader after
--          hitting <Enter>
--      o - automatically insert the current comment leader after hitting
--          'o' or 'O' in normal mode.
--      q - allow formatting of comments using gq
--      l - Long lines are not broken in insert mode: When a line was
--          longer than 'textwidth' when the insert command started, Vim does
--          not automatically format it
vim.opt_local.formatoptions="croql"

-- In multiline argument list, start the next line right under the first argument
-- in previous line
vim.opt_local.cinoptions = "(0"
