-- ftplugin for gdb_backtrace files (GDB thread-dump / backtrace, e.g. bt-*.txt)
--
-- Coloring vs. structure are deliberately split:
--   * COLORING  -> the built-in `gdb` vim syntax (identical to what these files
--     looked like before the tree-sitter work: numbers as Number, quoted
--     strings as String, everything else plain). We do NOT enable the
--     tree-sitter highlighter.
--   * STRUCTURE -> the custom `gdb_backtrace` tree-sitter parser, used only to
--     show the current thread in the winbar. The parser is queried directly;
--     no highlighter is started.
--
-- PERFORMANCE: the grammar is flat (every line is a direct child of root), so a
-- naive "walk root children on every CursorMoved" is O(lines) per move --
-- unusable on a 19k-line dump. Instead we build a sorted index of thread-header
-- rows ONCE per parse, cache it keyed by the buffer's changedtick, and
-- binary-search it on cursor move (O(log n), no re-parse, no tree walk).
--
-- Parser source: ~/workspace/software/tree-sitter-gdb-backtrace

local LANG = "gdb_backtrace"

-- Use the built-in gdb syntax for coloring, and make sure the tree-sitter
-- highlighter is NOT driving colors (defensive: nvim-treesitter's
-- highlight.enable may try to auto-start it because the parser is present).
local function apply_builtin_coloring()
  pcall(vim.treesitter.stop)
  if vim.bo.syntax ~= "gdb" then
    vim.bo.syntax = "gdb"
  end
end
apply_builtin_coloring()
-- Re-assert after any deferred nvim-treesitter FileType hook has run.
vim.schedule(apply_builtin_coloring)

vim.wo.wrap = false

-- Compile the thread-header query once for the whole session.
local ok_q, header_query = pcall(vim.treesitter.query.parse, LANG, "(thread_header) @h")
if not ok_q then
  header_query = nil
end

-- Per-buffer cache: { tick = <changedtick>, rows = {int...}, labels = {str...} }
-- `rows` is ascending (parse order == file order), so binary search works.
local cache = {}

--- Build (or rebuild) the sorted thread-header index for a buffer.
--- Runs the query over the tree ONCE. O(n) but only on parse/edit, not per move.
--- Uses get_parser directly (no highlighter) so coloring stays with vim syntax.
local function build_index(bufnr)
  local rows, labels = {}, {}

  local ok_p, parser = pcall(vim.treesitter.get_parser, bufnr, LANG, {})
  if ok_p and parser and header_query then
    local tree = parser:parse()[1]
    if tree then
      local root = tree:root()
      for _, node in header_query:iter_captures(root, bufnr, 0, -1) do
        local srow = node:start()
        local id_field = node:field("thread_id")[1]
        local det_field = node:field("details")[1]
        local id = id_field and vim.treesitter.get_node_text(id_field, bufnr) or "?"
        local lwp = ""
        if det_field then
          local det = vim.treesitter.get_node_text(det_field, bufnr)
          lwp = det:match("(LWP %d+)") or ""
        end
        local label = (lwp ~= "") and ("Thread " .. id .. " (" .. lwp .. ")")
                                   or ("Thread " .. id)
        rows[#rows + 1] = srow
        labels[#labels + 1] = label
      end
    end
  end

  cache[bufnr] = {
    tick = vim.api.nvim_buf_get_changedtick(bufnr),
    rows = rows,
    labels = labels,
  }
  return cache[bufnr]
end

--- Get the index for a buffer, rebuilding only if the buffer changed.
local function get_index(bufnr)
  local c = cache[bufnr]
  if not c or c.tick ~= vim.api.nvim_buf_get_changedtick(bufnr) then
    c = build_index(bufnr)
  end
  return c
end

--- Binary search: greatest index i such that rows[i] <= target. 0 if none.
local function upper_le(rows, target)
  local lo, hi, ans = 1, #rows, 0
  while lo <= hi do
    local mid = math.floor((lo + hi) / 2)
    if rows[mid] <= target then
      ans = mid
      lo = mid + 1
    else
      hi = mid - 1
    end
  end
  return ans
end

--- Current thread label for the cursor, using the cached index. No re-parse.
---@return string|nil
local function current_thread_label()
  local bufnr = vim.api.nvim_get_current_buf()
  local c = get_index(bufnr)
  if #c.rows == 0 then
    return "Thread (crashing / signal)"
  end
  local cursor_row = vim.api.nvim_win_get_cursor(0)[1] - 1 -- 0-indexed
  local i = upper_le(c.rows, cursor_row)
  if i == 0 then
    -- Before the first header: the crashing thread has no header in GDB output.
    return "Thread (crashing / signal)"
  end
  return c.labels[i]
end

-- Expose for statusline / other use.
_G.gdb_backtrace_thread_label = current_thread_label

local function update_winbar()
  if vim.bo.filetype ~= LANG then return end
  local label = current_thread_label()
  if not label then return end
  local text = "  " .. label:gsub("%%", "%%%%")
  if vim.wo.winbar ~= text then -- avoid needless redraws
    vim.wo.winbar = text
  end
end

local augroup = vim.api.nvim_create_augroup("GdbBacktraceContext", { clear = false })

vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufEnter" }, {
  group = augroup,
  buffer = 0,
  callback = update_winbar,
})

vim.api.nvim_create_autocmd({ "BufUnload" }, {
  group = augroup,
  buffer = 0,
  callback = function()
    cache[vim.api.nvim_get_current_buf()] = nil
  end,
})

update_winbar()
