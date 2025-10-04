-- Generic function to get custom icon
local function get_custom_icon(file_path, file_type)
    if file_type == "test" then
        return "T", "SnacksPickerFile"
    elseif file_path:match("mysql%-test") and (file_path:match("%.result$") or file_path:match("%.test$") or file_path:match("%.opt$")) then
        return "T", "SnacksPickerFile"
    end
    return nil
end

---@param item snacks.picker.Item
---@param picker snacks.Picker
---@return snacks.picker.Highlight[]
local function Shayagr_format_brazil_ws(item, picker)
    ---@type snacks.picker.Highlight[]
    local ret = {}

    if item.file then
        local path = item.file
        local abs_path = vim.fn.getcwd() .. "/" .. path

        -- Check for Brazil workspace pattern in absolute path: .../WORKSPACE/src/REPO/...
        local workspace, repo, rest = abs_path:match(".*/([^/]+)/src/([^/]+)/(.+)$")

        -- Transform src/[package]/main/java/[rest] -> [package]//[rest] (for search results)
        local package_name, file_type, rest_of_path = path:match("^src/([^/]+)/([^/]+)/java/(.+)$")

        -- Add icon
        if picker.opts.icons.files.enabled ~= false then
            local icon, hl = get_custom_icon(abs_path, file_type)
            if not icon then
                icon, hl = Snacks.util.icon(item.file, "file")
            end
            ret[#ret + 1] = { Snacks.picker.util.align(icon, 4), hl, virtual = true }
        end

        if workspace and repo and rest then
            -- Brazil workspace format: 🇧🇷 [workspace] [repo]/[path]
            ret[#ret + 1] = { "🇧🇷 ", "SnacksPickerDelim", field = "file" }
            ret[#ret + 1] = { workspace, "CustomPackageName", field = "file" }
            ret[#ret + 1] = { " ", "SnacksPickerDelim", field = "file" }
            ret[#ret + 1] = { repo, "CustomPackageName", field = "file" }
            ret[#ret + 1] = { "/", "SnacksPickerDelim", field = "file" }
            ret[#ret + 1] = { rest, "SnacksPickerFile", field = "file" }
        elseif package_name and file_type and rest_of_path then
            -- Custom highlight group for package name
            vim.api.nvim_set_hl(0, "CustomPackageName", { fg = "#B64DEB", bold = true })
            -- Java package format: [package]//[rest]
            ret[#ret + 1] = { package_name, "CustomPackageName", field = "file" }
            ret[#ret + 1] = { "//", "SnacksPickerDelim", field = "file" }
            ret[#ret + 1] = { rest_of_path, "SnacksPickerFile", field = "file" }
        else
            -- Normal path
            ret[#ret + 1] = { path, "SnacksPickerFile", field = "file" }
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

return {
    Shayagr_format_brazil_ws = Shayagr_format_brazil_ws,
}
