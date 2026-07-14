# GDB backtrace tree-sitter parser

<!-- inclusion: manual -- load when working on gdb_backtrace highlighting, the parser, or thread-context winbar. -->

A **custom tree-sitter grammar** for GDB backtrace / thread-dump files (the
multi-thread `bt`/`thread apply all bt` output that Aurora/Oscar crash tooling
produces, e.g. `bt-mysqld-<hash>.txt`). Purpose: syntax-highlight these dumps and
show **which thread the cursor is in** (the dumps are one long file split across
~60 threads), computed from the parse tree rather than a regex.

## Where things live

- **Grammar project (source of truth):**
  `~/workspace/software/tree-sitter-gdb-backtrace/`
  - `grammar.js` — the grammar
  - `src/scanner.c` — external scanner, emits a zero-width `_eof` token
  - `test/corpus/basic.txt` — 12 test cases (`tree-sitter test`)
  - `queries/highlights.scm` — highlight query
  - `README.md` — build/deploy instructions
- **Deployed into this nvim config** (`~/.config/nvim` → this repo):
  - `parser/gdb_backtrace.so` — compiled parser (includes the scanner)
  - `queries/gdb_backtrace/highlights.scm` — highlight query (copied)
  - `ftplugin/gdb_backtrace.lua` — starts tree-sitter + winbar thread context
  - `lua/autocmds/filetypes.lua` — maps `bt-*.txt` → filetype `gdb_backtrace`

## Grammar design (why it looks the way it does)

Every physical line in these dumps starts with the dump tool's own line number,
`N: ` (e.g. `38: #0 ...`). The grammar makes this `line_prefix` a **mandatory,
high-precedence single token** (`token(prec(2, /\d+:[ \t]/))`). This is the key
trick: it removes the column-0 ambiguity between the greedy catch-all and the
structured line types. After the prefix, one discriminating token picks the line
type. The catch-all `other_content` is `token(prec(-2, /[^\n]+/))` so structured
discriminators (`#N`, `Thread `, a register name, 4-space indent, `@@@@@@`) win.

Flat structure — `thread_header` is a **top-level sibling** of the frames it
introduces (not a parent). Consumers walk siblings to find the nearest preceding
header = current thread. This avoids blank-line/section ambiguity that a nested
`thread_section` rule caused.

Top-level node types: `thread_header` (fields `thread_id`, `details`), `frame`
(`frame_number`, `frame_body`), `register_line` (`register_name`, `hex_value`,
`register_extra`), `local_variable`, `info_line`
(`no_symbols` / `signal_handler` / `no_locals`), `redacted_line`
(`redacted_content`), `shared_library` (`hex_value` ×2, `shared_library_info`),
`blank_line`, `other_line`.

**`local_variable` sub-structure.** An indented (4+ spaces after the prefix)
struct/var-dump line is parsed into one of:
- `var_binding` — a `name = value` pair with fields `name` (`var_name`) and
  `value` (`var_value`), so each carries a precise column range instead of the
  whole line being one blob. Handles an optional `static ` `storage_class`
  modifier and dotted names like `_vptr.ClassName`.
- `members_header` — a `members of <type>:` section header.
- `variable_content` — catch-all for braces / base-class lines (`}`, `}, {`,
  `<...> = {`, `<No data fields>}`).

**`{4,}` gotcha (important if you edit the grammar).** This tree-sitter version
compiles the regex `/[ \t]{4,}/` as if it were `/[ \t]{4}/` (exactly four),
which truncated the indent token and left a stray space that broke `var_binding`
on deeply-indented lines. The `_indent` rule is therefore written explicitly as
`/[ \t][ \t][ \t][ \t]+/` (four mandatory + one-or-more). Avoid `{n,}` open-ended
repetition elsewhere in this grammar.

**External scanner / `_eof`:** GDB dumps frequently have *no trailing newline* on
the last line. Each line rule ends with `choice($._newline, $._eof)`; the scanner
in `src/scanner.c` emits `_eof` at end of input so that final line still parses.
Without this the last line errored.

