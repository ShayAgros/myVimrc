# AI Change Log & Documentation Protocol

<!-- inclusion: always -- this rule governs every AI session in this repo. -->

**This is the most important steering file. Read and obey it in every session.**

This Neovim configuration is maintained partly by AI. To keep that sustainable,
**every AI-assisted change must leave a written trail here**, so a future session
(with no memory of this one) can understand what exists, why it was built, and how
to extend it — without re-deriving everything from the Lua source.

## The rule

When you (an AI assistant) add, change, or remove anything in this configuration:

1. **Update the relevant subsystem doc.** If you touched a plugin or a
   self-written system that has a doc under `steering/plugins/<name>.md`, update
   that doc to reflect the new behavior. If you created a *new* large system
   (a new plugin config with non-trivial custom logic, or a new `lua/addons/`
   module of substance), create a new `steering/plugins/<name>.md` for it and add
   a line to `steering/INDEX.md`.
2. **Append a changelog entry** to the "Changelog" section at the bottom of this
   file: date, one-line summary, the files touched, and *why*. Keep newest first.
3. **Keep the foundational docs honest.** If your change alters the tech stack,
   the directory structure, or the product's scope, update `tech.md`,
   `structure.md`, or `product.md` accordingly.

### What counts as "documentation-worthy"

- New plugin added to `lua/plugins/` → note it in `tech.md` and, if it has custom
  config/keymaps, give it a `steering/plugins/` doc.
- New or changed `lua/addons/` module → subsystem doc + changelog.
- New keymap, command, or autocmd with lasting behavior → document where a user
  would look for it (usually the relevant subsystem doc).
- Trivial, self-evident edits (typo fixes, formatting) → changelog line is enough;
  no subsystem doc needed.

### What NOT to put here

- Secrets, tokens, machine-specific absolute paths that aren't already public.
- Transient debugging notes. This is durable design knowledge, not a scratchpad.
- Anything already obvious from reading a single short file — link to the file
  instead of duplicating it. Docs explain the *why* and the *cross-file design*
  that source alone doesn't convey.

## Format conventions

- Plain Markdown. Kiro loads steering files by `inclusion` front-matter (see
  `INDEX.md`); Claude Code reads them via `@import` from `.claude/CLAUDE.md`.
- Foundational docs (`product.md`, `tech.md`, `structure.md`, this file) are
  `inclusion: always`.
- Per-plugin verbose docs are `inclusion: manual` (loaded on demand) to keep the
  always-on context small.
- Reference source by `path:line` (e.g. `lua/addons/vreview/init.lua:242`) —
  these are precise and clickable.

## Changelog

<!-- Newest first. Format: ### YYYY-MM-DD — <summary> -->

