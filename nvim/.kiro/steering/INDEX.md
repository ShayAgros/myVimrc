# Steering Index

<!-- inclusion: always -- small catalog; keep it loaded so AI knows what exists. -->

Catalog of AI-steering docs for this Neovim config. `.kiro/steering/` is the
**source of truth** (kiro-cli); `.claude/steering` symlinks to it and
`.claude/CLAUDE.md` imports the foundational docs for Claude Code.

## How loading works

- **Kiro-cli**: reads every file in `.kiro/steering/`. Each file's intended load
  mode is noted in an HTML comment at its top (`inclusion: always | manual`).
  Foundational docs are `always`; per-plugin docs are `manual` (on demand) to keep
  the always-on context small.
- **Claude Code**: `.claude/CLAUDE.md` `@import`s the foundational docs; open a
  `plugins/*.md` doc directly when working on that subsystem.

## Foundational (always loaded)

| Doc | Purpose |
|---|---|
| `product.md` | What this repository is, who uses it, priorities |
| `tech.md` | Stack, plugins, self-written systems, conventions |
| `structure.md` | Directory & file layout, where things go |
| `ai-change-log.md` | **Change-logging protocol (mandatory) + changelog** |

## Per-subsystem verbose docs (`plugins/`, load on demand)

| Doc | Covers |
|---|---|
| `plugins/vreview.md` | **Offline code-review system** — comments, per-commit panel, review-order window, storage format, keymaps, CLI launcher. The largest custom system. |
| `plugins/reviewmode.md` | `reviewMode.lua` — the `cc` diffcon-context float and the background code-reviewer agent. |
| `plugins/find-impls.md` | **Fleet-wide find-implementations** (`glI`) — cross-repo type/method implementation search incl. packages not in the workspace (`csimpl` code-search CLI + tree-sitter verify + Snacks picker). Complement to jdtls `gli`. |
| `plugins/gdb-backtrace-treesitter.md` | **Custom tree-sitter grammar** for GDB backtrace/thread-dump files (`bt-*.txt`): syntax highlighting + current-thread winbar context. Grammar source lives in `~/workspace/software/tree-sitter-gdb-backtrace`. |
| `plugins/addons-misc.md` | Smaller `lua/addons/` helpers: claudeWarm, smartFileOpening, copyWebLink, CWLogsOps, yankBuffers, lsp_references_filter, instance_sync, brazil_picker. |

## Adding a doc

When you build a new large system, add a `plugins/<name>.md` and a row above, then
follow `ai-change-log.md`.
