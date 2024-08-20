
local function i(value)
  if type(value) == "string" then
    print(value)
  elseif type(value) == "number" then
    print(tostring(value))
  else
    print(vim.inspect(value))
  end
end

local function add_backslash_to_last_arg(command_node, argument)
  -- get the column of the backslash from the first argument
  local first_arg = command_node:named_child(1)
  local first_arg_last_line, _ = first_arg:end_()

  local line = vim.api.nvim_buf_get_lines(1, first_arg_last_line, first_arg_last_line + 1, true)[1]
  local _, indent_col = line:find('%s*\\$')

  local last_arg = command_node:named_child(command_node:named_child_count() - 1)

  local last_arg_row, _, _ = last_arg:end_()

  -- Add a backslash at the end of the last argument
  local last_arg_line = vim.api.nvim_buf_get_lines(1, last_arg_row, last_arg_row + 1, true)[1]
  local last_arg_end_col, _ = last_arg_line:find('%s*(\\?)$')
  local backslash_str = string.rep(" ", indent_col - last_arg_end_col) .. "\\"
  last_arg_line = last_arg_line:gsub('%s*(\\?)$', backslash_str)

  vim.api.nvim_buf_set_lines(1, last_arg_row, last_arg_row + 1, true, {last_arg_line})

  -- Add a new empty argument
  local _, indentation, _ = first_arg:start()
  local new_arg_str = string.rep(" ", indentation) .. argument

  --vim.api.nvim_buf_set_lines(1, last_arg_row + 1, last_arg_row + 1, true, {new_arg_str})
end

local function indent_node(node, indentation)
  local node_new_lines = {}
  local node_start, _ = node:start()
  local node_end, _ = node:end_()

  local first_line = vim.api.nvim_buf_get_lines(1, node_start, node_start + 1, true)[1]
  local _, orig_indent = first_line:find("^%s+")

  first_line = first_line:gsub("^%s+", indentation, 1)
  table.insert(node_new_lines, first_line)

  for linenr=node_start + 1, node_end do
    local line = vim.api.nvim_buf_get_lines(1, linenr, linenr + 1, true)[1]
    local new_indent = indentation
    local _, line_indent = line:find("^%s+")

    -- The first line might be the first argument and don't have indentation
    if orig_indent == nil then
      orig_indent = line_indent
    end

    if line_indent then
      local diff = line_indent - orig_indent
      if diff > 0 then
        new_indent = new_indent .. string.rep(" ", diff)
      end
    end

    line = line:gsub("^%s+", new_indent, 1)
    table.insert(node_new_lines, line)
  end

  return node_new_lines
end

local function align_command_argument(command_node)
  -- Get the start column of the first argument
  local first_arg = command_node:named_child(1)
  local _, indentation_col, _ = first_arg:start()
  local indentation = string.rep(" ", indentation_col)

  -- Get the length of the longest argument's line
  local max_arg_len = 0
  for node, _ in command_node:iter_children() do
    local node_start_row, _, _ = node:start()
    local node_end_row, _, _ = node:end_()
    local arg_lines = vim.api.nvim_buf_get_lines(1, node_start_row, node_end_row + 1, true)

    local node_max_line = 0
    -- find the longest line in an argument
    for _, line in ipairs(arg_lines) do
      local line_end_col, _ = line:find('%s*(\\?)$')

      -- calculate the future indentation (don't bother to do it for the 
      -- arguments which don't have leading spaces)
      local _, line_start_col = line:find("^%s+")
      if line_start_col then
        line_end_col = line_end_col + (indentation_col - line_start_col)
      end

      if node_max_line < line_end_col then
        node_max_line = line_end_col
      end
    end
    local last_line_end_col = node_max_line

    if last_line_end_col > max_arg_len then
      max_arg_len = last_line_end_col
    end
  end

  -- Make all arg start with the same indentation and have the backslash aligned
  local new_command_lines = {}

  local iterated_node = first_arg
  while iterated_node do
    local node_row, _, _ = iterated_node:start()

    --arg_line = arg_line:gsub("^%s+", indentation, 1)
    local new_node_lines = indent_node(iterated_node, indentation)
    local arg_line = new_node_lines[#new_node_lines]

    local line_end, _ = arg_line:find('%s*(\\?)$')
    local backslash_str = string.rep(" ", max_arg_len - line_end + 8) .. "\\"
    arg_line = arg_line:gsub('%s*\\$', backslash_str, 1)
    new_node_lines[#new_node_lines] = arg_line

    for _, new_node_line in ipairs(new_node_lines) do
      table.insert(new_command_lines, new_node_line)
    end
    --table.insert(new_command_lines, arg_line)
    --vim.api.nvim_buf_set_lines(1, node_row, node_row + 1, true, {arg_line})
    --i(arg_line)

    iterated_node = iterated_node:next_sibling()
    --i(iterated_node)
  end

  local command_first_line, _ = command_node:start()
  local command_last_line, _ = command_node:end_()
  vim.api.nvim_buf_set_lines(1, command_first_line, command_last_line + 1, true, new_command_lines)
  --i(new_command_lines)
end

function Align_bash_arguments()
  local language_tree = vim.treesitter.get_parser(1, 'bash')
  local syntax_tree = language_tree:parse()
  local root_node = syntax_tree[1]:root()

  local arg_ts_query = [[
        (command) @command
        ]]
  local arg_query = vim.treesitter.query.parse('bash', arg_ts_query)

  for id, node, _ in arg_query:iter_captures(root_node) do
    local capture_name = arg_query.captures[id]
    if capture_name == "command" then
      --align_command_argument(node)
      add_backslash_to_last_arg(node, '"kernel_exp"')
      --do return end
    end
  end
end

local function get_visual_selection()
  local s_start = vim.fn.getpos("'<")
  local s_end = vim.fn.getpos("'>")
  local n_lines = math.abs(s_end[2] - s_start[2]) + 1
  local lines = vim.api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)
  lines[1] = string.sub(lines[1], s_start[3], -1)
  if n_lines == 1 then
    lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3] - s_start[3] + 1)
  else
    lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3])
  end
  return table.concat(lines, '\n')