### 2026-07-14 — find_impls: fleet-wide "find implementations" (`glI`)
- New addon `lua/addons/find_impls/init.lua` + loader `plugin/find_impls.lua`
  (registers `:FindImpls` and a buffer-local `glI` in Java files) — the
  out-of-workspace complement to `gli` (jdtls implementation search only sees the
  local workspace + forward-dep classpath, so it misses subtypes in
  reverse-dependency packages that aren't checked out).
- Pipeline: resolve target via LSP `textDocument/definition` + tree-sitter
  classify (type vs method, and the method's *declaring* type) → `csimpl impls`
  broad code-search net → `M.analyze` tree-sitter verify/locate → Snacks picker.
  In-workspace hits open locally; out-of-workspace hits are fetched via
  `csimpl cat` (raw blob) into `~/.cache/csimpl/` and opened from there.
- Method-mode semantics match jdtls: emit only **concrete** declarations of the
  searched method — the declaring type's own body (e.g. an interface `default`)
  and subtypes that actually **override** it; a subtype that only inherits the
  default is excluded. Type-mode lists all subtypes, excluding the type itself.
- Companion CLI `~/.local/bin/csimpl` (user script, not in this repo): talks to
  the code-search Coral service `CodeSearchQueryService.SearchCodeV2` at
  `codesearch-query-sso.corp.amazon.com/midway/` via midway `mcurl`; `search` /
  `impls` / `cat` subcommands; fails loudly on HTTP 401/403 ("Run `mwinit`")
  instead of silently returning empty.
- Docs: new `plugins/find-impls.md` (+ INDEX row); noted in `tech.md` and
  `structure.md`.
- Why: reviewing CRs that change an SPI needs to see *all* implementors across the
  fleet (e.g. `ConstellationEngineLogic` → Mysql + Postgres), not just the ones in
  the current workspace.

### 2026-07-10 — gdb_backtrace: split local_variable into name = value
- Grammar: `local_variable` now parses indented struct/var lines into `var_binding`
  (fields `name`/`value`), `members_header`, or a `variable_content` catch-all,
  so name and value carry precise column ranges instead of one whole-line blob.
  Handles a `static` storage-class modifier and dotted `_vptr.Class` names.
- Worked around a tree-sitter quirk where `/[ \t]{4,}/` compiled as `{4}` (exactly
  four), truncating the indent — `_indent` is now `/[ \t][ \t][ \t][ \t]+/`.
- Rebuilt + redeployed `parser/gdb_backtrace.so`; updated
  `queries/gdb_backtrace/highlights.scm`. 16 corpus tests pass; real dump still 0
  errors. Winbar unaffected (thread_header unchanged).

### 2026-07-10 — gdb_backtrace: match built-in colors + fast winbar
- Split coloring from structure in `ftplugin/gdb_backtrace.lua`: coloring now uses
  the built-in `gdb` vim syntax (`syntax=gdb`, tree-sitter highlighter NOT started)
  so these files look identical to the pre-tree-sitter state (numbers → Number,
  quoted strings → String, rest plain). Verified token-for-token parity with
  `ft=gdb`.
- The `gdb_backtrace` tree-sitter parser is now used ONLY for the thread-context
  winbar (queried via `get_parser`, no highlighter). `queries/gdb_backtrace/
  highlights.scm` is dormant but kept.
- Rewrote the winbar to be O(log n) per cursor move: a `(thread_header)` query
  builds a sorted row→label index once per parse, cached by `changedtick`, then
  binary-searched on `CursorMoved`. Fixes the earlier O(19k)-per-move tree walk
  that made the buffer crawl (~4µs/move now).
- Updated `plugins/gdb-backtrace-treesitter.md` accordingly.

### 2026-07-10 — Custom tree-sitter grammar for GDB backtraces
- Built a tree-sitter grammar for GDB thread-dump/backtrace files at
  `~/workspace/software/tree-sitter-gdb-backtrace/` (grammar.js, external scanner
  `src/scanner.c` for `_eof`, 12-case corpus, highlights.scm). Parses the real
  19k-line dump with 0 errors (58 threads, 931 frames, 66 shared libs).
- Deployed into this config: `parser/gdb_backtrace.so`,
  `queries/gdb_backtrace/highlights.scm`, and `ftplugin/gdb_backtrace.lua` (starts
  tree-sitter + shows the current `Thread N (LWP M)` in the winbar, computed by
  walking the parse tree — `_G.gdb_backtrace_thread_label()`).
- Changed `lua/autocmds/filetypes.lua`: `bt-*.txt` now maps to filetype
  `gdb_backtrace` (was `gdb`), so the tree-sitter parser drives highlighting
  instead of the built-in GDB command-script syntax.
- Documented in `plugins/gdb-backtrace-treesitter.md` (+ INDEX row).
- Why: navigating a 60-thread crash dump is much easier when the editor shows
  which thread the cursor is in and highlights frames/registers/locals distinctly.

### 2026-07-09 — Added highlight_sections.lua addon
- Created `lua/addons/highlight_sections.lua`: visual-mode `<leader>ht` opens a
  floating menu to add/remove colored sign-column markers on selected lines.
  Cycles through a 10-color palette per session using extmarks in the
  `highlight_sections` namespace.
- Added `require("addons.highlight_sections")` to `init.lua`.
- Added `bt-*.txt → gdb` filetype detection in `lua/autocmds/filetypes.lua`
  (converted the unordered `pairs()` table to an ordered `ipairs()` list so
  specific patterns override the generic `*.txt → markdown` rule).
- Documented in `steering/plugins/addons-misc.md`.
- Why: easier visual triage of GDB backtraces and log sections during oncall.

### 2026-07-03 — Established the `.kiro`/`.claude` AI knowledge base
- Created `.kiro/steering/` (source of truth, Kiro-cli format) and `.claude/`
  (Claude Code): `.claude/steering` symlinks to `.kiro/steering`; `.claude/CLAUDE.md`
  is a real entry file that `@import`s the foundational docs.
- Added foundational docs (`product.md`, `tech.md`, `structure.md`), this protocol
  file, an `INDEX.md`, and per-subsystem docs under `steering/plugins/` — most
  notably `plugins/vreview.md` documenting the offline code-review system in full.
- Why: make AI-authored config knowledge durable across sessions.
