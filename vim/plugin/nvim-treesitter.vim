"" This initializes all TreeSitter related functionality in neovim

if !has('nvim-0.5.0')
	finish
endif

Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'nvim-treesitter/nvim-treesitter-textobjects'
Plug 'nvim-treesitter/playground'

lua <<EOF

function copy_table(original_table)
	new_table = {}

	for i, v in ipairs(original_table) do
		new_table[i] = v
	end

	return new_table
end

local function print_children_for_decendants(indentation, node, decendants)
	local ts_utils = require'nvim-treesitter.ts_utils'

	for _, child in ipairs(ts_utils.get_named_children(node)) do
		print(indentation.. child:type().. "( " .. ts_utils.get_node_text(child, 0)[1] .. " )")
		if #decendants > 0 then
			if child:type() == decendants[1] then
				new_table = copy_table(decendants)
				table.remove(new_table, 1)
				print_children_for_decendants(indentation .. "    ", child, new_table)
			end
		end
	end
end

local function get_identifiers(node)
end

function get_function_parameters()
	local parsers = require'nvim-treesitter.parsers'
	local ts_utils = require'nvim-treesitter.ts_utils'

	if not parsers.has_parser() then 
		print("err: no treesitter parser")
		return
	end

	local query_str = [[
	(parameter_declaration
		declarator : (identifier) @val)
	]]
	local query = vim.treesitter.query.parse_query('c', query_str)

	local current_node = ts_utils.get_node_at_cursor()
	if not current_node then return "" end

	while current_node do

		for _, child in ipairs(ts_utils.get_named_children(current_node)) do
			if child:type() == "function_declarator" then
				print_children_for_decendants("        ", child, {"parameter_list", "parameter_declaration", "pointer_declarator", "array_declarator"})

				for id, node, metadata in query:iter_captures(child) do
					print(id, node:type(), ts_utils.get_node_text(node, 0)[1])
				end
			end
		end

		current_node = current_node:parent()
	end
end

function list_treesitter()
	local parsers = require'nvim-treesitter.parsers'
	local ts_utils = require'nvim-treesitter.ts_utils'

	if not parsers.has_parser() then 
		print("err: no treesitter parser")
		return
	end

	local current_node = ts_utils.get_node_at_cursor()
	if not current_node then return "" end

	i = 1
	while current_node do
		
		-- print(tostring(i) .. ":" .. current_node:type() .. "( " .. table.concat(ts_utils.get_node_text(current_node, 0), "!") .. ")")
		print(tostring(i) .. ":" .. current_node:type() .. "( " .. ts_utils.get_node_text(current_node, 0)[1] .. " )")
		for _, child in ipairs(ts_utils.get_named_children(current_node)) do
			print("    " .. child:type().. "( " .. ts_utils.get_node_text(child, 0)[1] .. " )")

			if child:type() == "function_declarator" then
				print_children_for_decendants("        ", child, {"parameter_list", "parameter_declaration", "pointer_declarator", "array_declarator"})
			end
		end
		
		current_node = current_node:parent()
		i = i + 1
	end
end

function setup_ts()
	local success, ts_configs = pcall(require, 'nvim-treesitter.configs')

	if not success then
		return
	end

	ts_configs.setup {
		highlight = {
		  enable = true,
		  -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
		  -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
		  -- Using this option may slow down your editor, and you may see some duplicate highlights.
		  -- Instead of true it can also be a list of languages
		  additional_vim_regex_highlighting = true,
		},
		incremental_selection = {
		  enable = true,
		  keymaps = {
		    init_selection = "gnn",
		    node_incremental = "grn",
		    scope_incremental = "grc",
		    node_decremental = "grm",
		  },
		},
		indent = {
		  enable = true
		},
		textobjects = {
		move = {
		  	  enable = true,
		  	  set_jumps = true, -- whether to set jumps in the jumplist
		  	  goto_next_start = {
		  	  ["]m"] = "@function.outer",
		  	  ["]]"] = "@class.outer",
		  	  },
		    goto_next_end = {
		    ["]M"] = "@function.outer",
		    ["]["] = "@class.outer",
		    },
		goto_previous_start = {
		["[["] = "@function.outer",
		--			["[["] = "@class.outer",
		},
		  	  goto_previous_end = {
		  	  ["[M"] = "@function.outer",
		  	  ["[]"] = "@class.outer",
		  	  },
		    },
		}
	}
end

vim.api.nvim_command("augroup TSConfig")
vim.api.nvim_command("au!")
vim.api.nvim_command("autocmd User DoAfterConfigs ++nested lua setup_ts()")
vim.api.nvim_command("augroup END")

EOF
