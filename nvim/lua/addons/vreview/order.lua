-- vreview.order: the <leader>r floating window listing packages in the
-- recommended review order.
--
--   * current package under review: highlighted (yellow foreground + band)
--   * packages with saved comments: marked with a check
--   * j/k/arrows navigate (read-only buffer)
--   * <Esc> (or jk, which the user maps to <Esc>) closes
--   * <CR> switches the review to the package on the cursor line

local plan = require("addons.vreview.plan")
local store = require("addons.vreview.store")
local session = require("addons.vreview.session")

local M = {}

local ns = vim.api.nvim_create_namespace("vreview_order")
M.win = nil
M.buf = nil
M.rows = nil   -- parallel array: rows[i] = { pkg = <plan package>, is_header = bool }

-- Which package (by abs_path) is under review right now?
local function current_pkg_path()
    local s = session.get()
    if not s then return nil end
    -- Prefer the explicit cpath; else the session repo (git toplevel).
    return s.cpath or s.repo
end

-- Build the display lines + highlight metadata.
-- Returns lines(string[]), rows(table[]), where rows are aligned to buffer lines.
local function build(p)
    local cur = current_pkg_path()
    -- Normalize for comparison (strip trailing slash).
    local function norm(x) return x and x:gsub("/$", "") or x end
    cur = norm(cur)

    local n = #p.packages
    local num_w = #tostring(n)                     -- width of the largest index
    -- Longest package name, so the summary column lines up.
    local name_w = 0
    for _, pkg in ipairs(p.packages) do
        name_w = math.max(name_w, #(pkg.name or ""))
    end

    local lines, rows = {}, {}
    local function push(line, meta)
        table.insert(lines, line)
        table.insert(rows, meta or {})
    end

    -- Header.
    local title = "Review order"
    if p.cr then title = title .. "  (" .. p.cr .. ")" end
    push(title, { is_header = true })
    push("", { is_header = true })

    for _, pkg in ipairs(p.packages) do
        local reviewed = pkg.abs_path and store.has_comments(pkg.abs_path)
        local is_current = cur and norm(pkg.abs_path) == cur

        -- "▶ 2. AuroraConstellationFrontendCore   ✓  summary"
        --  ^marker ^num(right-aligned) ^name(left-padded) ^check ^summary
        local marker = is_current and "▶" or " "
        local num = string.format("%" .. num_w .. "d", pkg.order or 0)
        local name = pkg.name or "?"
        local name_pad = name .. string.rep(" ", name_w - #name)
        local check = reviewed and "✓" or " "
        local arg = pkg.vreview_arg or ""
        local commits = pkg.commits or 0
        local scope
        if arg == "-d" or commits == 0 then
            scope = "working tree"
        elseif commits == 1 then
            scope = "1 commit"
        else
            scope = commits .. " commits"
        end

        local line = string.format("%s %s. %s  %s  [%s]", marker, num, name_pad, check, scope)
        push(line, {
            pkg = pkg,
            is_current = is_current,
            reviewed = reviewed,
            -- column offsets for precise highlighting (byte positions):
            marker_col = 0,
            name_start = #marker + 1 + #num + 2, -- "marker" + " " + "num" + ". "
        })
    end

    return lines, rows
end

local function apply_highlights(p)
    vim.api.nvim_buf_clear_namespace(M.buf, ns, 0, -1)
    for i, r in ipairs(M.rows) do
        local line = i - 1
        if r.is_header then
            vim.api.nvim_buf_set_extmark(M.buf, ns, line, 0, {
                end_row = line + 1, hl_group = "VreviewOrderHeader", hl_eol = true,
            })
        elseif r.is_current then
            -- Yellow band across the whole current row.
            vim.api.nvim_buf_set_extmark(M.buf, ns, line, 0, {
                end_row = line + 1, hl_group = "VreviewOrderCurrent", hl_eol = true,
            })
        else
            -- Dim the number; normal name; green check handled below.
            if r.reviewed then
                vim.api.nvim_buf_set_extmark(M.buf, ns, line, 0, {
                    end_row = line + 1, hl_group = "VreviewOrderReviewed", hl_eol = true,
                })
            end
        end
    end
end

function M.close()
    if M.win and vim.api.nvim_win_is_valid(M.win) then
        vim.api.nvim_win_close(M.win, true)
    end
    M.win, M.buf, M.rows = nil, nil, nil
end

-- Switch the review to the package on the current cursor line, then close.
function M.select()
    if not M.rows then return end
    local line = vim.api.nvim_win_get_cursor(M.win)[1]
    local row = M.rows[line]
    if not row or not row.pkg then return end
    local pkg = row.pkg
    M.close()
    require("addons.vreview").switch_package(pkg)
end

function M.open()
    local p = plan.load()
    if not p then
        vim.notify(
            "vreview: no review plan found. Run the review-cr-code skill to generate " ..
            ".vreview/review_plan.json at the workspace root.",
            vim.log.levels.WARN)
        return
    end
    if #p.packages == 0 then
        vim.notify("vreview: review plan has no packages", vim.log.levels.WARN)
        return
    end

    -- Toggle: if already open, close.
    if M.win and vim.api.nvim_win_is_valid(M.win) then
        M.close()
        return
    end

    local lines, rows = build(p)
    M.rows = rows

    M.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, lines)
    vim.bo[M.buf].modifiable = false
    vim.bo[M.buf].buftype = "nofile"
    vim.bo[M.buf].bufhidden = "wipe"
    vim.bo[M.buf].filetype = "VreviewOrder"

    -- Size the float to the content.
    local width = 0
    for _, l in ipairs(lines) do width = math.max(width, vim.fn.strdisplaywidth(l)) end
    width = math.min(width + 2, vim.o.columns - 4)
    local height = math.min(#lines, vim.o.lines - 4)

    M.win = vim.api.nvim_open_win(M.buf, true, {
        relative = "editor",
        row = math.floor((vim.o.lines - height) / 2 - 1),
        col = math.floor((vim.o.columns - width) / 2),
        width = width,
        height = height,
        style = "minimal",
        border = "rounded",
        title = " vreview ",
        title_pos = "center",
    })

    local wo = vim.wo[M.win]
    wo.cursorline = true
    wo.number = false
    wo.relativenumber = false

    apply_highlights(p)

    -- Start the cursor on the current package (or first package row).
    local start_line = 3   -- first package (after 2 header lines)
    for i, r in ipairs(M.rows) do
        if r.is_current then start_line = i break end
    end
    pcall(vim.api.nvim_win_set_cursor, M.win, { start_line, 0 })

    -- Keymaps: read-only navigation; <CR> selects; <Esc> closes.
    local kopts = { buffer = M.buf, nowait = true, silent = true }
    vim.keymap.set("n", "<CR>", M.select, kopts)
    vim.keymap.set("n", "<Esc>", M.close, kopts)
    vim.keymap.set("n", "q", M.close, kopts)
    -- j/k/arrows work natively in a normal buffer; constrain within package rows
    -- is unnecessary (cursorline just moves). Prevent editing keys implicitly via
    -- non-modifiable buffer.
end

return M
