-- vreview.git: git helpers for the review plugin.

local M = {}

-- Run a git command in `repo` and return trimmed stdout (or "" on failure).
local function git(repo, args)
    local cmd = { "git", "-C", repo }
    for _, a in ipairs(args) do table.insert(cmd, a) end
    local out = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then return "" end
    return (out:gsub("%s+$", ""))
end
M.git = git

-- Absolute git toplevel for a path, or nil.
function M.toplevel(path)
    local root = git(path, { "rev-parse", "--show-toplevel" })
    if root == "" then return nil end
    return root
end

-- Current branch short name, or "" (detached).
function M.current_branch(repo)
    return git(repo, { "symbolic-ref", "--short", "HEAD" })
end

-- Extract the base branch from a CRUX/CR-XXXXXXXX/rN/<base> branch name.
-- Returns base_branch, cr_number, cr_revision (any may be nil).
function M.parse_cr_branch(branch)
    if not branch:match("^CRUX/CR%-") then return nil, nil, nil end
    local cr, rev, base = branch:match("^CRUX/(CR%-[^/]+)/(r%w+)/(.+)$")
    return base, cr, rev
end

-- Resolve a rev-ish to a full 40-char hash (or "" on failure).
function M.rev_parse(repo, revish)
    return git(repo, { "rev-parse", revish })
end

-- List commits in a range (e.g. "HEAD~2..HEAD"), oldest first.
-- Returns a list of { hash = <full>, short = <abbrev>, title = <subject> }.
-- Accepts either a range string or a single ref (treated as <ref>..HEAD).
function M.commits_in_range(repo, range)
    local rangespec = range
    if not range:find("%.%.") then
        -- A single ref given to vreview means "from this ref up to HEAD".
        rangespec = range .. "..HEAD"
    end
    -- Unit-separated fields, record-separated lines, to survive any subject text.
    local fmt = "%H%x1f%h%x1f%s"
    local out = git(repo, { "log", "--reverse", "--no-color", "--format=" .. fmt, rangespec })
    local commits = {}
    if out == "" then return commits, rangespec end
    for line in out:gmatch("[^\n]+") do
        local hash, short, title = line:match("^(.-)\31(.-)\31(.*)$")
        if hash and hash ~= "" then
            table.insert(commits, { hash = hash, short = short, title = title })
        end
    end
    return commits, rangespec
end

-- The diff spec that isolates a single commit's changes: <hash>^!.
-- (Equivalent to <hash>~1..<hash> but also works for root commits.)
function M.commit_isolation_spec(hash)
    return hash .. "^!"
end

return M
