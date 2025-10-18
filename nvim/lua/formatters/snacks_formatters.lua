-- Utility function to format Brazil workspace paths
local function format_brazil_path(path)
    local abs_path = vim.fn.getcwd() .. "/" .. path

    -- Check for Brazil workspace pattern
    local workspace, repo, rest = abs_path:match(".*/([^/]+)/src/([^/]+)/(.+)$")

    -- Also check for Java package pattern
    local package_name, file_type, rest_of_path = path:match("^src/([^/]+)/([^/]+)/java/(.+)$")

    if workspace and repo and rest then
        return {
            type = "brazil",
            workspace = workspace,
            repo = repo,
            rest = rest
        }
    elseif package_name and file_type and rest_of_path then
        return {
            type = "java",
            package = package_name,
            file_type = file_type,
            path = rest_of_path
        }
    else
        -- Replace $HOME with house emoji for regular paths
        local home = vim.fn.expand('$HOME') .. "/"
        path = path:gsub(home, "🏠//")
        return {
            type = "regular",
            path = path
        }
    end
end

-- Generic function to get custom icon
function get_custom_icon(file_path, file_type)
    if file_type == "test" then
        return "T", "SnacksPickerFile"
    elseif file_path:match("mysql%-test") and (file_path:match("%.result$") or file_path:match("%.test$") or file_path:match("%.opt$") or file_path:match("%.inc$")) then
        return "T", "SnacksPickerFile"
    end
    return nil
end

---@param item snacks.picker.Item
---@param picker snacks.Picker
---@return snacks.picker.Highlight[]
function Shayagr_format_brazil_ws(item, picker)
    ---@type snacks.picker.Highlight[]
    local ret = {}

    if item.file then
        local path = item.file
        local abs_path = vim.fn.getcwd() .. "/" .. path

        -- Add icon
        if picker.opts.icons.files.enabled ~= false then
            local icon, hl = get_custom_icon(abs_path, file_type)
            if not icon then
                icon, hl = Snacks.util.icon(item.file, "file")
            end
            ret[#ret + 1] = { Snacks.picker.util.align(icon, 4), hl, virtual = true }
        end

        local formatted = format_brazil_path(path)

        if formatted.type == "brazil" then
            ret[#ret + 1] = { "🇧🇷 ", "SnacksPickerDelim", field = "file" }
            ret[#ret + 1] = { formatted.workspace, "CustomPackageName", field = "file" }
            ret[#ret + 1] = { " ", "SnacksPickerDelim", field = "file" }
            ret[#ret + 1] = { formatted.repo, "CustomPackageName", field = "file" }
            ret[#ret + 1] = { "/", "SnacksPickerDelim", field = "file" }
            ret[#ret + 1] = { formatted.rest, "SnacksPickerFile", field = "file" }
        elseif formatted.type == "java" then
            -- Custom highlight group for package name
            vim.api.nvim_set_hl(0, "CustomPackageName", { fg = "#B64DEB", bold = true })
            ret[#ret + 1] = { formatted.package, "CustomPackageName", field = "file" }
            ret[#ret + 1] = { "//", "SnacksPickerDelim", field = "file" }
            ret[#ret + 1] = { formatted.path, "SnacksPickerFile", field = "file" }
        else
            ret[#ret + 1] = { formatted.path, "SnacksPickerFile", field = "file" }
        end

        -- Add position (for search results)
        if item.pos and item.pos[1] > 0 then
            ret[#ret + 1] = { ":" .. item.pos[1], "SnacksPickerRow" }
        end
        ret[#ret + 1] = { " " }
    end

    -- Add line content (for search results)
    if item.line then
        Snacks.picker.highlight.format(item, item.line, ret)
    end

    return ret
end

---@param item snacks.picker.Item
---@param picker snacks.Picker
---@return snacks.picker.Highlight[]
function Shayagr_format_buffers_in_brazil_ws(item, picker)
    ---@type snacks.picker.Highlight[]
    local ret = {}

    -- Add buffer number if available
    if item.info.bufnr then
        local buff_str = "#" .. item.info.bufnr .. " "
        ret[#ret + 1] = { Snacks.picker.util.align(buff_str, 5), "SnacksPickerDelim", field = "bufnr" }
    end

    -- Get the formatting from the base formatter
    local base_format = Shayagr_format_brazil_ws(item, picker)

    -- Combine the results
    for _, highlight in ipairs(base_format) do
        ret[#ret + 1] = highlight
    end

    return ret
end

function Shayagr_workspace_aware_file_preview(ctx)
    Snacks.picker.preview.file(ctx)
    local path = Snacks.picker.util.path(ctx.item)
    if path then
        local formatted = format_brazil_path(path)
        local title
        if formatted.type == "brazil" then
            title = string.format("🇧🇷 %s %s/%s",
                formatted.workspace,
                formatted.repo,
                formatted.rest)
        elseif formatted.type == "java" then
            title = string.format("%s//%s",
                formatted.package,
                formatted.path)
        else
            title = formatted.path
        end
        ctx.preview:set_title(title)
    end
end

function Shayagr_test_buffer()
    Snacks.picker.buffers({
        format = Shayagr_format_buffers_in_brazil_ws,
        preview = Shayagr_workspace_aware_file_preview,
        cwd = "/home/ANT.AMAZON.COM/shayagr/workspace/brazil/dev-kermit" })
end

return {
    Shayagr_format_brazil_ws = Shayagr_format_brazil_ws,
    Shayagr_format_buffers_in_brazil_ws = Shayagr_format_buffers_in_brazil_ws,
    Shayagr_workspace_aware_file_preview = Shayagr_workspace_aware_file_preview,
}
