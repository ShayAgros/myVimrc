-- vreview: offline code-review layer on top of diffview.nvim.
--
-- Entry point wired from the `vreview` shell script:
--   nvim -c "lua require('addons.vreview').start(<opts>)"
--
-- Features:
--   * C (normal/visual) leaves a markdown review comment, persisted per-project.
--   * A commit panel under diffview's file panel lists the range's commits;
--     <leader><Tab> cycles whole-range <-> each commit's isolated diff.
--   * cc still shows llm_diff_context.diffcon context (delegated to reviewMode).

local session = require("addons.vreview.session")
local panel = require("addons.vreview.panel")
local comments = require("addons.vreview.comments")
local store = require("addons.vreview.store")
local git = require("addons.vreview.git")

local M = {}

-- ---------------------------------------------------------------------------
-- Highlights (pretty, theme-aware via linking + subtle custom backgrounds)
-- ---------------------------------------------------------------------------
local function setup_highlights()
    local set = function(name, opts) vim.api.nvim_set_hl(0, name, opts) end
    -- Link where possible so the colorscheme drives the palette.
    set("VreviewPanelRange", { link = "Comment", default = true })
    set("VreviewPanelHash", { link = "Identifier", default = true })
    set("VreviewPanelTitle", { link = "Normal", default = true })
    set("VreviewCommentSign", { link = "DiagnosticSignInfo", default = true })

    -- Active row: a distinct highlighted band. Derive colors from existing
    -- groups so it fits any theme, with a visible background.
    local vis = vim.api.nvim_get_hl(0, { name = "Visual", link = false })
    local fn = vim.api.nvim_get_hl(0, { name = "Function", link = false })
    local kw = vim.api.nvim_get_hl(0, { name = "Keyword", link = false })
    local bg = vis.bg

    -- Line NUMBER color for commented lines: a bold warning-colored number so a
    -- commented line stands out in the number column. Falls back gracefully.
    local warn = vim.api.nvim_get_hl(0, { name = "DiagnosticWarn", link = false })
    set("VreviewCommentNum", { fg = warn.fg or "#e5c07b", bold = true, default = true })
    set("VreviewPanelActive", { bg = bg, bold = true, default = true })
    set("VreviewPanelActiveHash", { bg = bg, fg = fn.fg, bold = true, default = true })
    set("VreviewPanelArrow", { fg = (kw.fg or fn.fg), bg = bg, bold = true, default = true })

    -- Review-order window (<leader>r).
    set("VreviewOrderHeader", { link = "Title", default = true })
    set("VreviewOrderReviewed", { link = "Comment", default = true })
    -- Current package: yellow foreground on the selection band.
    local diag_warn = vim.api.nvim_get_hl(0, { name = "DiagnosticWarn", link = false })
    local yellow = diag_warn.fg or "#e5c07b"
    set("VreviewOrderCurrent", { fg = yellow, bg = bg, bold = true, default = true })
end

-- ---------------------------------------------------------------------------
-- Opening diffview for the active scope
-- ---------------------------------------------------------------------------

-- Close any diffview in the current tab, then open the given spec.
-- `spec` == "" means "whole range" (reopen the original raw range) or
-- working-tree if no range.
function M.open_scope()
    local s = session.get()
    if not s then return end

    local spec
    if s.scope_idx == 0 then
        -- Whole view: use the exact argument the user launched with, so the
        -- aggregate diff matches what `vreview <arg>` originally showed.
        spec = s.diffview_arg or ""
    else
        local c = s.commits[s.scope_idx]
        spec = git.commit_isolation_spec(c.hash)
    end

    -- Remember we are (re)opening so the DiffviewViewClosed handler keeps the
    -- session alive across the close/open.
    M._reopening = true

    -- diffview will open the new view in a fresh tab; move our session back to
    -- "pending" so it re-binds to that tab.
    session.reopen(s)

    -- Close current diffview view (if any) then open the new one.
    pcall(vim.cmd, "DiffviewClose")
    M.diffview_open(spec, s.cpath)

    vim.notify("vreview: " .. session.active_scope_label(), vim.log.levels.INFO)
end

-- Run :DiffviewOpen for `spec` (may be ""), optionally scoped to a package repo
-- via the -C flag (so it works regardless of the forced workspace-root cwd).
function M.diffview_open(spec, cpath)
    local parts = { "DiffviewOpen" }
    if cpath and cpath ~= "" then
        table.insert(parts, "-C" .. vim.fn.fnameescape(cpath))
    end
    if spec and spec ~= "" then
        table.insert(parts, spec)
    end
    vim.cmd(table.concat(parts, " "))
