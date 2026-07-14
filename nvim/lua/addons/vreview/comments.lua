-- vreview.comments: leave/browse review comments from within diffview.
--
--   C  (normal)  -> comment on the current line
--   C  (visual)  -> comment on the selected whole-line range
--
-- Opens a markdown scratch split at the bottom. `:wq`/`:w` logs the comment;
-- `:q!` / empty body cancels. Commented lines get a gutter sign.

local store = require("addons.vreview.store")
local session = require("addons.vreview.session")

local M = {}

local SIGN_GROUP = "vreview_comments"
local SIGN_NAME = "VreviewComment"
local ns = vim.api.nvim_create_namespace("vreview_comments")

-- ---------------------------------------------------------------------------
-- Buffer -> (repo-relative file, side) resolution for diffview buffers.
-- ---------------------------------------------------------------------------

-- Old (left) side buffers look like: diffview://<repo>/.git/<hash>/<relpath>
-- New (right) side buffers are ordinary files under the repo.
local function is_old_side(bufname)
    return bufname:match("^diffview://") ~= nil and bufname:match("%.git/[^/]+/") ~= nil
end

local function relative_path(repo, bufname)
    local rel = bufname:match("%.git/[^/]+/(.+)$")
    if rel then return rel end
    local prefix = repo:gsub("/$", "") .. "/"
    if bufname:sub(1, #prefix) == prefix then
        return bufname:sub(#prefix + 1)
    end
    return vim.fn.fnamemodify(bufname, ":.")
end

-- Resolve the repo root for the current buffer: session first, else git.
local function resolve_repo()
    local s = session.get()
    if s and s.repo then return s.repo end
    local bufname = vim.api.nvim_buf_get_name(0):gsub("^diffview://", "")
    local dir = vim.fn.fnamemodify(bufname, ":h")
    local git = require("addons.vreview.git")
    return git.toplevel(dir ~= "" and dir or vim.fn.getcwd())
end

-- ---------------------------------------------------------------------------
-- Signs
-- ---------------------------------------------------------------------------

local function ensure_sign_defined()
    if vim.tbl_isempty(vim.fn.sign_getdefined(SIGN_NAME)) then
        vim.fn.sign_define(SIGN_NAME, {
            text = "▌",
            texthl = "VreviewCommentSign",
            numhl = "VreviewCommentNum",   -- colors the line NUMBER of commented lines
        })
    end
end

-- Place gutter signs for every stored comment whose file matches this buffer.
function M.refresh_signs(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local repo = resolve_repo()
    if not repo then return end
    ensure_sign_defined()
    vim.fn.sign_unplace(SIGN_GROUP, { buffer = bufnr })

    local bufname = vim.api.nvim_buf_get_name(bufnr)
    if bufname == "" then return end
    local relfile = relative_path(repo, bufname)
    local side = is_old_side(bufname) and "old" or "new"

    for _, c in ipairs(store.load_comments(repo)) do
        if c.file == relfile and (c.side or "new") == side and not c.parent then
            for ln = c.start_line, c.end_line do
                pcall(vim.fn.sign_place, 0, SIGN_GROUP, SIGN_NAME, bufnr,
                    { lnum = ln, priority = 20 })
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Comment capture split
-- ---------------------------------------------------------------------------

-- Open a markdown scratch buffer at the bottom.
--   on_submit(body)  called when the user writes a NON-EMPTY buffer.
--   on_empty()       (optional) called when the user writes an EMPTY buffer —
--                    used by edit mode to delete the comment. When nil, writing
--                    an empty buffer does nothing (create mode).
local function open_capture(header_lines, seed, on_submit, on_empty)
    vim.cmd("botright 12split")
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, buf)
    local win = vim.api.nvim_get_current_win()

    vim.bo[buf].buftype = "acwrite"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].filetype = "markdown"
    vim.bo[buf].swapfile = false
    vim.api.nvim_buf_set_name(buf, "vreview://comment/" .. buf)

    -- Header comment lines (markdown comments, stripped on save) + optional seed.
    local content = {}
    for _, h in ipairs(header_lines) do
        table.insert(content, "<!-- " .. h .. " -->")
    end
    table.insert(content, "")
    for _, l in ipairs(seed or {}) do table.insert(content, l) end
    -- Guarantee at least one writable (empty) line after the header block.
    if not seed or #seed == 0 then table.insert(content, "") end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
    vim.bo[buf].modified = false

    -- Put the cursor on the first writable line (clamped to buffer length).
    local target = math.min(#header_lines + 2, vim.api.nvim_buf_line_count(buf))
    vim.api.nvim_win_set_cursor(win, { target, 0 })
    vim.cmd("startinsert")

    local submitted = false
    local function collect_body()
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local body = {}
        for _, l in ipairs(lines) do
            if not l:match("^%s*<!%-%-.*%-%->%s*$") then
                table.insert(body, l)
            end
        end
        -- Trim leading/trailing blank lines.
        while #body > 0 and body[1]:match("^%s*$") do table.remove(body, 1) end
        while #body > 0 and body[#body]:match("^%s*$") do table.remove(body) end
        return table.concat(body, "\n")
    end

    -- :w / :wq -> submit (non-empty) or delete (empty, edit mode only)
    vim.api.nvim_create_autocmd("BufWriteCmd", {
        buffer = buf,
        callback = function()
            local body = collect_body()
            vim.bo[buf].modified = false
            if not submitted then
                if body ~= "" then
                    submitted = true
                    on_submit(body)
                elseif on_empty then
                    submitted = true
                    on_empty()
                end
            end
            -- Auto-dismiss the capture window after a plain `:w`. Deferred so we
            -- don't double-close on `:wq`/`:x`/ZZ: with those, the user's own
            -- quit closes THIS window first (leaving other windows intact), and
            -- this scheduled close then finds `win` already gone and no-ops.
            -- Closing synchronously here would let `:wq`'s quit phase fall
            -- through and close an unrelated window (e.g. the file panel).
            vim.schedule(function()
                if vim.api.nvim_win_is_valid(win) then
                    vim.api.nvim_win_close(win, true)
                end
            end)
        end,
    })

    -- Helpful footer keymaps: <C-c> cancels, gq submits.
    local opts = { buffer = buf, nowait = true, silent = true }
    vim.keymap.set({ "n", "i" }, "<C-c>", function()
        vim.cmd("stopinsert")
        if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
    end, opts)
end

-- ---------------------------------------------------------------------------
-- Public: leave a comment on the current line / visual range.
-- ---------------------------------------------------------------------------

-- Find the most recent top-level comment on this file/side whose line range
-- overlaps [start_line, end_line]. Returns the comment or nil. Scope-agnostic,
-- matching how gutter signs are shown (all comments on the line, any scope).
local function find_comment_on_range(repo, relfile, side, start_line, end_line)
    local match = nil
    for _, c in ipairs(store.load_comments(repo)) do
        if c.file == relfile and (c.side or "new") == side and not c.parent then
            -- Overlap test between [c.start_line, c.end_line] and [start_line, end_line].
            if c.start_line <= end_line and c.end_line >= start_line then
                match = c   -- keep last (comments.jsonl is append-order = chronological)
            end
        end
    end
    return match
end

-- Determine the whole-line range for the current normal line or visual span.
local function current_line_range(mode)
    if mode == "v" or mode == "V" or mode == "\22" then
        local s = vim.fn.line("v")
        local e = vim.fn.line(".")
        if s > e then s, e = e, s end
        return s, e
    end
    local l = vim.fn.line(".")
    return l, l
end

function M.leave_comment()
    -- Capture range BEFORE the mode changes (leaving visual mode).
    local mode = vim.fn.mode()
    local start_line, end_line = current_line_range(mode)
    -- Exit visual mode so the capture window opens cleanly.
    if mode:match("[vV\22]") then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
    end

    local repo = resolve_repo()
    if not repo then
        vim.notify("vreview: not inside a git repo", vim.log.levels.WARN)
        return
    end

    local bufname = vim.api.nvim_buf_get_name(0)
    local relfile = relative_path(repo, bufname)
    local side = is_old_side(bufname) and "old" or "new"
    local commit = session.active_commit_tag()
    local target_buf = vim.api.nvim_get_current_buf()

    local function refresh()
        if vim.api.nvim_buf_is_valid(target_buf) then
            M.refresh_signs(target_buf)
        end
    end

    -- Editing an existing comment? If the cursor line (or visual range) overlaps
    -- a stored comment on this file/side, edit that one instead of creating new.
    local existing = find_comment_on_range(repo, relfile, side, start_line, end_line)

    if existing then
        local eloc = (existing.start_line == existing.end_line)
            and string.format("%s:%d", relfile, existing.start_line)
            or string.format("%s:%d-%d", relfile, existing.start_line, existing.end_line)
        local seed = vim.split(existing.body or "", "\n", { plain = true })

        open_capture({
            "vreview EDIT comment  (write to save, empty buffer = DELETE, <C-c> = cancel)",
            "scope: " .. (existing.commit or "?") .. "   side: " .. side,
            "loc:   " .. eloc,
        }, seed, function(body)
            store.update_comment(repo, existing.id, body)
            vim.notify(string.format("vreview: comment updated on %s", eloc), vim.log.levels.INFO)
            refresh()
        end, function()
            store.delete_comment(repo, existing.id)
            vim.notify(string.format("vreview: comment deleted on %s", eloc), vim.log.levels.INFO)
            refresh()
        end)
        return
    end

    local loc = (start_line == end_line)
        and string.format("%s:%d", relfile, start_line)
        or string.format("%s:%d-%d", relfile, start_line, end_line)

    open_capture({
        "vreview comment  (write to save, <C-c> to cancel; markdown OK)",
        "scope: " .. commit .. "   side: " .. side,
        "loc:   " .. loc,
    }, nil, function(body)
        store.add_comment(repo, {
            commit = commit,
            file = relfile,
            side = side,
            start_line = start_line,
            end_line = end_line,
            body = body,
        })
        vim.notify(string.format("vreview: comment saved on %s", loc), vim.log.levels.INFO)
        refresh()
    end)
end

return M
