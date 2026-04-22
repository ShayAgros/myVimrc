local addon = require('addons.lsp_references_filter')

-- Open the file and position cursor on 'item'
vim.cmd('edit /local/home/shayagr/workspace/brazil/dev-kermit/src/OscarMysql80/sql/sql_optimizer.cc')
vim.api.nvim_win_set_cursor(0, {480, 50})

-- Wait for LSP
vim.wait(5000, function()
    return #vim.lsp.get_clients({bufnr = 0}) > 0
end)

local symbol_name = vim.fn.expand('<cword>')
print(string.format("\n=== Analyzing all LSP references for '%s' ===\n", symbol_name))

local params = vim.lsp.util.make_position_params()
params.context = { includeDeclaration = true }

local result = vim.lsp.buf_request_sync(0, "textDocument/references", params, 10000)

if not result or vim.tbl_isempty(result) then
    print("No references found")
    return
end

local all_refs = {}
for client_id, response in pairs(result) do
    if response.result then
        vim.list_extend(all_refs, response.result)
    end
end

print(string.format("Found %d references\n", #all_refs))
print(string.rep("=", 100))

for i, ref in ipairs(all_refs) do
    local uri = ref.uri or ref.targetUri
    local range = ref.range or ref.targetSelectionRange
    local file = vim.uri_to_fname(uri)
    local line_num = range.start.line + 1
    local bufnr = vim.uri_to_bufnr(uri)
    vim.fn.bufload(bufnr)
    local line_text = vim.api.nvim_buf_get_lines(bufnr, range.start.line, range.start.line + 1, false)[1] or ""
    
    local is_assign = addon.is_assignment(file, line_num, symbol_name)
    
    -- Manual analysis
    local manual_check = "?"
    local trimmed = line_text:gsub("^%s+", "")
    
    -- Check for assignment patterns
    if trimmed:match("^[%w_]+%s*=%s*") or                    -- var = ...
       trimmed:match("^[%w_]+%->[%w_]+%s*=%s*") or          -- obj->field = ...
       trimmed:match("^[%w_]+%.[%w_]+%s*=%s*") or           -- obj.field = ...
       trimmed:match("^[%w_]+::[%w_]+%s*=%s*") then         -- Class::field = ...
        -- Check if 'item' is on the left side of =
        local left_side = trimmed:match("^(.-)%s*=")
        if left_side and left_side:match(symbol_name) then
            manual_check = "ASSIGN"
        else
            manual_check = "READ"
        end
    else
        manual_check = "READ"
    end
    
    local match = (is_assign and manual_check == "ASSIGN") or (not is_assign and manual_check == "READ")
    local status = match and "✓" or "✗ MISMATCH"
    
    print(string.format("[%d] %s | Detected: %-6s | Expected: %-6s | %s:%d",
        i, status, 
        is_assign and "ASSIGN" or "READ",
        manual_check,
        file:match("([^/]+)$"), 
        line_num
    ))
    print(string.format("    %s", trimmed:sub(1, 90)))
    
    if not match then
        print("    ^^^ MISMATCH - needs investigation")
    end
end

print(string.rep("=", 100))