end

local function get_node_properties(node, bufnr)
  return {
    txt = vim.treesitter.get_node_text(node, bufnr),
    start = {node:start()},
    end_ = {node:end_()},
  }
end

local function split_str(str)
  local input_table
  for s in string.gmatch(str, "([^\n]+)") do
      table.insert(input_table, s)
   end

  return input_table
end

local function replace_nodes_content(fnode, snode, bufnr)
  local fnode_srow = fnode.start[1]
  local fnode_erow = fnode.end_[1]
  local fnode_row_len = fnode_erow - fnode_srow + 1

  local snode_srow = snode.start[1]
  local snode_erow = snode.end_[1]
  local snode_row_len = snode_erow - snode_srow + 1

  local lines = vim.api.nvim_buf_get_lines(bufnr, fnode_srow, snode_erow + 1, false)
  local snode_srelative = snode_srow - fnode_srow + 1

  local new_lines = {}
  i({snode_srelative, (snode_srelative + snode_row_len - 1)})
  for line_nr = snode_srelative, (snode_srelative + snode_row_len - 1) do
    table.insert(new_lines, lines[line_nr])
  end

  for line_nr = fnode_row_len + 1, (snode_srelative - 1) do
    table.insert(new_lines, lines[line_nr])
  end

  for line_nr = 1, fnode_row_len do table.insert(new_lines, lines[line_nr]) end

  i(new_lines)
end

function Switch_TS_arguments(bufnr)
  bufnr = bufnr or 0
  local ts_query = vim.fn.getreg('a')

  local language_tree = vim.treesitter.get_parser(bufnr, 'bash')
  local syntax_tree = language_tree:parse()
  local root_node = syntax_tree[1]:root()
  local arg_query = vim.treesitter.query.parse('bash', ts_query)

  local fnode, snode
  for id, node, _ in arg_query:iter_captures(root_node) do
    if id == 1 then
      fnode = get_node_properties(node, bufnr)
    else
      snode = get_node_properties(node, bufnr)
      replace_nodes_content(fnode, snode, bufnr)
    end
  end
end

function Find_non_empty_ts_query(bufnr)
  bufnr = bufnr or 0
  -- Search for a capture expression for TreeSitter, and check whether its value
  -- is non empty or not. The query is stored in register &a
  local ts_query = vim.fn.getreg('a')

  local language_tree = vim.treesitter.get_parser(bufnr, 'bash')
  local syntax_tree = language_tree:parse()
  local root_node = syntax_tree[1]:root()
  local arg_query = vim.treesitter.query.parse('bash', ts_query)

  local found_args = {}

  for _, node, _ in arg_query:iter_captures(root_node) do
    local node_str = vim.treesitter.get_node_text(node, bufnr)
    if string.find(node_str, "%a") then
      local node_srow, node_scol, _ = node:start()
      local node_erow, node_ecol, _ = node:end_()
      table.insert(found_args, {
        bufnr = bufnr,
        text = node_str,
        lnum = node_srow + 1,
        ena_lnum = node_erow + 1,
        col = node_scol,
        ena_col = node_ecol
      })
      print(node_str)
    end
  end

  -- clear current quicklist
  vim.fn.setqflist({}, 'r')

  if #found_args == 0 then
    return
  end

  vim.fn.setqflist(found_args, 'a')
  vim.cmd.copen()
  vim.cmd.cfirst()
end

function Transpose_c_macros_highlight()
  local str = vim.fn.getreg('"')
  local parser = vim.treesitter.get_string_parser(str, "c")
  local syntax_tree = parser:parse()
  local root_node = syntax_tree[1]:root()

  local arg_ts_query = [[
    (binary_expression
      left: (_) @left
      right: (_) @right)
        ]]
  local arg_query = vim.treesitter.query.parse('c', arg_ts_query)

  local args = {}
  for id, node, _ in arg_query:iter_captures(root_node) do
    local _, start_col, _ = node:start()
    local _, end_col, _ = node:end_()

    table.insert(args, {vim.treesitter.get_node_text(node, str), start_col, end_col})
    --i{vim.treesitter.get_node_text(node, str), start_col, end_col}
  end

  local new_exp = str:sub(1, args[1][2]) or ""
  new_exp = new_exp .. str:sub(args[2][2], args[2][3])

  new_exp = new_exp .. str:sub(args[1][3] + 1, args[2][2])

  new_exp = new_exp .. str:sub(args[1][2] + 1, args[1][3])
  new_exp = new_exp:gsub("^%s+", "")

  -- change the direction of < or >
  local changed_ix
  new_exp, changed_ix = new_exp:gsub("<", ">")
  if changed_ix == 0 then
    new_exp, changed_ix = new_exp:gsub(">", "<")
  end

  vim.fn.setreg('"', new_exp)

  --i(new_exp)
end

--Switch_TS_arguments(495)
--find_non_empty_ts_query()
--Transpose_c_macros_highlight()