Validated against the real dump: **0 parse errors**, 58 `thread_header`, 58
`blank_line` separators, 931 `frame`, 66 `shared_library`.

## Thread-context winbar + coloring split

`ftplugin/gdb_backtrace.lua` deliberately **splits coloring from structure**:

- **Coloring = built-in `gdb` vim syntax.** The ftplugin sets `vim.bo.syntax =
  "gdb"` (and defensively `vim.treesitter.stop()`), so these files are colored
  exactly as they were before the tree-sitter work: numbers → `Number`, quoted
  strings → `String`, everything else plain. The tree-sitter **highlighter is NOT
  started**. This was a deliberate choice — the owner wanted the coloring to match
  the pre-tree-sitter look, and the flat grammar would otherwise need to
  sub-tokenize numbers/strings inside frame bodies to reproduce it.
- **Structure = the `gdb_backtrace` tree-sitter parser**, used ONLY for the winbar
  thread context. The parser is obtained with `vim.treesitter.get_parser(bufnr,
  "gdb_backtrace")` and queried directly — no highlighter, so it does not affect
  colors.

Because nvim-treesitter's `highlight.enable=true` may try to auto-start the
highlighter when it sees the parser present, the ftplugin re-asserts
`syntax=gdb` + `treesitter.stop()` both synchronously and via `vim.schedule`.

`queries/gdb_backtrace/highlights.scm` is therefore currently **dormant** (kept for
anyone who wants to switch to full tree-sitter highlighting by calling
`vim.treesitter.start()` instead of the built-in syntax).

### Winbar mechanics + performance

On `CursorMoved`/`BufEnter` the ftplugin sets `vim.wo.winbar` to the current
`Thread N (LWP M)`. Performance is the reason for the caching design:

- The grammar is **flat** — every line is a direct child of root — so a naive
  "walk root children to find the enclosing thread_header" is **O(lines) per
  cursor move**, which made a 19k-line dump crawl.
- Instead, a compiled `(thread_header) @h` query builds a **sorted index** of
  `{row → "Thread N (LWP M)"}` **once per parse**, cached per-buffer keyed by
  `changedtick` (rebuilt only on edit, which is ~never for these read-only dumps).
- Cursor moves then do a **binary search** (`upper_le`) over the cached rows:
  ~4µs each vs. walking 19k nodes. Before the first header → `Thread (crashing /
  signal)` (GDB prints the crashing thread without a header).
- Measured: cold parse ~10ms (once), index build ~0.05ms, per-move lookup
  ~0.004ms. Exposed as `_G.gdb_backtrace_thread_label()` for statusline reuse.

## Rebuild / redeploy after a grammar change

```sh
cd ~/workspace/software/tree-sitter-gdb-backtrace
tree-sitter generate && tree-sitter test && tree-sitter build -o gdb_backtrace.so
cp gdb_backtrace.so ~/.config/nvim/parser/gdb_backtrace.so
cp queries/highlights.scm ~/.config/nvim/queries/gdb_backtrace/highlights.scm
```

## Gotchas

- The parser name / language is `gdb_backtrace` and equals the filetype, so no
  `vim.treesitter.language.register` call is needed.
- Coloring is intentionally done by the built-in `gdb` vim syntax (via
  `syntax=gdb` set in the ftplugin), NOT by the tree-sitter highlighter. The
  filetype is still `gdb_backtrace` (so the ftplugin fires and the winbar works);
  only the *syntax* option is `gdb`. Do not "simplify" this by setting the whole
  filetype to `gdb` — that would stop the ftplugin/winbar from loading.
- The `.so` is committed into the repo (`parser/`), so it is machine-specific
  (x86-64 Linux). On a different arch, rebuild with `tree-sitter build`.
- nvim-treesitter `auto_install=true` / `highlight.enable=true` may try to
  auto-start the tree-sitter highlighter because the parser is on the runtimepath;
  the ftplugin re-asserts `syntax=gdb` + `vim.treesitter.stop()` (sync + scheduled)
  to keep coloring on the built-in syntax.
