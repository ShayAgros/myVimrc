-- This file contains custom functions for my everyday work

---@class TreeSitterNode

--- Find the first parent TreeSitter node whose type matches the @type
---@param type string
---@return TreeSitterNode | nil
local function find_node_by_type(type)
  local ts_utils = require'nvim-treesitter.ts_utils'

  local current_node = ts_utils.get_node_at_cursor()

  local call_node = nil
  while current_node do
    if current_node:type() == type then
      call_node = current_node
      break
    end

    current_node = current_node:parent()
  end

  return call_node
end

--- Given a TreeSitter node find the names of its arguments
---@param tsnode TreeSitterNode
---@return table args number indexed table or arguments. The first parameter is\
---function's name
local function get_call_expression_arg_names(tsnode)
  local ts_utils = require'nvim-treesitter.ts_utils'

  local arg_ts_query = [[
        (call_expression
          function: (identifier) @func_name
          arguments:
            (argument_list (identifier) @arg))
        ]]
  local arg_query = vim.treesitter.query.parse_query('c', arg_ts_query)
  local func_name = ""
  local call_exp_args = {}

  for id, node, _ in arg_query:iter_captures(tsnode) do
    local capture_name = arg_query.captures[id]
    if capture_name == "func_name" then
      func_name = vim.treesitter.query.get_node_text(node, 0)
    else
      table.insert(call_exp_args, vim.treesitter.query.get_node_text(node, 0))
    end
  end

  --vim.pretty_print({func_name, unpack(call_exp_args)})
  return {func_name, unpack(call_exp_args)}
end

local function get_query_first_match(tsnode, tsquery)
  for _, node, _ in tsquery:iter_captures(tsnode) do
    return node
  end
end

---@alias symbol_pair
---| '"name"' symbol's name
---| '"type"' symbol's type

--- Given a TreeSitter node of a function declarator find the names of its arguments
---@param tsnode TreeSitterNode
---@return symbol_pair symbols
local function get_func_symbols(tsnode)
  local ts_utils = require'nvim-treesitter.ts_utils'
  local decl_query_str = [[
    (declaration
      type: (_) @type
      declarator: (_) @dec)
  ]]
  local decl_query = vim.treesitter.query.parse_query('c', decl_query_str)
  local identifier_query_str = [[
    declarator: (_) @dec
  ]]
  local identifier_query = vim.treesitter.query.parse_query('c', identifier_query_str)

  local symbols = {}
  local i = 0
  -- hash values into a table under {symbol_name, symbol_type} pairs
  for id, node, _ in decl_query:iter_captures(tsnode) do
    local capture_name = decl_query.captures[id]
    local symbol_table_index = math.floor(i / 2) + 1
    local symbol_table_entry = symbols[symbol_table_index] or {}

    if capture_name == "dec" then

      -- if we're initializing the variable on the spot, take only the
      -- declaration part
      if node:type() == "init_declarator" then
        local name_node = node:child(0)
        symbol_table_entry["name"] = vim.treesitter.query.get_node_text(name_node, 0)
      else
        symbol_table_entry["name"] = vim.treesitter.query.get_node_text(node, 0)
      end
      --print(symbol_table_entry["name"])
    else
      symbol_table_entry["type"] = vim.treesitter.query.get_node_text(node, 0)
      --print(symbol_table_entry["type"])
    end

    symbols[symbol_table_index] = symbol_table_entry
    i = i + 1
  end

  for _, value in ipairs(symbols) do
    if value["name"] then
      symbols[value["name"]:gsub("[*&%[%]]", "")] = value
    end
  end

  return symbols
end

--- Add (void) prefix to all functions parameters at the beginning of the
--- function. This is used to suppress "unused symbol" warning
function Void_function_parameters()
  local parsers = require'nvim-treesitter.parsers'
  local ts_utils = require'nvim-treesitter.ts_utils'

  if not parsers.has_parser() then
    print("err: no treesitter parser")
    return
  end

  -- pointers / primitive types
  local function_param_query_str = [[
    (identifier) @val
  ]]

  local params_query = vim.treesitter.query.parse_query('c', function_param_query_str)

  local current_node = ts_utils.get_node_at_cursor()

  while current_node do
    if current_node:type() == "function_definition" then
      break
    end

    current_node = current_node:parent()
  end

  if not current_node then return end

  local body_node = current_node:field("body")[1]
  local declarator_node = current_node:field("declarator")[1]
  local parameters_node = declarator_node:field("parameters")[1]

  local params = {}
  for _, node, _ in params_query:iter_captures(parameters_node) do
    table.insert(params, string.rep(" ", vim.opt.shiftwidth:get()) .. "(void)".. vim.treesitter.query.get_node_text(node, 0) .. ";")
  end

  if #params == 0 then
    print("Couldn't find function params")
    return ""
  end

  local start_row, _, _ = body_node:start()

  start_row = start_row + 1
  vim.api.nvim_buf_set_lines(0, start_row, start_row, 0, params)
end

