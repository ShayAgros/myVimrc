# Tech — Stack, tooling, conventions

<!-- inclusion: always -->

## Runtime & language

- **Neovim ≥ 0.10** (developed against 0.12). Config is **Lua** (not Vimscript),
  entry point `init.lua`.
- A Neovim server socket is started on launch at `/tmp/nvim-<pid>.sock`
  (`init.lua`) so external tools can drive the editor.

## Plugin management

- **[lazy.nvim](https://github.com/folke/lazy.nvim)**, bootstrapped in
  `lua/config/lazy.lua` (clones stable into `stdpath("data")/lazy/`).
- Plugin specs live in `lua/plugins/*.lua`; lazy imports the whole `plugins`
  module. `change_detection` is disabled. Lockfile: `lazy-lock.json`.
- To add a plugin: create/extend a spec under `lua/plugins/`. Follow the existing
  return-table style.

## Key plugins (by domain)

| Domain | Plugin(s) | Spec file |
|---|---|---|
| Git / diff / review | `tpope/vim-fugitive`, `sindrets/diffview.nvim` | `plugins/git.lua` |
| LSP | native LSP + `lspsaga.nvim` | `plugins/lsp.lua`, `plugins/lspsaga.lua` |
| Completion | `nvim-cmp` (+ luasnip, cmp sources) | `plugins/cmp.lua` |
| Treesitter | `nvim-treesitter` | `plugins/treesitter.lua` |
| Fuzzy / UI | `snacks.nvim`, a picker | `plugins/snacks.lua`, `plugins/picker.lua` |
| File tree | `nvim-tree` | `plugins/nvim-tree.lua` |
| Debug | `nvim-dap` (+ dap-ui), `nvim-gdb` | `lua/addons/dap/*`, `plugins/nvim-gdb.lua` |
| Motions/edits | `leap.nvim`, surround, autopairs, comments, vim-eunuch | respective specs |
| Statusline | `lualine.nvim` | `plugins/lualine.lua` |
| Sessions | `obsession` | `plugins/obsession.lua` |
| Colors | nightfox et al. | `plugins/colorschemes.lua` |
| AI | Claude Code integration, `amazonq` | `plugins/llm.lua`, `plugins/amazonq.lua` |

## Self-written systems (`lua/addons/`)

These are bespoke Lua modules, not third-party plugins. Substantial ones have a
dedicated doc under `steering/plugins/`:

- **`vreview/`** — offline code-review layer on diffview (comments, per-commit
  panel, review-order window). See `plugins/vreview.md`. **Largest custom system.**
- **`reviewMode.lua`** — diffcon context float (`cc`), background reviewer agent.
- **`find_impls/`** — fleet-wide find-implementations (`glI`): cross-repo type/method
  implementation search incl. packages not in the workspace, via the `csimpl`
  code-search CLI (`nvim/scripts/csimpl`, symlinked to `~/.local/bin`) + tree-sitter
  + Snacks. See `plugins/find-impls.md`.
- `claudeWarm.lua` — pre-warm the Claude terminal on startup.
- `smartFileOpening.lua` — resolve `code.amazon.com/packages/.../blobs/...` URLs to
  local `src/<pkg>/<path>` and jump there.
- `copyWebLink.lua` — copy a code.amazon.com web link for the current file/line.
- `CWLogsOps.lua` — build CloudWatch console links from log lines (`dom:<n>`).
- `debug_setup.lua`, `dap/`, `dapui_custom.lua` — DAP configuration.
- `lsp_references_filter.lua` — filter noisy LSP references.
- `brazil_picker.lua`, `instance_sync.lua`, `yankBuffers.lua` — misc helpers.

Plus `lua/code_notes.lua` (+ `code_notes_init.lua`) — code-anchored notes.

## Keymap conventions

- **Leader = `\`** (backslash); localleader also `\` (defaults — not overridden).
- Custom mappings: `lua/config/keymaps.lua`. Plugin-local mappings live in each
  plugin's config or, for review buffers, are set by autocmd (see `vreview`).
- `jk` is mapped to `<Esc>` in insert/terminal (and command-mode `<C-c>`).

## External integration points

- **Brazil build system / workspaces** — `packageInfo` at a workspace root; each
  `src/<Package>/` is its own git repo. An autocmd (`autocmds/project.lua`) `lcd`s
  to the nearest ancestor containing `packageInfo` (else `.git`) on `BufWinEnter`,
  and sets `vim.b.in_brazil`.
- **CRUX CR branches** — named `CRUX/CR-XXXXXXXX/rN/<base>`; several tools parse
  the base/CR/revision out of this.
- **AI CLIs** — `kiro-cli` and `claude` (Claude Code). This repo carries config for
  both under `.kiro/` and `.claude/`.

## Build / test

There is no build step for a Neovim config. "Testing" a change means loading it in
Neovim. For headless verification of Lua modules (used when developing `vreview`):

```bash
nvim --headless -c "lua assert(loadfile(vim.fn.stdpath('config')..'/lua/addons/<mod>.lua'))" -c 'qa'
```

`vreview` storage can be isolated for tests via `$VREVIEW_DATA_DIR`.
