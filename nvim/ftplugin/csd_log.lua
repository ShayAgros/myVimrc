-- Navigate between CSD log files by timestamp: gn = next, gp = previous
local function get_sorted_siblings()
    local current = vim.api.nvim_buf_get_name(0)
    local dir = vim.fs.dirname(current)
    local files = {}
    for name, type in vim.fs.dir(dir) do
        if type == "file" and name:match("^grover%.csdd%.") and name:match("%.log$") then
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
                vim.notify("No " .. (direction > 0 and "next" or "previous") .. " CSD log", vim.log.levels.INFO)
            end
            return
        end
    end
end

vim.keymap.set("n", "gn", function() navigate_log(1) end, { buffer = true, desc = "Next CSD log" })
vim.keymap.set("n", "gp", function() navigate_log(-1) end, { buffer = true, desc = "Previous CSD log" })

-- Add diagnostics
local ns = vim.api.nvim_create_namespace("csd_log_diagnostics")

-- Make buffer readonly
vim.bo.readonly = true

local function scan_buffer()
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local diagnostics = {}

    for lnum, line in ipairs(lines) do
        local has_error = false
        
        -- Check for CSD network connection problem
        local start_pos, end_pos = line:find("CSD encounters network connection problem")
        if start_pos then
            table.insert(diagnostics, {
                lnum = lnum - 1,
                col = start_pos - 1,
                end_lnum = lnum - 1,
                end_col = end_pos,
                severity = vim.diagnostic.severity.ERROR,
                message = "CSD network connection problem detected",
                source = "csd_log"
            })
            has_error = true
        end
        
        -- Check for CSD_SN_NETWORK FAILOVER in global diag lines
        if line:match("global diag:") then
            start_pos, end_pos = line:find("CSD_SN_NETWORK%s+FAILOVER")
            if start_pos then
                table.insert(diagnostics, {
                    lnum = lnum - 1,
                    col = start_pos - 1,
                    end_lnum = lnum - 1,
                    end_col = end_pos,
                    severity = vim.diagnostic.severity.ERROR,
                    message = "CSD network failover detected",
                    source = "csd_log"
                })
                has_error = true
            end
        end
        
        -- Check for ERRO/3 only if no error diagnostic already added
        if not has_error then
            start_pos, end_pos = line:find("ERRO/3")
            if start_pos then
                table.insert(diagnostics, {
                    lnum = lnum - 1,
                    col = start_pos - 1,
                    end_lnum = lnum - 1,
                    end_col = end_pos,
                    severity = vim.diagnostic.severity.WARN,
                    message = "Error level 3 detected",
                    source = "csd_log"
                })
            end
        end
    end

    vim.diagnostic.set(ns, bufnr, diagnostics)
end

vim.defer_fn(scan_buffer, 0)
