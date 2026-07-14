-- vreview.store: on-disk persistence for offline code review.
--
-- Layout (under stdpath("data")/vreview/):
--   INDEX                 jsonl, one {id=<n>, repo=<abs git toplevel>} per line
--   <id>/meta.json        review metadata (repo, base, range, CR number/revision)
--   <id>/comments.jsonl   one JSON object per comment (multi-line markdown bodies,
--                         `parent` links a reply to an existing comment)
--   <id>/review.md        human-readable render, regenerated on every write
--
-- The repo path is NEVER encoded into a filename (Linux path length / illegal
-- chars). The INDEX maps an absolute git toplevel to an opaque numeric dir id.

local M = {}

-- Monotonic counter so two comments created in the same second never collide.
local id_counter = 0

local function data_root()
    -- VREVIEW_DATA_DIR lets tests isolate storage without moving the whole
    -- nvim data dir (which would trigger plugin re-cloning).
    local override = vim.env.VREVIEW_DATA_DIR
    if override and override ~= "" then return override end
    return vim.fn.stdpath("data") .. "/vreview"
end

local function index_path()
    return data_root() .. "/INDEX"
end

local function ensure_dir(path)
    vim.fn.mkdir(path, "p")
end

-- Read the whole contents of a file, or nil.
local function read_file(path)
    local fd = io.open(path, "r")
    if not fd then return nil end
    local data = fd:read("*a")
    fd:close()
    return data
end

local function write_file(path, data)
    local fd = io.open(path, "w")
    if not fd then return false end
    fd:write(data)
    fd:close()
    return true
end

local function append_line(path, line)
    local fd = io.open(path, "a")
    if not fd then return false end
    fd:write(line .. "\n")
    fd:close()
    return true
end

-- Parse an INDEX file into a list of {id=number, repo=string}.
local function read_index()
    local entries = {}
    local data = read_file(index_path())
    if not data then return entries end
    for line in data:gmatch("[^\n]+") do
        local ok, obj = pcall(vim.json.decode, line)
        if ok and type(obj) == "table" and obj.id and obj.repo then
            table.insert(entries, obj)
        end
    end
    return entries
end

-- Resolve (creating if needed) the review directory for a git toplevel.
-- Returns the absolute directory path.
function M.review_dir(repo_root)
    repo_root = vim.fn.fnamemodify(repo_root, ":p"):gsub("/$", "")
    ensure_dir(data_root())

    local entries = read_index()
    local max_id = 0
    for _, e in ipairs(entries) do
        if e.repo == repo_root then
            local dir = data_root() .. "/" .. e.id
            ensure_dir(dir)
            return dir
        end
        if e.id > max_id then max_id = e.id end
    end

    local id = max_id + 1
    append_line(index_path(), vim.json.encode({ id = id, repo = repo_root }))
    local dir = data_root() .. "/" .. id
    ensure_dir(dir)
    return dir
end

-- Write/merge review metadata. `meta` is a table; existing keys are preserved
-- unless overwritten.
function M.write_meta(repo_root, meta)
    local dir = M.review_dir(repo_root)
    local path = dir .. "/meta.json"
    local existing = {}
    local data = read_file(path)
    if data then
        local ok, obj = pcall(vim.json.decode, data)
        if ok and type(obj) == "table" then existing = obj end
    end
    for k, v in pairs(meta) do existing[k] = v end
    write_file(path, vim.json.encode(existing))
    return existing
end

function M.read_meta(repo_root)
    local dir = M.review_dir(repo_root)
    local data = read_file(dir .. "/meta.json")
    if not data then return {} end
    local ok, obj = pcall(vim.json.decode, data)
    if ok and type(obj) == "table" then return obj end
    return {}
end

-- Load all comments for a repo as a list of tables (file order preserved).
function M.load_comments(repo_root)
    local dir = M.review_dir(repo_root)
    local comments = {}
    local data = read_file(dir .. "/comments.jsonl")
    if not data then return comments end
    for line in data:gmatch("[^\n]+") do
        local ok, obj = pcall(vim.json.decode, line)
        if ok and type(obj) == "table" then
            table.insert(comments, obj)
        end
    end
    return comments
end

-- True if this repo has at least one stored comment (used to mark reviewed
-- packages in the review-order window).
function M.has_comments(repo_root)
    local dir = M.review_dir(repo_root)
    local data = read_file(dir .. "/comments.jsonl")
    return data ~= nil and data:match("%S") ~= nil
end

-- Append one comment. `c` fields:
--   commit (string: short hash or range), file (repo-relative), side ("new"|"old"),
--   start_line, end_line (numbers), body (string, may be multi-line markdown),
--   parent (optional id of the comment this replies to)
-- Fills id/ts automatically. Returns the stored comment (with id/ts).
function M.add_comment(repo_root, c)
    local dir = M.review_dir(repo_root)
    id_counter = id_counter + 1
    c.id = c.id or string.format("%d-%d", os.time(), id_counter)
    c.ts = c.ts or os.date("!%Y-%m-%dT%H:%M:%SZ")
    append_line(dir .. "/comments.jsonl", vim.json.encode(c))
    M.regenerate_markdown(repo_root)
    return c
