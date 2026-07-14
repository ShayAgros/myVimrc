# Neovim Configuration — AI Entry Point (Claude Code)

This is the Claude Code entry point for this Neovim configuration repository. The
**source of truth** for all AI-authored knowledge lives in `.kiro/steering/`
(Kiro-cli format, plain Markdown). `.claude/steering` is a symlink to it, so both
tools read identical content. Claude Code does **not** auto-read `.kiro/`, which is
why this file exists and imports the shared docs below.

## Read these first

@steering/INDEX.md
@steering/product.md
@steering/tech.md
@steering/structure.md
@steering/ai-change-log.md

## MANDATORY: log your changes

Any change you make to this configuration with AI assistance **must be documented**
in `.kiro/steering/` so future sessions can build on it. See
@steering/ai-change-log.md for exactly how and where. This is not optional — it is
the mechanism that keeps this knowledge base useful.

## Per-subsystem docs

Each large plugin or self-written system has a dedicated verbose doc under
`.kiro/steering/plugins/`. Load the one relevant to what you're editing (they use
Kiro `inclusion: manual`, so they are on-demand). The index at
@steering/INDEX.md lists them all. Notably:

- `plugins/vreview.md` — the offline code-review system (largest self-written system).
