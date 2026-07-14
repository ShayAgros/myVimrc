-- vreview.session: per-tab review state shared across the plugin modules.
--
-- Holds, for the current review: the repo root, the review range, the ordered
-- commit list, and which "scope" is currently being reviewed. The scope drives
-- both the diffview that is shown and the commit tag written onto new comments.
--
--   scope index 0        -> whole range   (comments tagged with the range string)
--   scope index 1..N     -> commits[i]    (comments tagged with commits[i].short)

local git = require("addons.vreview.git")

local M = {}

-- state, keyed by tabpage id, so multiple reviews can coexist in separate tabs.
-- diffview opens each view in its OWN tab (`tab split`), so a freshly-built
-- session starts life "pending" and is bound to the diffview tab once its view
-- opens (see M.bind_current_tab).
M.state = {}
M.pending = nil

-- Build (but don't yet tab-bind) a review session.
-- `range` is the raw ref/range passed to vreview (may be nil for working-tree).
-- `diffview_arg` is the exact argument to hand to :DiffviewOpen for the whole
-- view (preserves original semantics, e.g. a base branch vs working tree).
-- `opts` (optional): { cpath = <package repo path for DiffviewOpen -C>,
--                      pkg_name = <display name> }
function M.init(repo_root, range, diffview_arg, opts)
    opts = opts or {}
    local commits, rangespec = {}, nil
    if range and range ~= "" then
        commits, rangespec = git.commits_in_range(repo_root, range)
    end
    -- With exactly one commit the whole-range view and the single-commit view
    -- are identical, so there's nothing to cycle. Default the active scope to
    -- that commit (highlight it) and leave the range row as informational only.
    local scope_idx = (#commits == 1) and 1 or 0

    M.pending = {
        repo = repo_root,
        raw_range = range,
        range = rangespec,          -- normalized "a..b" or nil
        diffview_arg = diffview_arg or "", -- whole-view :DiffviewOpen argument
        cpath = opts.cpath,         -- package repo path for DiffviewOpen -C (or nil)
        pkg_name = opts.pkg_name,   -- display name of the package under review
        commits = commits,          -- oldest first
        scope_idx = scope_idx,      -- 0 = whole range, i = commits[i]
    }
    return M.pending
end

-- Can the current session cycle scopes? Only meaningful with >1 commit (a
-- single commit's isolated diff equals the whole-range diff).
function M.can_cycle()
    local s = M.get() or M.pending
    return s ~= nil and #s.commits > 1
end

-- Bind the pending session (or the existing one) to the current tabpage.
-- Called when diffview's view opens in its own tab. Idempotent.
function M.bind_current_tab()
    local tab = vim.api.nvim_get_current_tabpage()
    if M.state[tab] then return M.state[tab] end
    if M.pending then
        M.state[tab] = M.pending
        M.pending = nil
    end
    return M.state[tab]
end

function M.get()
    return M.state[vim.api.nvim_get_current_tabpage()]
end

-- Drop the session for the current tab (on view close).
function M.clear_current_tab()
    M.state[vim.api.nvim_get_current_tabpage()] = nil
end

-- Move a session back to "pending" so it re-binds to the next diffview tab
-- (used when cycling scopes reopens diffview in a fresh tab).
function M.reopen(s)
    M.pending = s
    -- Detach it from its current tab so a stale binding doesn't linger.
    for tab, st in pairs(M.state) do
        if st == s then M.state[tab] = nil end
    end
end

-- The commit tag a new comment should carry, given the active scope.
-- Whole-range view -> the range string (so a comment on an unchanged line is
-- clearly "part of reviewing this branch" rather than pinned to one commit).
-- Single-commit view -> that commit's short hash.
function M.active_commit_tag()
    local s = M.get()
    if not s then
        -- No session (e.g. plain `vreview -d`): fall back to HEAD short hash.
        return "working-tree"
    end
    if s.scope_idx == 0 then
        return s.range or (s.raw_range or "working-tree")
    end
    local c = s.commits[s.scope_idx]
    return c and c.short or s.range or "working-tree"
end

-- A human label for the current scope, for the commit panel / notifications.
function M.active_scope_label()
    local s = M.get()
    if not s then return "working tree" end
    if s.scope_idx == 0 then
        return "[whole] " .. (s.range or s.raw_range or "working tree")
    end
    local c = s.commits[s.scope_idx]
    if c then
        return string.format("commit %d/%d: %s", s.scope_idx, #s.commits, c.short)
    end
    return "[whole]"
end

-- Advance the scope to the next one (whole -> c1 -> c2 -> ... -> whole).
-- Returns the diffview spec to open for the new scope (string), or "" for the
-- whole-range/working-tree case (caller decides how to open).
function M.cycle_next()
    local s = M.get()
    if not s then return nil end
    local n = #s.commits
    if n == 0 then return nil end
    s.scope_idx = (s.scope_idx + 1) % (n + 1)
    if s.scope_idx == 0 then
        return s.range or s.raw_range or ""
    end
    return git.commit_isolation_spec(s.commits[s.scope_idx].hash)
end

return M
