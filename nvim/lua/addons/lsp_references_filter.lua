local M = {}

-- Check if a reference is an assignment to the symbol (C/C++ only)
local function is_assignment_to_symbol(file_path, line_num, symbol_name)
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
    local line_text = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]
    if not line_text then
        return false
    end
    
    local symbol_col = line_text:find(symbol_name, 1, true)
    if not symbol_col then
        return false
    end
    
    local node = root:named_descendant_for_range(line_num - 1, symbol_col - 1, line_num - 1, symbol_col - 1 + #symbol_name)
    if not node then
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
        
        -- Check if parent is an assignment and current node is on the left side
        if parent_type == "assignment_expression" then
            local left_child = parent:field("left")[1]
            if left_child then
                -- Check if our node is within the left side subtree
                local left_start_row, left_start_col = left_child:start()
                local left_end_row, left_end_col = left_child:end_()
                local node_start_row, node_start_col = node:start()
                local node_end_row, node_end_col = node:end_()
                
                if node_start_row >= left_start_row and node_end_row <= left_end_row and
                   node_start_col >= left_start_col and node_end_col <= left_end_col then
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

function M.lsp_references_with_filter()
    local params = vim.lsp.util.make_position_params()
    params.context = { includeDeclaration = true }
    local symbol_name = vim.fn.expand('<cword>')
    
    vim.lsp.buf_request(0, "textDocument/references", params, function(err, result, ctx)
        if err or not result or vim.tbl_isempty(result) then
            vim.notify("No references found", vim.log.levels.INFO)
            return
        end

        local items = {}
        for _, ref in ipairs(result) do
            local uri = ref.uri or ref.targetUri
            local range = ref.range or ref.targetSelectionRange
            local file = vim.uri_to_fname(uri)
            local bufnr = vim.uri_to_bufnr(uri)
            vim.fn.bufload(bufnr)
            local line_text = vim.api.nvim_buf_get_lines(bufnr, range.start.line, range.start.line + 1, false)[1] or ""
            local is_assign = is_assignment_to_symbol(file, range.start.line + 1, symbol_name)
            
            table.insert(items, {
                file = file,
                pos = { range.start.line + 1, range.start.character + 1 },
                line = line_text,
                text = line_text,
                type = is_assign and "=" or "",  -- Add 'type' field for filtering
            })
        end

        local formatters = require("formatters.snacks_formatters")
        
        Snacks.picker({
            source = "lsp_references_filtered",
            finder = function()
                return items
            end,
            format = formatters.Shayagr_format_brazil_ws,
            preview = formatters.Shayagr_workspace_aware_file_preview,
            jump = { tagstack = true },
        })
    end)
end

-- Exported function for testing: returns true if line contains assignment to symbol
function M.is_assignment(file_path, line_num, symbol_name)
    return is_assignment_to_symbol(file_path, line_num, symbol_name)
end

vim.api.nvim_create_user_command('LspReferencesFilter', M.lsp_references_with_filter, {
    desc = "LSP references with assignment filter support"
})

vim.api.nvim_create_user_command('TestIsAssignment', function()
    local symbol_name = vim.fn.expand('<cword>')
    local params = vim.lsp.util.make_position_params()
    params.context = { includeDeclaration = true }
    
    print(string.format("Testing assignments for symbol: '%s'", symbol_name))
    
    vim.lsp.buf_request(0, "textDocument/references", params, function(err, result, ctx)
        if err then
            vim.notify("LSP error: " .. vim.inspect(err), vim.log.levels.ERROR)
            return
        end
        
        if not result or vim.tbl_isempty(result) then
            vim.notify("No references found", vim.log.levels.INFO)
            return
        end
        
        print(string.format("Found %d total references", #result))
        
        local assignments = {}
        for i, ref in ipairs(result) do
            local uri = ref.uri or ref.targetUri
            local range = ref.range or ref.targetSelectionRange
            local file = vim.uri_to_fname(uri)
            local line_num = range.start.line + 1
            
            local bufnr = vim.uri_to_bufnr(uri)
            vim.fn.bufload(bufnr)
            local line_text = vim.api.nvim_buf_get_lines(bufnr, range.start.line, range.start.line + 1, false)[1] or ""
            
            local is_assign = is_assignment_to_symbol(file, line_num, symbol_name)
            
            print(string.format("[%d] %s:%d %s - %s", 
                i, 
                file:match("([^/]+)$"), 
                line_num, 
                is_assign and "[ASSIGN]" or "[READ]",
                line_text:gsub("^%s+", ""):sub(1, 60)
            ))
            
            if is_assign then
                table.insert(assignments, {
                    filename = file,
                    lnum = line_num,
                    col = range.start.character + 1,
                    text = line_text,
                })
            end
        end
        
        if #assignments == 0 then
            vim.notify("No assignments found for '" .. symbol_name .. "'", vim.log.levels.WARN)
            return
        end
        
        vim.fn.setqflist(assignments, 'r')
        vim.cmd('copen')
        vim.notify(string.format("Found %d assignment(s) to '%s'", #assignments, symbol_name), vim.log.levels.INFO)
    end)
end, {
    desc = "Test assignment detection - shows assignments in quickfix"
})

return M