end

-- Rewrite the entire comments.jsonl from a list (used for edits/deletes).
function M.rewrite_comments(repo_root, comments)
    local dir = M.review_dir(repo_root)
    local lines = {}
    for _, c in ipairs(comments) do
        table.insert(lines, vim.json.encode(c))
    end
    write_file(dir .. "/comments.jsonl", table.concat(lines, "\n") .. (next(lines) and "\n" or ""))
    M.regenerate_markdown(repo_root)
end

-- Update the body of an existing comment (by id). Returns true if found.
function M.update_comment(repo_root, id, body)
    local comments = M.load_comments(repo_root)
    local changed = false
    for _, c in ipairs(comments) do
        if c.id == id then
            c.body = body
            c.edited_ts = os.date("!%Y-%m-%dT%H:%M:%SZ")
            changed = true
            break
        end
    end
    if changed then M.rewrite_comments(repo_root, comments) end
    return changed
end

-- Delete a comment (by id). Returns true if found. Any replies to it are
-- re-parented to nil (kept as top-level) so nothing is silently lost.
function M.delete_comment(repo_root, id)
    local comments = M.load_comments(repo_root)
    local kept, found = {}, false
    for _, c in ipairs(comments) do
        if c.id == id then
            found = true
        else
            if c.parent == id then c.parent = nil end
            table.insert(kept, c)
        end
    end
    if found then M.rewrite_comments(repo_root, kept) end
    return found
end

-- Render a location label like "src/x.cc:10-14" or "src/x.cc:12".
local function loc_label(c)
    if c.start_line == c.end_line then
        return string.format("%s:%d", c.file, c.start_line)
    end
    return string.format("%s:%d-%d", c.file, c.start_line, c.end_line)
end

-- Regenerate the human-readable review.md, grouped by commit/range then file,
-- with threaded replies nested underneath their parent.
function M.regenerate_markdown(repo_root)
    local dir = M.review_dir(repo_root)
    local meta = M.read_meta(repo_root)
    local comments = M.load_comments(repo_root)

    -- Index by id and collect children so replies render under their parent.
    local by_id = {}
    for _, c in ipairs(comments) do by_id[c.id] = c end
    local children = {}
    local roots = {}
    for _, c in ipairs(comments) do
        if c.parent and by_id[c.parent] then
            children[c.parent] = children[c.parent] or {}
            table.insert(children[c.parent], c)
        else
            table.insert(roots, c)
        end
    end

    -- Group roots by commit scope, then by file.
    local scopes = {}          -- scope -> { files = {file -> {comments}}, order = {} }
    local scope_order = {}
    for _, c in ipairs(roots) do
        local scope = c.commit or "(unspecified)"
        if not scopes[scope] then
            scopes[scope] = { files = {}, file_order = {} }
            table.insert(scope_order, scope)
        end
        local s = scopes[scope]
        if not s.files[c.file] then
            s.files[c.file] = {}
            table.insert(s.file_order, c.file)
        end
        table.insert(s.files[c.file], c)
    end

    local out = {}
    local function emit(line) table.insert(out, line) end

    emit("# Code Review")
    emit("")
    if meta.cr_number then
        local rev = meta.cr_revision and (" (revision " .. meta.cr_revision .. ")") or ""
        emit(string.format("- **CR**: %s%s", meta.cr_number, rev))
    end
    if meta.base_branch then emit("- **Base branch**: " .. meta.base_branch) end
    if meta.range then emit("- **Range**: " .. meta.range) end
    if meta.repo then emit("- **Repo**: " .. meta.repo) end
    emit("")

    local function render_comment(c, depth)
        local indent = string.rep("  ", depth)
        local body_lines = vim.split(c.body or "", "\n", { plain = true })
        -- First line gets the bullet; continuation lines align under it.
        emit(indent .. "- " .. (body_lines[1] or ""))
        for i = 2, #body_lines do
            emit(indent .. "  " .. body_lines[i])
        end
        for _, reply in ipairs(children[c.id] or {}) do
            render_comment(reply, depth + 1)
        end
    end

    for _, scope in ipairs(scope_order) do
        emit("## " .. scope)
        emit("")
        local s = scopes[scope]
        for _, file in ipairs(s.file_order) do
            local list = s.files[file]
            table.sort(list, function(a, b) return (a.start_line or 0) < (b.start_line or 0) end)
            for _, c in ipairs(list) do
                emit(string.format("### %s", loc_label(c)))
                emit("")
                render_comment(c, 0)
                emit("")
            end
        end
    end

    write_file(dir .. "/review.md", table.concat(out, "\n") .. "\n")
end

return M
