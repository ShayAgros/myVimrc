-- Review mode: K keymap in diffview shows context from llm_diff_context.diffcon
local M = {}

local function parse_diffcon(filepath)
    local entries = {}
    local file = io.open(filepath, "r")
    if not file then return nil end
    for line in file:lines() do
        if not line:match("^#") and line:match("|") then
            local loc, explanation = line:match("^(.-)%s*|%s*(.+)$")
            if loc and explanation then
                local path, start_l, end_l = loc:match("^(.+):(%d+)-(%d+)$")
                if path then
                    table.insert(entries, {
                        path = path,
                        start_line = tonumber(start_l),
                        end_line = tonumber(end_l),
                        text = explanation,
                    })
                end
            end
        end
    end
    file:close()
    return entries
end

local function find_diffcon()
    -- Try from cwd first
    local found = vim.fs.find("llm_diff_context.diffcon", {
        upward = true, path = vim.fn.getcwd(), type = "file",
    })
    if found[1] then return found[1] end
    -- Try from the buffer's actual path (strip diffview:// prefix)
    local bufname = vim.api.nvim_buf_get_name(0):gsub("^diffview://", "")
    local bufdir = vim.fn.fnamemodify(bufname, ":h")
    if bufdir and bufdir ~= "" then
        found = vim.fs.find("llm_diff_context.diffcon", {
            upward = true, path = bufdir, type = "file",
        })
    end
    return found[1]
end

local function get_relative_path(bufname)
    local cwd = vim.fn.getcwd() .. "/"
    if bufname:sub(1, #cwd) == cwd then
        return bufname:sub(#cwd + 1)
    end
    -- diffview old-version buffers: diffview:///abs/path/.git/HASH/relative/path
    local rel = bufname:match("%.git/[^/]+/(.+)$")
    if rel then return rel end
    -- fallback
    return vim.fn.fnamemodify(bufname, ":.")
end

-- Parse git diff hunks for a file, returns list of {old_start, old_count, new_start, new_count}
local function parse_diff_hunks(repo_root, filepath)
    local cmd = string.format("git -C %s diff HEAD~1 -- %s", vim.fn.shellescape(repo_root), vim.fn.shellescape(filepath))
    local output = vim.fn.system(cmd)
    local hunks = {}
    for old_start, old_count, new_start, new_count in output:gmatch("@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@") do
        table.insert(hunks, {
            old_start = tonumber(old_start),
            old_count = tonumber(old_count ~= "" and old_count or "1"),
            new_start = tonumber(new_start),
            new_count = tonumber(new_count ~= "" and new_count or "1"),
        })
    end
    return hunks
end

-- Determine if buffer is the old (left) side of a diffview split
local function is_old_buffer(bufname)
    return bufname:match("^diffview://") and bufname:match("%.git/[^/]+/") ~= nil
end

-- Map an old-file line to the corresponding new-file line range via diff hunks
local function old_line_to_new(hunks, old_line)
    for _, h in ipairs(hunks) do
        local old_end = h.old_start + h.old_count - 1
        if old_line >= h.old_start and old_line <= old_end then
            -- Line is inside this hunk — map to the new side
            return h.new_start, h.new_start + h.new_count - 1
        end
    end
    return nil
end

local function find_context_for_line(entries, filepath, line, repo_root)
    -- Try direct match first (works for new-file side)
    for _, entry in ipairs(entries) do
        if filepath:match(entry.path .. "$") then
            if line >= entry.start_line and line <= entry.end_line then
                return entry
            end
        end
    end

    -- If on old-file buffer, map line through diff hunks to new-file coordinates
    local bufname = vim.api.nvim_buf_get_name(0)
    if is_old_buffer(bufname) then
        local hunks = parse_diff_hunks(repo_root, filepath)
        local new_start, new_end = old_line_to_new(hunks, line)
        if new_start then
            for _, entry in ipairs(entries) do
                if filepath:match(entry.path .. "$") then
                    -- Check if the mapped new-file range overlaps with the entry
                    if new_start <= entry.end_line and new_end >= entry.start_line then
                        return entry
                    end
                end
            end
        end
    end

    -- Proximity fallback: within 5 lines
    local best, best_dist = nil, math.huge
    for _, entry in ipairs(entries) do
        if filepath:match(entry.path .. "$") then
            local dist = math.min(math.abs(line - entry.start_line), math.abs(line - entry.end_line))
            if dist < best_dist then
                best, best_dist = entry, dist
            end
        end
    end
    if best and best_dist <= 5 then return best end
    return nil
end

local active_float = nil

local function close_float()
    if active_float and vim.api.nvim_win_is_valid(active_float) then
        vim.api.nvim_win_close(active_float, true)
    end
    active_float = nil
end

local function show_floating(text)
    local lines = {}
    for segment in text:gmatch("[^\n]+") do
        local current = ""
        for word in segment:gmatch("%S+") do
            if #current + #word + 1 > 72 then
                table.insert(lines, current)
                current = word
            else
                current = current == "" and word or (current .. " " .. word)
            end
        end
        if current ~= "" then table.insert(lines, current) end
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

    local width = math.min(74, vim.o.columns - 4)
    local height = math.min(#lines, 15)
    active_float = vim.api.nvim_open_win(buf, false, {
        relative = "cursor",
        row = 1,
        col = 0,
        width = width,
        height = height,
        style = "minimal",
        border = "rounded",
    })

    vim.keymap.set("n", "q", close_float, { buffer = buf, nowait = true })
    vim.keymap.set("n", "<Esc>", close_float, { buffer = buf, nowait = true })

    -- Close on cursor move in the parent buffer (not inside the float)
    local parent_buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_create_autocmd("CursorMoved", {
        buffer = parent_buf,
        callback = close_float,
        once = true,
    })
end

function M.show_diff_context()
    -- Toggle: if float is open, jump into it
    if active_float and vim.api.nvim_win_is_valid(active_float) then
        vim.api.nvim_set_current_win(active_float)
        return
    end

    local diffcon_path = find_diffcon()
    if not diffcon_path then
        vim.notify("No llm_diff_context.diffcon found", vim.log.levels.WARN)
        return
    end

    local entries = parse_diffcon(diffcon_path)
    if not entries then
        vim.notify("Failed to parse diffcon file", vim.log.levels.ERROR)
        return
    end

    local bufname = vim.api.nvim_buf_get_name(0)
    local filepath = get_relative_path(bufname)
    local line = vim.fn.line(".")

    local entry = find_context_for_line(entries, filepath, line, vim.fn.fnamemodify(diffcon_path, ":h"))
    if entry then
        show_floating(entry.text)
    else
        vim.notify("No context for this line", vim.log.levels.INFO)
    end
end

function M.setup()
    vim.g.review_mode = true

    -- Set cc keymap in diff buffers
    vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("ReviewMode", { clear = true }),
        callback = function()
            if vim.wo.diff or vim.bo.filetype == "DiffviewFiles" or vim.g.review_mode then
                vim.keymap.set("n", "cc", M.show_diff_context, { buffer = true, desc = "Show diff context" })
            end
        end,
    })
end

return M
