local M = {}

-- Check if a reference line contains an assignment TO the symbol (not FROM it)
-- This checks if the symbol itself is being assigned a value, not if it's used in an assignment
function M.is_assignment_to_symbol(file_path, line_num, symbol_name)
    -- Load the buffer
    local bufnr = vim.fn.bufadd(file_path)
    vim.fn.bufload(bufnr)
    
    local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "cpp")
    if not ok or not parser then
        return false
    end
    
    local trees = parser:parse()
    if not trees or #trees == 0 then
        return false
    end
    
    local root = trees[1]:root()
    
    -- Get the line text
    local line_text = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]
    if not line_text then
        return false
    end
    
    -- Find where the symbol appears in the line
    local symbol_col = line_text:find(symbol_name, 1, true)
    if not symbol_col then
        return false
    end
    
    -- Get the node at the symbol position
    local node = root:named_descendant_for_range(line_num - 1, symbol_col - 1, line_num - 1, symbol_col - 1 + #symbol_name)
    if not node then
        return false
    end
    
    -- Check if this node is a field_identifier (like ->item or .item)
    -- In this case, we're NOT assigning TO the symbol, we're reading FROM it
    if node:type() == "field_identifier" then
        return false
    end
    
    -- Walk up the tree to find if this is part of an assignment's left side
    local current = node
    while current do
        local parent = current:parent()
        if not parent then
            break
        end
        
        local parent_type = parent:type()
        
        -- If we hit a field_expression, the symbol is being accessed, not assigned
        if parent_type == "field_expression" then
            return false
        end
        
        -- Check if parent is an assignment and current node is on the left side
        if parent_type == "assignment_expression" then
            local left_child = parent:field("left")[1]
            if left_child then
                local left_text = vim.treesitter.get_node_text(left_child, bufnr)
                -- Check if the left side is exactly our symbol (not a field access)
                if left_text == symbol_name then
                    return true
                end
            end
        end
        
        -- Check for init_declarator (variable initialization)
        if parent_type == "init_declarator" then
            local declarator = parent:field("declarator")[1]
            if declarator then
                local decl_text = vim.treesitter.get_node_text(declarator, bufnr)
                if decl_text == symbol_name then
                    return true
                end
            end
        end
        
        current = parent
    end
    
    return false
end

-- Test function that analyzes LSP references
function M.test_references(file_path, line, col)
    print("\n=== Testing LSP References with Assignment Detection ===\n")
    
    -- Open the file
    vim.cmd('edit ' .. vim.fn.fnameescape(file_path))
    local bufnr = vim.api.nvim_get_current_buf()
    
    -- Wait for LSP to attach
    vim.wait(5000, function()
        return #vim.lsp.get_clients({bufnr = bufnr}) > 0
    end)
    
    local clients = vim.lsp.get_clients({bufnr = bufnr})
    if #clients == 0 then
        print("ERROR: No LSP client attached")
        return
    end
    
    print("LSP client attached: " .. clients[1].name)
    
    -- Set cursor position
    vim.api.nvim_win_set_cursor(0, {line, col})
    
    -- Get the symbol under cursor
    local symbol_name = vim.fn.expand('<cword>')
    print("Symbol: " .. symbol_name)
    print("Location: " .. file_path .. ":" .. line)
    
    -- Request LSP references synchronously
    local params = vim.lsp.util.make_position_params()
    params.context = { includeDeclaration = true }
    
    local result = vim.lsp.buf_request_sync(0, "textDocument/references", params, 10000)
    
    if not result or vim.tbl_isempty(result) then
        print("\nNo references found")
        return
    end
    
    -- Extract results from all clients
    local all_refs = {}
    for client_id, response in pairs(result) do
        if response.result then
            vim.list_extend(all_refs, response.result)
        end
    end
    
    if #all_refs == 0 then
        print("\nNo references found")
        return
    end
    
    print("\nFound " .. #all_refs .. " references:")
    print(string.rep("-", 80))
    
    local assignment_count = 0
    for i, ref in ipairs(all_refs) do
        local uri = ref.uri or ref.targetUri
        local range = ref.range or ref.targetSelectionRange
        local ref_file = vim.uri_to_fname(uri)
        local ref_bufnr = vim.uri_to_bufnr(uri)
        vim.fn.bufload(ref_bufnr)
        
        local ref_line = range.start.line + 1
        local line_text = vim.api.nvim_buf_get_lines(ref_bufnr, range.start.line, range.start.line + 1, false)[1] or ""
        
        local is_assign = M.is_assignment_to_symbol(ref_file, ref_line, symbol_name)
        if is_assign then
            assignment_count = assignment_count + 1
        end
        
        print(string.format("[%d] %s:%d %s", 
            i, 
            ref_file:match("([^/]+)$"), 
            ref_line,
            is_assign and "[ASSIGNMENT]" or ""
        ))
        print("    " .. line_text:gsub("^%s+", ""))
    end
    
    print(string.rep("-", 80))
    print(string.format("\nSummary: %d total references, %d assignments", #all_refs, assignment_count))
end

return M