end

-- Cycle to the next scope and reopen diffview accordingly.
function M.cycle()
    local s = session.get()
    if not s then
        vim.notify("vreview: no active review session", vim.log.levels.WARN)
        return
    end
    if #s.commits == 0 then
        vim.notify("vreview: no commits to cycle (single diff)", vim.log.levels.INFO)
        return
    end
    if #s.commits == 1 then
        -- A single commit's isolated diff equals the whole-range diff, so the
        -- range row is informational only and there's nothing to cycle.
        vim.notify("vreview: single commit — nothing to cycle", vim.log.levels.INFO)
        return
    end
    s.scope_idx = (s.scope_idx + 1) % (#s.commits + 1)
    M.open_scope()
end

-- Toggle diffview's file panel AND the commit panel together, preserving the
-- commit panel's height so it returns to the same proportion. Bound to the same
-- key diffview uses for toggling the file panel (<leader>b).
function M.toggle_panels()
    -- No commit panel for this review (plain diff): just toggle the file panel.
    if not (session.get() and #session.get().commits > 0) then
        local cur_win = vim.api.nvim_get_current_win()
        pcall(vim.cmd, "DiffviewToggleFiles")
        -- Restore focus if the original window is still valid.
        if vim.api.nvim_win_is_valid(cur_win) then
            vim.api.nvim_set_current_win(cur_win)
        end
        return
    end

    local cur_win = vim.api.nvim_get_current_win()

    if panel.file_panel_open() then
        -- Hiding: close the commit panel first (records its height), then the
        -- file panel, so neither is left orphaned.
        panel.close()
        pcall(vim.cmd, "DiffviewToggleFiles")
        -- Restore focus if the original window is still valid (it won't be if
        -- the cursor was IN the panel being closed).
        if vim.api.nvim_win_is_valid(cur_win) then
            vim.api.nvim_set_current_win(cur_win)
        end
    else
        -- Showing: reopen the file panel, then restore the commit panel at its
        -- saved height once the layout settles. Keep focus on the original window.
        pcall(vim.cmd, "DiffviewToggleFiles")
        vim.schedule(function()
            panel.open()
            -- After panels are open, restore focus to the original diff window.
            if vim.api.nvim_win_is_valid(cur_win) then
                vim.api.nvim_set_current_win(cur_win)
            end
        end)
    end
end

-- ---------------------------------------------------------------------------
-- Keymaps active inside diffview buffers
-- ---------------------------------------------------------------------------
local function set_review_keymaps(buf)
    local opts = { buffer = buf, nowait = true, silent = true }
    -- Leave a comment on the current line / visual selection.
    vim.keymap.set("n", "C", comments.leave_comment,
        vim.tbl_extend("force", opts, { desc = "vreview: comment on line" }))
    vim.keymap.set("x", "C", comments.leave_comment,
        vim.tbl_extend("force", opts, { desc = "vreview: comment on selection" }))
    -- Cycle whole-range <-> per-commit review.
    vim.keymap.set("n", "<leader><Tab>", M.cycle,
        vim.tbl_extend("force", opts, { desc = "vreview: cycle commit scope" }))
    -- Toggle file panel + commit panel together (overrides diffview's <leader>b).
    vim.keymap.set("n", "<leader>b", M.toggle_panels,
        vim.tbl_extend("force", opts, { desc = "vreview: toggle file + commit panels" }))
    -- Open the review-order window (jump between packages).
    vim.keymap.set("n", "<leader>r", M.review_order,
        vim.tbl_extend("force", opts, { desc = "vreview: review-order window" }))
end

-- ---------------------------------------------------------------------------
-- setup(): install autocmds. Safe to call multiple times.
-- ---------------------------------------------------------------------------
function M.setup()
    if M._did_setup then return end
    M._did_setup = true

    vim.g.review_mode = true
    setup_highlights()

    -- Delegate to the legacy reviewMode: it owns the `cc` diffcon-context
    -- keymap and the background code-reviewer agent for CR workspaces.
    pcall(function() require("addons.reviewMode").setup() end)

    local grp = vim.api.nvim_create_augroup("VreviewMode", { clear = true })

    -- Re-apply highlights on colorscheme change.
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = grp,
        callback = setup_highlights,
    })

    -- Bind review keymaps (C comment, <leader><Tab> cycle) whenever we enter a
    -- diff/diffview buffer.
    vim.api.nvim_create_autocmd("BufEnter", {
        group = grp,
        callback = function(ev)
            local ft = vim.bo[ev.buf].filetype
            if vim.wo.diff or ft == "DiffviewFiles" or vim.g.review_mode then
                set_review_keymaps(ev.buf)
            end
        end,
    })

    -- Place comment signs whenever diffview shows a diff buffer in a window.
    vim.api.nvim_create_autocmd("User", {
        group = grp,
        pattern = "DiffviewDiffBufWinEnter",
        callback = function()
            comments.refresh_signs()
        end,
    })

    -- Also refresh on entering an ordinary diff window (covers non-diffview
    -- diffs and re-entering an already-loaded buffer).
    vim.api.nvim_create_autocmd("BufWinEnter", {
        group = grp,
        callback = function(ev)
            if vim.wo.diff then
                comments.refresh_signs(ev.buf)
            end
        end,
    })

    -- diffview opens its view in a fresh tab; bind our session to that tab as
    -- soon as the view opens so session.get() works inside the diff.
    vim.api.nvim_create_autocmd("User", {
        group = grp,
        pattern = "DiffviewViewOpened",
        callback = function()
            session.bind_current_tab()
        end,
    })

    -- After diffview builds its layout, (re)open the commit panel.
    vim.api.nvim_create_autocmd("User", {
        group = grp,
        pattern = "DiffviewViewPostLayout",
        callback = function()
            session.bind_current_tab()
            vim.schedule(function()
                panel.open()
            end)
        end,
    })

    -- Tidy the commit panel when diffview closes.
    vim.api.nvim_create_autocmd("User", {
        group = grp,
        pattern = "DiffviewViewClosed",
        callback = function()
            if not M._reopening then
                panel.close()
                session.clear_current_tab()
            end
            M._reopening = false
        end,
    })
end

-- ---------------------------------------------------------------------------
-- start(opts): called by the vreview shell script (and package switching).
--   opts.range        raw ref/range (e.g. "HEAD~2", "HEAD~2..HEAD"); nil for -d
--   opts.diffview_arg the exact argument to hand to :DiffviewOpen ("" for -d)
--   opts.cpath        (optional) package repo path to target via -C; when set,
--                     git operations run against it instead of cwd (cwd is the
--                     forced Brazil workspace root, not the package).
--   opts.pkg_name     (optional) display name of the package under review
-- ---------------------------------------------------------------------------
function M.start(opts)
    opts = opts or {}
    M.setup()

    -- Resolve the package repo: an explicit cpath (from the review-order window)
    -- wins; otherwise use the git toplevel of the cwd.
    local repo = git.toplevel(opts.cpath or vim.fn.getcwd())
    if not repo then
        vim.notify("vreview: not inside a git repo", vim.log.levels.ERROR)
        return
    end

    -- For -d (working tree) opts.range is nil; but if we were given a commit
    -- count via diffview_arg like "HEAD~2", pass it as the range too.
    local range = opts.range
    if not range and opts.diffview_arg and opts.diffview_arg:match("^HEAD~%d+$") then
        range = opts.diffview_arg
    end

    -- Build the session (parses the commit range against `repo`). It is
    -- "pending" until diffview opens its tab, so use the returned value here.
    local s = session.init(repo, range, opts.diffview_arg,
        { cpath = opts.cpath, pkg_name = opts.pkg_name })

    -- Persist review metadata, including CR info parsed from the branch name.
    local branch = git.current_branch(repo)
    local base, cr, rev = git.parse_cr_branch(branch)
    store.write_meta(repo, {
        repo = repo,
        branch = branch,
        base_branch = base,
        range = s.range or range,
        cr_number = cr,
        cr_revision = rev,
    })

    M.diffview_open(opts.diffview_arg or "", opts.cpath)
end

-- Switch the active review to a different package (from the review-order
-- window). Closes the current diffview and reopens targeting `pkg.abs_path`.
function M.switch_package(pkg)
    if not pkg or not pkg.abs_path then return end

    -- Keep the session alive across the close so DiffviewViewClosed doesn't
    -- tear down state we're about to replace.
    M._reopening = true
    pcall(vim.cmd, "DiffviewClose")

    -- -d means working-tree diff (no range); anything else is the diffview arg.
    local dv_arg = pkg.vreview_arg or ""
    local range
    if dv_arg == "-d" then
        dv_arg = ""
    else
        range = dv_arg
    end

    M.start({
        range = range,
        diffview_arg = dv_arg,
        cpath = pkg.abs_path,
        pkg_name = pkg.name,
    })
end

-- Open the review-order floating window (<leader>r).
function M.review_order()
    require("addons.vreview.order").open()
end

return M
