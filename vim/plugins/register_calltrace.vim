" An effort to log which functions I pass through when studying code

if !has('nvim-0.5.0')
	finish
endif


lua << EOF

my_call_tree = {}

local function ts_get_current_function()

	local parsers = require'nvim-treesitter.parsers'
	local ts_utils = require'nvim-treesitter.ts_utils'

	if not parsers.has_parser() then 
		print("err: no treesitter parser")
		return nil
	end

	local current_node = ts_utils.get_node_at_cursor()
	if not current_node then return nil end

	local function_name_query_str = [[
	(function_declarator
		declarator : (identifier) @val)
	]]
	local name_query = vim.treesitter.query.parse_query('c', function_name_query_str)

	while current_node do
		if current_node:type() == 'function_definition' then
			break
		end

		current_node = current_node:parent()
	end

	if not current_node then
		return nil
	end

	for id, node, metadata in name_query:iter_captures(current_node) do
		return ts_utils.get_node_text(node, 0)[1]
	end

	return nil
end

function my_current_func_to_add_to_calltree()
--	local current_file = string.gsub(vim.api.nvim_buf_get_name(0), vim.loop.cwd(), '')
	func_name = ts_get_current_function()
	if func_name == nil then
		print("err: unable to parse function name")
		return
	end

	table.insert(my_call_tree, {
		func_name = func_name,
		file_name = vim.api.nvim_buf_get_name(0),
		})

	print("function", func_name .. "(...)", "was added to call tree")
end

function get_func_under_cursor()
	local parsers = require'nvim-treesitter.parsers'
	local ts_utils = require'nvim-treesitter.ts_utils'

	if not parsers.has_parser() then 
		print("err: no treesitter parser")
		return nil
	end

	local current_node = ts_utils.get_node_at_cursor()
	if not current_node then return nil end

	local function_name_query_str = [[
	[
		(call_expression
		function : (identifier) @val)

		(function_declarator
			declarator : (identifier) @val)
		]
	]]
	local name_query = vim.treesitter.query.parse_query('c', function_name_query_str)
	while current_node do
		local ntype = current_node:type()
		if  ntype == 'call_expression' or ntype == 'function_declarator' then
--			print("found")
			break
		end

		current_node = current_node:parent()
	end

	if not current_node then
		return nil
	end

	for id, node, metadata in name_query:iter_captures(current_node) do
		return ts_utils.get_node_text(node, 0)[1]
	end

	return nil
end

function create_org_link_of_current_func()
	local cur_func = get_func_under_cursor()
	if cur_func == nil then
		print("No function under cursor was found")
		return
	end

	file = vim.fn.expand('%:p')
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))

	local org_link = "[[file:" .. file .. "::" .. row .. "][" .. cur_func .. "()" .. "]]"
	
	print(org_link)
	vim.fn.setreg("+", org_link)
--	:let @+=fnamemodify(expand("%"), ":~:.") . "#L" . line(".")<cr>
end

function my_clean_func_calltrace()
	my_call_tree = {}
end

function my_print_func_calltrace()
	print(vim.inspect(my_call_tree))
end

vim.api.nvim_set_keymap("n", "<Space>cmf", ":lua my_current_func_to_add_to_calltree()<CR>", { silent = true })
vim.api.nvim_set_keymap("n", "<Space>cmd", ":lua my_clean_func_calltrace()<CR>", { silent = true })
vim.api.nvim_set_keymap("n", "<Space>cmp", ":lua my_print_func_calltrace()<CR>", { silent = true })
vim.api.nvim_set_keymap("n", "<Space>cre", ":lua create_org_link_of_current_func()<CR>", { silent = true })

EOF
