-- This file contains custom functions for my everyday work

---@class TreeSitterNode

-- Once entering a new buffer, change the local directory to git directory if
-- exists
function Maybe_change_git_project()
  local utils = require 'shayagr_utils'
  local buffer_file = vim.api.nvim_buf_get_name(0)

  if buffer_file then
    local file_dir = buffer_file:match("(.*/)")
    local git_dir = utils.get_git_dir(file_dir)

    if git_dir then
      --print(git_dir)
      vim.cmd('lcd ' .. git_dir)
      --vim.fn.lcd(git_dir)
    end
  end
end

function Clean_trailing_spaces_in_file()
  local buff_lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
  local modified_lines = {}
  local some_lines_changed = false

  for _, line in ipairs(buff_lines) do
    local new_line = vim.fn.substitute(line, '\\s\\+$', '', '')
    some_lines_changed = some_lines_changed or (new_line ~= line)

    table.insert(modified_lines, new_line)
  end

  if some_lines_changed then
    vim.api.nvim_buf_set_lines(0, 0, -1, true, modified_lines)
  end
end

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

function My_shift_oncall_shift()
  local roles = {}

  local current_line = vim.api.nvim_get_current_line()
  local new_line = current_line

  for _, turn in ipairs({ "next", "curr" }) do
    for _, role in ipairs({"driver", "firmware", "secondary", "Weekend"}) do
      roles[turn] = roles[turn] or {}
      local rstart, rend, name = string.find(current_line, turn .. "_ena_" .. role .. "=(%a+)")

      roles[turn][role] = {}
      roles[turn][role].name = name
      roles[turn][role].rstart = rstart
      roles[turn][role].rend = rend

      -- ugly solution. Oh well
      if turn == "curr" then
        new_line = new_line:gsub(turn .. "_ena_" .. role .. "=(%a+)", turn .. "_ena_" .. role .. "=" .. roles["next"][role].name)
      end
    end
  end

  vim.api.nvim_buf_set_lines(0, 0, 1, false, {new_line})
end

function My_parse_vf_flags(flags_bitmap)
  local bit = require("bit")

  -- ENA VF features flags
  local ena_vf_flags = {
    ["ENA_VF_FLAGS_QUIESCED"] = 0,
    ["ENA_VF_FLAGS_IS_FLR_ACK_REQ"] = 1,
    ["ENA_VF_FLAGS_DRAIN_QUEUES"] = 2,
    ["ENA_VF_FLAGS_LLQ_ALLOCATED"] = 3,
    ["ENA_VF_FLAGS_DDP_SUPPORTED"] = 4,
    ["ENA_VF_FLAGS_KNOWN_ERROR"] = 6,
    ["ENA_VF_FLAGS_DUMPED_STATS_ON_STOP_JOB_ERROR"] = 7,
    ["ENA_VF_FLAGS_IS_EFA"] = 8,
    ["ENA_VF_FLAGS_EXTENDED_RX_USED"] = 9,
    ["ENA_VF_FLAGS_FORCE_STOP"] = 11,
    ["ENA_VF_FLAGS_NX_REQUIRES_RX_OFFSET"] = 12,
    ["ENA_VF_FLAGS_HOST_SUPPORTS_RX_OFFSET"] = 13,
    ["ENA_VF_FLAGS_USER_VF"] = 14,
    ["ENA_VF_FLAGS_HOST_USE_RX_MODERATION"] = 15,
    ["ENA_VF_FLAGS_HOST_USE_TX_MODERATION"] = 16,
    ["ENA_VF_FLAGS_MSIX_0_FOR_IO"] = 17,
    ["ENA_VF_FLAGS_IPP_SUPPORTED"] = 18,
    ["ENA_VF_FLAGS_PUPA_SUPPORTED"] = 19,
    ["ENA_VF_FLAGS_XDP_ENABLED"] = 20,
    ["ENA_VF_FLAGS_DPDK_RECENTLY_ATTACHED"] = 21,
    ["ENA_VF_FLAGS_HOST_SUPPORTS_AL8_ACCEL"] = 22,
    ["ENA_VF_FLAGS_HOST_DOESNT_SUPPORT_AL8_ACCEL"] = 23,
  }

  if not flags_bitmap then
    return
  end

  local enabled_features = {}
  for flag_name, flag_bit in pairs(ena_vf_flags) do
    local bit_set = bit.band(flags_bitmap, bit.lshift(1, flag_bit))
    if bit_set then
      table.insert(enabled_features, flag_name)
    end
  end

  print(table.concat(enabled_features, "\n"))
end

function GetCloudWatchLink()
  local row, column = unpack(vim.api.nvim_win_get_cursor(0))

  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)

  -- Search for the expression 'dom:[number]'
  local dom, i, j
  while true do
      i, j = string.find(line[1], "dom:%d+", i and (i + 1) or 0) -- find next dom occurrence
      if i == nil then break end

      -- column is 0 based, while lua is 1-based (who'd have thought that's an
      -- issue ?)
      if i < column and column <= j then
        dom = string.sub(line[1], i, j)
        break
      end
    end

  if not dom then
    print("Couldn't extract dom from line")
    return
  end

  dom = string.gsub(dom, ":", "-")

  local file_path = vim.api.nvim_buf_get_name(0)
  local _, _, file_name = string.find(file_path, "([^/]+)$")
  print("dom is", dom, "file name", file_name)
  if not file_name then
    print("Couldn't extract filename from", file_path)
    return
  end

  local starttime_d, starttime_t, endtime_d, endtime_t
  _, j, starttime_d, starttime_t = string.find(file_name, "(%d+)-(%d+)")
  _, _, endtime_d, endtime_t = string.find(file_name, "(%d+)-(%d+)", j + 1)

  if not (starttime_t and starttime_d and endtime_d and endtime_t) then
    print("Couldn't extract time range from file name")
  end

  local az
  _, _, az = string.find(file_path, "/([^/]+)/[^/]+/[^/]+$")
  if not az then
    print("Couldn't extract az from file path", file_path)
    return
  end

  local efa_tool_cmd = "efa_tool cw" .. " -z " .. az .. " -c " .. dom
  efa_tool_cmd = efa_tool_cmd .. " -s " .. starttime_d .. "T" .. starttime_t
  efa_tool_cmd = efa_tool_cmd .. " -e " .. endtime_d .. "T" .. endtime_t

  print("(Copied to clipboard)", efa_tool_cmd)
  vim.fn.setreg("+", efa_tool_cmd)
end

vim.api.nvim_set_keymap('n', '<leader>ec', '<cmd>lua My_get_nvim_config_file()<CR>', {noremap = true})
vim.api.nvim_set_keymap('n', '<space>o', '<cmd>lua My_get_tags_in_file()<CR>', {noremap = true})
