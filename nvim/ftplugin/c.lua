-- Display tabs as T-
vim.opt_local.list = true
vim.opt_local.listchars = "tab:T-"

-- Apply clang-format settings if available
local clang_format = require('clang_format')
clang_format.setup_buffer_indentation()

-- Fallback defaults if no .clang-format found
vim.opt_local.shiftwidth=8
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

function GetCurrentClass()
    local ts_utils = require('nvim-treesitter.ts_utils')
    local parsers = require('nvim-treesitter.parsers')

    -- Get the current node at cursor
    local node = ts_utils.get_node_at_cursor()

    -- Traverse up the tree to find a class_specifier or struct_specifier
    while node do
        local node_type = node:type()
        if node_type == 'class_specifier' or node_type == 'struct_specifier' then
            -- Find the class name within this node
            for child in node:iter_children() do
                if child:type() == 'type_identifier' or child:type() == 'name' then
                    return vim.treesitter.get_node_text(child, 0)
                end
            end
        end
        node = node:parent()
    end

    return nil
end

function lsp_get_current_function()
        local line_num = vim.api.nvim_win_get_cursor(0)[1] - 1
        vim.lsp.buf_request(0, 'textDocument/documentSymbol', {
            textDocument = vim.lsp.util.make_text_document_params()
        }, function(err, result, ctx, config)
                if err then
                    print("Error: " .. vim.inspect(err))
                    return
                end
                if result then
                    local current_line = line_num
                    local target_line = 0
                    -- Find the closest previous symbol
                    for _, symbol in ipairs(result) do
                        if symbol.range and 
                            symbol.range.start.line < current_line and 
                            symbol.range.start.line > target_line then
                            print(vim.inspect(symbol))
                        end
                    end
                end
            end)
end

function custom_previous_function()
    -- Check if there's an active LSP client for the current buffer
    local has_lsp = false
    for _, client in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
        has_lsp = true
        break
    end

    if has_lsp then
        -- Your LSP-based function
        local line_num = vim.api.nvim_win_get_cursor(0)[1] - 1
        vim.lsp.buf_request(0, 'textDocument/documentSymbol', {
            textDocument = vim.lsp.util.make_text_document_params()
        }, function(err, result, ctx, config)
                if err then
                    print("Error: " .. vim.inspect(err))
                    return
                end
                if result then
                    local current_line = line_num
                    local target_line = 0
                    -- Find the closest previous symbol
                    for _, symbol in ipairs(result) do
                        if symbol.range and 
                            symbol.range.start.line < current_line and 
                            symbol.range.start.line > target_line then
                            target_line = symbol.range.start.line
                        end
                    end
                    if target_line > 0 then
                        -- Add current position to jump list before moving
                        vim.cmd("normal! m'")

                        vim.api.nvim_win_set_cursor(0, {target_line + 1, 0})
                    end
                end
            end)
    else
        -- Execute the default [[ behavior
        vim.cmd("normal! [[")
    end
end

vim.api.nvim_buf_set_keymap(0, 'n', '[[', 
    '<cmd>lua custom_previous_function()<CR>', 
    {noremap = true, silent = true}
)


-- Get the current C++ class/struct name using Treesitter
local function get_current_cpp_class()
  local node = vim.treesitter.get_node()

  while node do
    local node_type = node:type()

    -- Case 1: Inside a class/struct definition
    if node_type == 'class_specifier' or node_type == 'struct_specifier' then
      for child in node:iter_children() do
        if child:type() == 'type_identifier' then
          return vim.treesitter.get_node_text(child, 0)
        end
      end
    end

    -- Case 2: Inside a method definition outside class body (e.g., void MyClass::method())
    if node_type == 'function_definition' then
      local declarator = node:field('declarator')[1]
      if declarator then
        for child in declarator:iter_children() do
          if child:type() == 'qualified_identifier' then
            local scope = child:field('scope')[1]
            if scope then
              return vim.treesitter.get_node_text(scope, 0)
            end
          end
        end
      end
    end

    node = node:parent()
  end

  return nil
end

-- Jump to tag location
local function jump_to_tag(tag)
  vim.cmd('e ' .. vim.fn.fnameescape(tag.filename))

  if tag.line then
    vim.cmd(tostring(tag.line))
  elseif tag.cmd then
    local cmd = tag.cmd
    if cmd:sub(1, 1) == '/' or cmd:sub(1, 1) == '?' then
      -- Search pattern: strip delimiters and anchors
      local pattern = cmd:sub(2, -2):gsub('^%^', ''):gsub('%$$', '')
      vim.fn.search(vim.fn.escape(pattern, '\\.*~[]'), 'w')
    else
      -- Line number
      vim.cmd(cmd)
    end
  end
end

-- Push current position to tagstack before jumping
local function push_tagstack(tagname)
  local pos = vim.fn.getpos('.')
  local curpos = {vim.fn.bufnr('%'), pos[2], pos[3], pos[4]}
  local item = {
    tagname = tagname,
    from = curpos,
    bufnr = vim.fn.bufnr('%'),
  }
  vim.fn.settagstack(vim.fn.win_getid(), { items = {item} }, 't')
end

-- Jump to tag location (modified)
local function jump_to_tag(tag, tagname)
  -- Push to tagstack BEFORE jumping
  push_tagstack(tagname)

  vim.cmd('e ' .. vim.fn.fnameescape(tag.filename))

  if tag.line then
    vim.cmd(tostring(tag.line))
  elseif tag.cmd then
    local cmd = tag.cmd
    if cmd:sub(1, 1) == '/' or cmd:sub(1, 1) == '?' then
      local pattern = cmd:sub(2, -2):gsub('^%^', ''):gsub('%$$', '')
      vim.fn.search(vim.fn.escape(pattern, '\\.*~[]'), 'w')
    else
      vim.cmd(cmd)
    end
  end
end

function TagSelectByCurrentClass(tagname)
  local classname = get_current_cpp_class()

  if not classname then
    vim.notify("Could not determine current class from cursor position", vim.log.levels.WARN)
    return
  end

  vim.notify("Searching for " .. classname .. "::" .. tagname, vim.log.levels.INFO)

  local tags = vim.fn.taglist('^' .. tagname .. '$')
  local filtered = vim.tbl_filter(function(t)
    return t.class == classname or t.struct == classname
  end, tags)

  if #filtered == 0 then
    vim.notify("No tags found for " .. classname .. "::" .. tagname, vim.log.levels.WARN)
    return
  elseif #filtered == 1 then
    jump_to_tag(filtered[1], tagname)
  else
    local items = {}
    for i, t in ipairs(filtered) do
      items[i] = string.format("[%s] %s:%s", t.kind or '?', t.filename, t.line or '?')
    end

    vim.ui.select(items, { prompt = classname .. '::' .. tagname }, function(_, idx)
      if idx then
        jump_to_tag(filtered[idx], tagname)
      end
    end)
  end
end

vim.keymap.set('n', '<leader>tc', function()
  TagSelectByCurrentClass(vim.fn.expand('<cword>'))
end, { desc = 'Jump to tag in current class' })
