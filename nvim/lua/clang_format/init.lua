local M = {}

-- Function to find .clang-format file
function M.find_clang_format()
    local current_dir = vim.fn.expand('%:p:h')
    
    while current_dir ~= '/' do
        local format_file = current_dir .. '/.clang-format'
        if vim.fn.filereadable(format_file) == 1 then
            return format_file
        end
        current_dir = vim.fn.fnamemodify(current_dir, ':h')
    end
    return nil
end

-- Parse relevant settings from .clang-format
local function parse_clang_format(file_path)
    local settings = {}
    local file = io.open(file_path, "r")
    if not file then 
        return nil
    end

    for line in file:lines() do
        -- Remove leading/trailing whitespace
        line = line:match("^%s*(.-)%s*$")
        
        -- Parse IndentWidth
        local indent_width = line:match("^IndentWidth:%s*(%d+)")
        if indent_width then
            settings.indent_width = tonumber(indent_width)
        end

        -- Parse UseTab
        local use_tab = line:match("^UseTab:%s*(%w+)")
        if use_tab then
            settings.use_tab = use_tab
        end

        -- Parse TabWidth
        local tab_width = line:match("^TabWidth:%s*(%d+)")
        if tab_width then
            settings.tab_width = tonumber(tab_width)
        end
    end
    
    file:close()
    return settings
end

-- Apply clang-format settings to buffer
function M.setup_buffer_indentation()
    vim.schedule(function()
        local format_file = M.find_clang_format()
        if not format_file then
            return
        end

        local settings = parse_clang_format(format_file)
        if not settings then
            return
        end

        -- Set indent width (number of spaces for each indentation level)
        if settings.indent_width then
            vim.bo.shiftwidth = settings.indent_width
        end

        -- Set tab behavior
        if settings.use_tab then
            if settings.use_tab == "Never" then
                vim.bo.expandtab = true
            elseif settings.use_tab == "Always" or settings.use_tab == "ForIndentation" then
                vim.bo.expandtab = false
            end
        end

        -- Set tab width
        if settings.tab_width then
            vim.bo.tabstop = settings.tab_width
            vim.bo.softtabstop = settings.tab_width
        end
    end)
end

return M
