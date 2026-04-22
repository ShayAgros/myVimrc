local ns = vim.api.nvim_create_namespace("hm_log_diagnostics")

vim.bo.readonly = true

local function scan_buffer()
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local diagnostics = {}

    for lnum, line in ipairs(lines) do
        if line:match("^%a[%w_%.]*Exception") then
            local start_pos, end_pos = line:find("[%w_%.]+Exception[%w]*")
            table.insert(diagnostics, {
                lnum = lnum - 1,
                col = start_pos - 1,
                end_lnum = lnum - 1,
                end_col = end_pos,
                severity = vim.diagnostic.severity.WARN,
                message = line:sub(start_pos, end_pos),
                source = "hm_log"
            })
        elseif line:match("%[ERROR%]") then
            local s, e = line:find("%[ERROR%]")
            table.insert(diagnostics, {
                lnum = lnum - 1, col = s - 1, end_lnum = lnum - 1, end_col = e,
                severity = vim.diagnostic.severity.ERROR,
                message = "[ERROR]", source = "hm_log"
            })
        elseif line:match("%[WARN[^%]]*%]") then
            local s, e = line:find("%[WARN[^%]]*%]")
            table.insert(diagnostics, {
                lnum = lnum - 1, col = s - 1, end_lnum = lnum - 1, end_col = e,
                severity = vim.diagnostic.severity.WARN,
                message = line:sub(s, e), source = "hm_log"
            })
        end
    end

    vim.diagnostic.set(ns, bufnr, diagnostics)
end

vim.fn.matchadd("HmLogError", "\\[ERROR\\]")
vim.fn.matchadd("HmLogWarn", "\\[WARN[^\\]]*\\]")
vim.fn.matchadd("HmLogWarn", "\\<[A-Z]\\w*Exception\\w*\\>")
vim.api.nvim_set_hl(0, "HmLogError", { fg = "red", bold = true })
vim.api.nvim_set_hl(0, "HmLogWarn", { fg = "#575a26", bold = true })

vim.defer_fn(scan_buffer, 0)
