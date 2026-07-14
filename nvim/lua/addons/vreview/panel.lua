-- vreview.panel: a small window under diffview's file panel that lists the
-- commits in the review range and highlights the one currently in scope.
--
-- Rendered as:
--   HEAD~2..HEAD                      <- range header (whole-review row, idx 0)
--   43d988a2a0ba ACON-184: PIN/UNPIN…  <- commit 1 (idx 1)
--   03fbf03acb23 ACON-184: router-side… <- commit 2 (idx 2)
--
-- The active scope's row is highlighted. <leader><Tab> cycles the scope, which
-- reopens diffview for that scope and re-highlights here.

local session = require("addons.vreview.session")

local M = {}

local ns = vim.api.nvim_create_namespace("vreview_panel")
M.win = nil
M.buf = nil

-- Locate diffview's file-panel window in the current tab (filetype DiffviewFiles).
local function find_file_panel_win()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == "DiffviewFiles" then
            return win
        end
    end
    return nil
end

-- Is diffview's file panel currently visible in this tab?
function M.file_panel_open()
    return find_file_panel_win() ~= nil
end

local function build_lines(s)
    local lines = {}
    -- Row 0: the range / whole-review header.
    table.insert(lines, {
        text = s.range or s.raw_range or "working tree",
        kind = "range",
        idx = 0,
    })
    for i, c in ipairs(s.commits) do
        table.insert(lines, {
            text = string.format("%s %s", c.short, c.title),
            kind = "commit",
            idx = i,
            short_len = #c.short,
        })
    end
    return lines
end

-- (Re)render the panel contents and highlight the active scope.
function M.render()
    local s = session.get()
    if not s or not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then return end

    local rows = build_lines(s)
    local text = {}
    for _, r in ipairs(rows) do table.insert(text, r.text) end

    vim.bo[M.buf].modifiable = true
    vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, text)
    vim.bo[M.buf].modifiable = false

    vim.api.nvim_buf_clear_namespace(M.buf, ns, 0, -1)
    for li, r in ipairs(rows) do
        local line = li - 1
        local active = (r.idx == s.scope_idx)
        if r.kind == "range" then
            vim.api.nvim_buf_set_extmark(M.buf, ns, line, 0, {
                end_row = line + 1,
                hl_group = active and "VreviewPanelActive" or "VreviewPanelRange",
                hl_eol = true,
            })
        else
            -- Hash gets its own color; title inherits the row/active style.
            vim.api.nvim_buf_set_extmark(M.buf, ns, line, 0, {
                end_col = r.short_len,
                hl_group = active and "VreviewPanelActiveHash" or "VreviewPanelHash",
            })
            vim.api.nvim_buf_set_extmark(M.buf, ns, line, 0, {
                end_row = line + 1,
                hl_group = active and "VreviewPanelActive" or "VreviewPanelTitle",
                hl_eol = true,
                priority = active and 90 or 100, -- title extmark under hash extmark
            })
        end
        if active then
            -- A left-edge marker (sign-like) via extmark sign column.
            vim.api.nvim_buf_set_extmark(M.buf, ns, line, 0, {
                sign_text = "▶",
                sign_hl_group = "VreviewPanelArrow",
            })
        end
    end
end

-- Create the panel split below the file panel. Idempotent per tab.
-- `height` overrides the default (used to restore the exact size on toggle).
function M.open(height)
    local s = session.get()
    if not s or #s.commits == 0 then return end   -- nothing to show for plain diffs

    -- Already open in this tab?
    if M.win and vim.api.nvim_win_is_valid(M.win) then
        M.render()
        return
    end

    local file_win = find_file_panel_win()
    if not file_win then return end

    local cur = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(file_win)

    -- Split below the file panel. Default height scales with commit count
    -- (capped); a caller-supplied height (from a prior toggle) takes priority.
    height = height or M.saved_height or math.min(#s.commits + 1, 10)
    vim.cmd("belowright " .. height .. "split")
    M.win = vim.api.nvim_get_current_win()
    M.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(M.win, M.buf)

    vim.bo[M.buf].buftype = "nofile"
    vim.bo[M.buf].bufhidden = "wipe"
    vim.bo[M.buf].swapfile = false
    vim.bo[M.buf].filetype = "VreviewCommits"
    vim.api.nvim_buf_set_name(M.buf, "vreview://commits")

    local wo = vim.wo[M.win]
    wo.number = false
    wo.relativenumber = false
    wo.wrap = false
    wo.cursorline = false
    wo.signcolumn = "yes:1"
    wo.winfixheight = true
    wo.winfixwidth = true
    wo.list = false
    wo.foldcolumn = "0"
    wo.statusline = "%#VreviewPanelTitle# vreview commits "

    -- Clicking / <CR> on a row jumps directly to that scope.
    vim.keymap.set("n", "<CR>", function() M.goto_cursor_scope() end,
        { buffer = M.buf, nowait = true, silent = true, desc = "vreview: review this commit" })
    -- <leader>b toggles both panels from here too (matches the diff buffers).
    vim.keymap.set("n", "<leader>b", function() require("addons.vreview").toggle_panels() end,
        { buffer = M.buf, nowait = true, silent = true, desc = "vreview: toggle file + commit panels" })

    M.render()
    if vim.api.nvim_win_is_valid(cur) then
        vim.api.nvim_set_current_win(cur)
    end
end

-- Jump the scope to the commit on the panel's cursor line.
function M.goto_cursor_scope()
    local s = session.get()
    if not s then return end
    local line = vim.api.nvim_win_get_cursor(M.win)[1]
    local idx = line - 1   -- row 1 = range (idx 0)
    if idx < 0 or idx > #s.commits then return end
    -- With a single commit the range row (idx 0) is informational only and not
    -- selectable — the commit's diff already equals the whole-range diff.
    if #s.commits == 1 and idx == 0 then return end
    if idx == s.scope_idx then return end
    s.scope_idx = idx
    require("addons.vreview").open_scope()
end

function M.is_open()
    return M.win ~= nil and vim.api.nvim_win_is_valid(M.win)
end

-- Close the panel, remembering its current height so a later open() restores
-- the same proportion.
function M.close()
    if M.is_open() then
        M.saved_height = vim.api.nvim_win_get_height(M.win)
        vim.api.nvim_win_close(M.win, true)
    end
    M.win, M.buf = nil, nil
end

-- Toggle only the commit panel (used by the combined <leader>b handler).
function M.toggle()
    if M.is_open() then
        M.close()
    else
        M.open()
    end
end

return M
