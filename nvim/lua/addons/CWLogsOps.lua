function GetCloudWatchLink()
    local row, _ = unpack(vim.api.nvim_win_get_cursor(0))

    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)

    -- Search for the expression 'dom:[number]'
    local dom = string.match(line[1], "dom:(%d+)")

    if not dom then
        print("Couldn't extract dom from line")
        return
    end

    local file_path = vim.api.nvim_buf_get_name(0)
    local file_name = string.match(file_path, "([^/]+)$")
    print("dom is", dom, "file name", file_name)
    if not file_name then
        print("Couldn't extract filename from", file_path)
        return
    end

    local _, j, starttime_d, starttime_t = string.find(file_name, "(%d+)-(%d+)")
    local endtime_d, endtime_t = string.match(file_name, "(%d+)-(%d+)", j + 1)

    if not (starttime_t and starttime_d and endtime_d and endtime_t) then
        print("Couldn't extract time range from file name")
        return
    end

    local az = string.match(file_path, "/([^/]+)/[^/]+/[^/]+$")
    if not az then
        print("Couldn't extract az from file path", file_path)
        return
    end

    local efa_tool_cmd = "efa_tool cw" .. " -z " .. az .. " -c " .. string.format("dom-%s", dom)
    efa_tool_cmd = efa_tool_cmd .. " -s " .. starttime_d .. "T" .. starttime_t
    efa_tool_cmd = efa_tool_cmd .. " -e " .. endtime_d .. "T" .. endtime_t

    print("(Copied to clipboard)", efa_tool_cmd)
    vim.fn.setreg("+", efa_tool_cmd)
end
