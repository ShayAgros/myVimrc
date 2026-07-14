# vreview — Offline Code-Review System

<!-- inclusion: manual -- load when working on offline review / diffview / addons/vreview. -->

`vreview` is a bespoke offline code-review layer built **on top of**
[`diffview.nvim`](https://github.com/sindrets/diffview.nvim) — **without forking
it**. It turns Neovim into a full review tool: leave persistent markdown comments,
review a multi-commit branch commit-by-commit, and jump between the changed
packages of a Brazil workspace in a recommended order.

It is the largest self-written system in this config. Code lives in
`lua/addons/vreview/`; the shell launcher is `~/.local/bin/vreview` (outside this
repo). Companion skill `review-cr-code` (in `~/workspace/dots/llm_files`) generates
the review plan it consumes.

## How it hooks diffview without forking

diffview exposes everything needed as public integration points, so vreview never
patches diffview source — with **one exception**: diffview's default `<leader>b` →
`toggle_files` keybinding has been removed from `config.lua` (in view, file_panel,
and file_history_panel sections). Without this, diffview's `attach_buffer()` would
re-apply `<leader>b` → `toggle_files` every time a new diff buffer is shown
(navigating files with `<tab>`), overwriting vreview's `<leader>b` →
`toggle_panels`. vreview's version subsumes diffview's (it calls
`DiffviewToggleFiles` internally when there's no commit panel), so nothing is lost.

Integration points used:

- **User autocmds** emitted by diffview: `DiffviewViewOpened`,
  `DiffviewViewPostLayout`, `DiffviewViewClosed`, `DiffviewDiffBufWinEnter`.
  (`diffview/init.lua` calls `M.init()` on require, so these always fire.)
- **`DiffviewFiles` filetype** identifies the file-panel window — vreview anchors
  its commit panel just below it.
- **`DiffviewOpen -C<path> <rev>`** targets an arbitrary repo regardless of cwd —
  essential because the Brazil autocmd forces cwd to the workspace root, not the
  package (see below).
- diffview opens each view in its **own tabpage** (`tab split`), which is why the
  session is bound per-tab (see `session.lua`).

## Modules (`lua/addons/vreview/`)

| Module | Responsibility |
|---|---|
| `init.lua` | Public entry (`start`), setup/autocmds, highlights, scope cycling, panel toggling, package switching, `<leader>r` hook. |
| `store.lua` | On-disk persistence: `INDEX` + per-repo dirs, comments, `meta.json`, regenerated `review.md`. |
| `git.lua` | git helpers: toplevel, branch, CR-branch parsing, commit-range listing, single-commit isolation spec. |
| `session.lua` | Per-tab review state: repo, range, commit list, active scope index, cpath. |
| `comments.lua` | `C` keymap, the markdown capture split, buffer→(file,side) resolution, gutter signs. |
| `panel.lua` | The commit-list window under diffview's file panel + highlighting. |
| `plan.lua` | Finds the workspace root and loads `.vreview/review_plan.json`. |
| `order.lua` | The `<leader>r` review-order floating window. |

## Invocation & the shell launcher

`~/.local/bin/vreview [-d] [ref|range]`:

- `vreview` — auto-detect: if on a `CRUX/CR-XXXXXXXX/rN/<base>` branch, diff against
  `<base>` (or `origin/<base>` if no local branch); else `HEAD~1`.
- `vreview HEAD~2` — review the last 2 commits (`HEAD~2..HEAD`), cycleable.
- `vreview HEAD~3..HEAD~1` — an explicit range.
- `vreview -d` — working-tree (unstaged) diff; no commit panel.

It builds and runs: `nvim -c "lua require('addons.vreview').start({ range=..., diffview_arg=... })"`.
`start(opts)` accepts `range`, `diffview_arg`, and (for package switching)
`cpath` + `pkg_name`.

## Feature 1 — Comments (`C`)

Bound in diff/diffview buffers (set via `BufEnter` autocmd in `init.lua`):

- **`C` in normal mode** → comment the current line. **`C` in visual mode** →
  comment the selected **whole-line** range (partial-line selections are widened).
- Opens a **markdown scratch split** at the bottom with a header (scope, side,
  location). Write (`:w`/`:wq`) saves; `<C-c>` or `:q!` cancels. Bodies are full
  multi-line markdown.
- **Scope tagging**: each comment records the *active scope* —
  - whole-range view → the **range string** (e.g. `HEAD~2..HEAD`). Deliberate: a
    comment on a line the diff didn't touch is still recorded as part of reviewing
    the branch, not dropped.
  - single-commit view → that commit's **short hash**.
  - working-tree (`-d`) → `working-tree`.
- Commented lines get a `▌` gutter sign (`VreviewCommentSign`). Signs are placed on
  every line of a multi-line range, on both old and new sides.
- **Old vs new side**: old (left) buffers are named
  `diffview://<repo>/.git/<hash>/<relpath>`; new (right) are ordinary repo files.
  `comments.lua` resolves the repo-relative path and side from the buffer name.

## Feature 2 — Commit panel + cycling (`<leader><Tab>`)

`vreview HEAD~2` (or any `a..b`) shows a highlighted panel below diffview's file
panel:

```
HEAD~2..HEAD
43d988a2a0ba ACON-184: PIN/UNPIN routing on mainline (…)
03fbf03acb23 ACON-184: router-side UNPIN temp-object guard (core)
```

- **`<leader><Tab>`** cycles scope: whole range → commit 1 (`<hash>^!` isolated
  diff) → commit 2 → … → back to whole. diffview reopens scoped each time.
- Active row highlighted with a `▶` marker (`VreviewPanelActive` /
  `VreviewPanelActiveHash`); `<CR>` on a row jumps straight to that scope.
- **Single-commit special case** (`vreview HEAD~1`): the panel still shows two rows
  (range header + the one commit), but the **commit row is active by default** and
  the range header is *informational only* — `<leader><Tab>` is a no-op and the
  header isn't selectable, because a single commit's isolated diff already equals
  the whole-range diff. (`session.can_cycle()` gates this; scope defaults to idx 1
  when `#commits == 1`.)

## Feature 3 — Panel toggle (`<leader>b`)

Overrides diffview's built-in `toggle_files`. Toggles the **file panel and the
commit panel together** so neither is orphaned, and **restores the commit panel's
exact height** on reopen (captured into `panel.saved_height` on close). For a plain
diff with no commits it just forwards to `DiffviewToggleFiles`.

## Feature 4 — Review-order window (`<leader>r`)

Opens a floating window listing the workspace's changed packages in recommended
review order, read from `.vreview/review_plan.json` (see below).

- Aligned columns: index, package name, a `✓` for packages that already have saved
  comments, and the review scope (`[N commits]` / `[working tree]`).
- The package currently under review is highlighted in **yellow**
  (`VreviewOrderCurrent`) with a `▶`; the cursor starts on it.
- `j`/`k`/arrows navigate (read-only buffer). `<Esc>` (or `jk`, mapped to `<Esc>`)
  / `q` closes. **`<CR>`** switches the review to the package on the cursor line.
- **Package switching** reopens diffview via `DiffviewOpen -C<abs_path> <arg>` and
  re-inits the session — **no `cd`**, because the Brazil workspace autocmd
  (`autocmds/project.lua`) forces cwd to the workspace root (the `packageInfo` dir),
  not the package. The package repo is passed explicitly with `-C`. A `-d` package
  opens as a working-tree diff.
- If no plan file exists, `<leader>r` shows a message pointing to the
  `review-cr-code` skill.

### `.vreview/review_plan.json` (workspace root)

Generated by the `review-cr-code` skill. Schema:

```json
{
  "cr": "CR-XXXXXXXX",            // or null for a non-CR workspace review
  "base": "mainline",             // or null
  "packages": [
    { "order": 1, "name": "ConstellationSqlParser",
      "path": "src/ConstellationSqlParser",   // relative to workspace root
      "vreview_arg": "HEAD~2",                 // exact arg for vreview/DiffviewOpen; "-d" = working tree
      "commits": 2,                            // 0 = working-tree diff
      "summary": "Parser: PIN/UNPIN keywords" }
  ]
}
```

`plan.lua` walks parents from cwd for `.vreview/review_plan.json` (falling back to
the nearest `packageInfo` dir for the workspace root), sorts packages by `order`,
and resolves each `path` to `abs_path`.

## Storage (`store.lua`)

Root: `stdpath("data")/vreview/` — override with **`$VREVIEW_DATA_DIR`** (used by
tests to isolate storage without moving the whole nvim data dir).

```
vreview/
├── INDEX                  jsonl: {"id":<n>,"repo":"<abs git toplevel>"} per line
└── <id>/
    ├── meta.json          repo, branch, base_branch, range, cr_number, cr_revision
    ├── comments.jsonl     one comment/line (see schema below)
    └── review.md          human-readable render, regenerated on every write
```

- The repo path is **never** encoded into a filename (Linux path-length / illegal
  chars); `INDEX` maps an absolute git toplevel → an opaque numeric dir id. Each
  package is its own git repo → its own review dir.
- **Comment schema**: `id`, `parent` (optional — for threaded replies; data model
  supports it, reply UI is a future addition), `commit` (scope tag: range string,
  short hash, or `working-tree`), `file` (repo-relative), `side` (`new`|`old`),
  `start_line`, `end_line`, `body` (multi-line markdown), `ts`.
- `review.md` is regenerated on every write: grouped by commit-scope → file, with
  threaded replies nested under their parent.
- Helper `store.has_comments(repo)` powers the `✓` in the order window.

## Session model (`session.lua`)

- State is keyed by **tabpage** (diffview opens each view in its own tab). A new
  session starts "pending" and is bound to the diffview tab on `DiffviewViewOpened`
  (`bind_current_tab`). Cycling/switching moves the session back to pending
  (`reopen`) so it re-binds to the freshly opened tab.
- Fields: `repo`, `raw_range`, `range` (normalized `a..b`), `diffview_arg`,
  `cpath` (for `-C`), `pkg_name`, `commits` (oldest-first list of
  `{hash, short, title}`), `scope_idx` (0 = whole range, i = commits[i]).
- `active_commit_tag()` / `active_scope_label()` derive the comment tag and the
  panel/notification label from the scope. `can_cycle()` is true only when
  `#commits > 1`.

## git helpers (`git.lua`)

`toplevel`, `current_branch`, `parse_cr_branch` (→ base, CR number, revision from
`CRUX/CR-XXXXXXXX/rN/<base>`), `commits_in_range` (uses unit-separated
`git log --reverse` fields to survive arbitrary subjects; a bare ref is treated as
`<ref>..HEAD`), and `commit_isolation_spec(hash)` → `<hash>^!`.

## Highlights (`init.lua` `setup_highlights`)

Theme-aware (linked to existing groups, backgrounds derived from `Visual`):
`VreviewPanelRange/Hash/Title/Active/ActiveHash/Arrow`, `VreviewCommentSign`,
`VreviewOrderHeader/Reviewed/Current` (current = yellow fg from `DiagnosticWarn`).
Re-applied on `ColorScheme`.

## Interaction with `reviewMode.lua`

`vreview.setup()` calls `require('addons.reviewMode').setup()`, which owns the `cc`
diffcon-context float and the background code-reviewer agent for CR workspaces.
See `reviewmode.md`.

## Keymap summary (inside a review)

| Key | Action |
|---|---|
| `C` (n/x) | Comment current line / visual whole-line range |
| `<leader><Tab>` | Cycle whole ↔ per-commit scope (no-op if ≤1 commit) |
| `<leader>b` | Toggle file panel + commit panel together (keeps proportions) |
| `<leader>r` | Open the review-order window |
| `<CR>` (commit panel) | Jump to that commit's scope |
| `<CR>` (order window) | Switch review to that package |
| `cc` | Show diffcon context float (via reviewMode) |

## Testing

Modules are pure enough to drive headless. Pattern used during development:

```bash
VREVIEW_DATA_DIR=/tmp/vreview_data nvim --headless \
  -c "luafile /tmp/test.lua" -c 'qa'
```

Tests spawn `require('addons.vreview').start(...)`, `vim.wait` for the panel buffer,
then assert on session state, panel lines, extmark highlight groups, stored
comments, and `review.md`. Always set `$VREVIEW_DATA_DIR` so tests don't touch real
review data, and never move `$XDG_DATA_HOME` (that makes lazy re-clone every plugin).

## Known future work

- Threaded-reply **UI** (the storage `parent` field already supports it).
- The order window's "no plan" case is intentionally just a message (no
  auto-discovery of changed packages).

## Maintenance: diffview.nvim patch

The local copy at `~/.local/share/nvim/lazy/diffview.nvim/lua/diffview/config.lua`
has `<leader>b` removed from all three keymap sections (view, file_panel,
file_history_panel). **If diffview is updated via lazy.nvim, the patch will be
lost** — re-apply by removing the `<leader>b` lines from `config.lua` defaults.
The reason: diffview's `attach_buffer()` re-applies keymaps every time a diff buffer
is shown (e.g. navigating files with `<tab>`), which would overwrite vreview's
`<leader>b` → `toggle_panels` binding.