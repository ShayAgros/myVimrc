-- Navigate between MySQL error log files by timestamp: gn = next, gp = previous
local function get_sorted_siblings()
    local current = vim.api.nvim_buf_get_name(0)
    local dir = vim.fs.dirname(current)
    local files = {}
    for name, type in vim.fs.dir(dir) do
        if type == "file" and name:match("^mysql%-error%-running%.log%.") then
            table.insert(files, dir .. "/" .. name)
        end
    end
    table.sort(files)
    return files, current
end

local function navigate_log(direction)
    local files, current = get_sorted_siblings()
    for i, f in ipairs(files) do
        if f == current then
            local target = files[i + direction]
            if target then
                vim.cmd("edit " .. vim.fn.fnameescape(target))
            else
                vim.notify("No " .. (direction > 0 and "next" or "previous") .. " MySQL error log", vim.log.levels.INFO)
            end
            return
        end
    end
end

vim.keymap.set("n", "gn", function() navigate_log(1) end, { buffer = true, desc = "Next MySQL error log" })
vim.keymap.set("n", "gp", function() navigate_log(-1) end, { buffer = true, desc = "Previous MySQL error log" })

-- Add diagnostics
local ns = vim.api.nvim_create_namespace("mysql_error_log_diagnostics")

-- Make buffer readonly
vim.bo.readonly = true

local function add_to_quickfix()
    local qflist = {}
    local bufnr = vim.api.nvim_get_current_buf()
    local filename = vim.api.nvim_buf_get_name(bufnr)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local diagnostics = {}

    for lnum, line in ipairs(lines) do
        if line:match("AWS_OSCAR_WARN") or line:match("AWS_OSCAR_ERROR") then
            table.insert(qflist, {
                bufnr = bufnr,
                filename = filename,
                lnum = lnum,
                text = line
            })
        end
        
        -- Add diagnostic for AWS_OSCAR_ERROR
        local start_pos, end_pos = line:find("AWS_OSCAR_ERROR")
        if start_pos then
            table.insert(diagnostics, {
                lnum = lnum - 1,
                col = start_pos - 1,
                end_lnum = lnum - 1,
                end_col = end_pos,
                severity = vim.diagnostic.severity.ERROR,
                message = "AWS OSCAR error detected",
                source = "mysql_error_log"
            })
        end
    end

    vim.diagnostic.set(ns, bufnr, diagnostics)
    vim.fn.setqflist(qflist)
    return qflist
end

local qflist = add_to_quickfix()
local line_to_idx = {}
for i, item in ipairs(qflist) do
    line_to_idx[item.lnum] = i
end

local function sync_quickfix_to_cursor()
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    local idx = line_to_idx[current_line]
    if idx then
        vim.fn.setqflist({}, 'r', {idx = idx})
    end
end

vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = 0,
    callback = sync_quickfix_to_cursor
})


