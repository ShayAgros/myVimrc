# Product — What this repository is

<!-- inclusion: always -->

This repository is **shayagr's personal Neovim configuration**. It is not an
application or a library; the "product" is an editor environment tuned for the
owner's daily work.

## Who uses it and for what

A single developer (Amazon engineer working primarily on Aurora/Constellation —
Rust, Java, C++ — plus assorted personal projects). The config is used for:

- General software editing with LSP, completion, treesitter, fuzzy finding.
- **Offline code review** of Amazon CRs and Brazil workspaces (the `vreview`
  system — the most developed bespoke feature; see `plugins/vreview.md`).
- Debugging (DAP for C/Java/Lua, nvim-gdb).
- AI-assisted coding via in-editor Claude / Amazon Q integrations.
- Note-taking tied to code (`code_notes`), and various Amazon-internal helpers
  (CloudWatch links, code.amazon.com URL → local file resolution, web-link copy).

## Design priorities

1. **Keyboard-first, low-latency.** e.g. the Claude terminal is pre-warmed on
   startup so the first invocation is instant (`lua/addons/claudeWarm.lua`).
2. **Bespoke tooling where off-the-shelf falls short.** The owner writes custom
   `lua/addons/` modules rather than contorting plugins — `vreview` is a full
   review layer built on top of `diffview.nvim` without forking it.
3. **Amazon-workflow aware.** Brazil workspaces, CRUX CR branches, code.amazon.com
   URLs, and dev-desktop sync are first-class concerns.
4. **AI-maintainable.** This `.kiro`/`.claude` knowledge base exists so AI sessions
   can extend the config coherently (see `ai-change-log.md`).

## Non-goals

- Not intended to be a distributable "distro" for others.
- Not minimal — it deliberately carries specialized tooling for the owner's job.