function My_declare_yank_func()
  local success, parsers = pcall(require, 'nvim-treesitter.parsers')
  if not success then
    print("Telescope plugin isn't installed, ignoring")
    return
  end

  if not parsers.has_parser() then
    print("No TreeSitter parser in this document")
    return
  end

  local call_node = find_node_by_type("call_expression")
  if not call_node then
    return
  end

  local call_exp_args = get_call_expression_arg_names(call_node)
  -- this is an incredible ugly way of doing func_name, func_args = var[1], var[2:]
  -- but I don't know a better way
  local func_name, func_args = call_exp_args[1], {unpack(call_exp_args, 2)}
  local function_node = find_node_by_type("function_definition")
  if not function_node then
    print("Couldn't find containing function. Exiting")
    return
  end

  local func_symbols = get_func_symbols(function_node)

  --vim.pretty_print(func_args)
  --vim.pretty_print(func_symbols)

  -- Now create the function's signature
  local func_sig_str = string.format("static void %s(", func_name)
  for i, arg in ipairs(func_args) do
    if not func_symbols[arg] then
      print("Couldn't find symbol", arg, "in function's context. Aborting")
      return
    end

    local arg_name = func_symbols[arg]["name"]
    local arg_type = func_symbols[arg]["type"]
    -- precede with comma if it's not the first argument
    if i ~= 1 then
      func_sig_str = func_sig_str ..", "
    end
    func_sig_str = func_sig_str .. string.format("%s %s", arg_type, arg_name)
  end
  func_sig_str = func_sig_str .. ")\n{\n}"
  print(func_sig_str)
  vim.fn.setreg('"', func_sig_str)
end

function My_get_nvim_config_file()
  local success, _ = pcall(require, 'telescope')

  if not success then
    print("Telescope plugin isn't installed, ignoring")
    return
  end

  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local make_entry = require "telescope.make_entry"
  local conf = require("telescope.config").values

  -- find ~/.vim ~/.config/nvim -not -path '*/plugged/*' -name '*.vim' -type f,l -follow | sed "s,${HOME}/\(\.vim/\)\?,,"
  local search_command = vim.tbl_flatten {
    "find",
    vim.env.HOME .. "/.vim",
    vim.env.HOME .. "/.config/nvim",
    "-not",
    "-path",
    "*/plugged/*",
    "-regex",
    '.*\\.\\(vim\\|lua\\)',
    "-type",
    "f,l",
    "-follow",
  }

  local opts = {}
  -- remove common part from path
  opts.path_display = function(_, path)
    -- Remove ~/.vim prefix
    local mpath = path:gsub(vim.env.HOME .. "/.vim/", "")
    -- Remove ~/.config prefix
    mpath = mpath:gsub(vim.env.HOME .. "/.config/", "")
    return mpath
  end
  opts.entry_maker = make_entry.gen_from_file(opts)

  pickers.new(opts, {
    prompt_title = "Choose vim config",
    finder = finders.new_oneshot_job(search_command, opts),
    sorter = conf.file_sorter({}),
  }):find()
end

function My_get_tags_in_file()
  local success, _ = pcall(require, 'telescope')

  if not success then
    print("Telescope plugin isn't installed, ignoring")
    return
  end

  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local make_entry = require "telescope.make_entry"
  local previewers = require "telescope.previewers"
  local action_state = require "telescope.actions.state"
  local action_set = require "telescope.actions.set"
  local conf = require("telescope.config").values

  local search_command = vim.tbl_flatten {
    vim.env.HOME .. "/workspace/Software/ctags/ctags-p5.9.20210307.0/ctags",
    "-f",
    "-",
    "--kinds-c=f",
    vim.api.nvim_buf_get_name(0)
  }
  vim.pretty_print(search_command)

  local opts = {
    bufnr = 0,
    path_display = "hidden",
  }
  opts.entry_maker = make_entry.gen_from_ctags(opts)

  pickers.new(opts, {
    prompt_title = "Local tags",
    finder = finders.new_oneshot_job(search_command, opts),
    sorter = conf.generic_sorter(opts),
    previewer = previewers.ctags.new(opts),
    attach_mappings = function()
      action_set.select:enhance {
        post = function()
          local selection = action_state.get_selected_entry()
          if not selection then
            return
          end

          if selection.scode then
            -- un-escape / then escape required
            -- special chars for vim.fn.search()
            -- ] ~ *
            local scode = selection.scode:gsub([[\/]], "/"):gsub("[%]~*]", function(x)
              return "\\" .. x
            end)

            vim.cmd "norm! gg"
            vim.fn.search(scode)
            vim.cmd "norm! zz"
          else
            vim.api.nvim_win_set_cursor(0, { selection.lnum, 0 })
          end
        end,
      }
      return true
    end,
  }):find()
end

vim.api.nvim_set_keymap('n', '<leader>ec', '<cmd>lua My_get_nvim_config_file()<CR>', {noremap = true})
vim.api.nvim_set_keymap('n', '<space>o', '<cmd>lua My_get_tags_in_file()<CR>', {noremap = true})
