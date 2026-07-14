# Structure — Directory & file layout

<!-- inclusion: always -->

The config root is `~/.config/nvim`, a symlink to
`~/workspace/dots/myVimrc/nvim` (a git repo, branch `master`, remote `kermit` on
dev-kermit). **Commit changes there.**

```
nvim/
├── init.lua                    Entry: settings → keymaps → lazy → addons → autocmds
├── lazy-lock.json              Plugin lockfile
├── claude-settings.json        Settings for the in-editor Claude integration
├── nightfox.tmux               Generated tmux theme (from colorscheme)
├── .kiro/                      AI knowledge base — SOURCE OF TRUTH (kiro-cli)
│   └── steering/
│       ├── INDEX.md            Catalog of all steering docs + inclusion modes
│       ├── product.md          What this repo is (always)
│       ├── tech.md             Stack & conventions (always)
│       ├── structure.md        This file (always)
│       ├── ai-change-log.md    Change-logging protocol + changelog (always)
│       └── plugins/            Per-subsystem verbose docs (inclusion: manual)
│           ├── vreview.md      Offline review system (full)
│           ├── reviewmode.md   diffcon context float + reviewer agent
│           ├── find-impls.md   Fleet-wide find-implementations (glI) + csimpl CLI
│           └── addons-misc.md  The smaller lua/addons helpers
├── .claude/                    Claude Code view of the same knowledge
│   ├── CLAUDE.md               Real entry file; @imports the steering docs
│   └── steering -> ../.kiro/steering   (symlink: shared markdown)
├── lua/
│   ├── config/                 settings.lua, keymaps.lua, lazy.lua, abbrevations.lua
│   ├── plugins/                One spec file per plugin/domain (lazy.nvim)
│   ├── addons/                 Self-written modules (see tech.md)
│   │   ├── vreview/            The offline review system (its own package)
│   │   │   ├── init.lua        Wiring, keymaps, start(), scope cycling
│   │   │   ├── store.lua       Persistence (INDEX + per-repo dirs)
│   │   │   ├── git.lua         Range/CR parsing helpers
│   │   │   ├── session.lua     Per-tab review scope state
│   │   │   ├── comments.lua    C keymap, capture split, gutter signs
│   │   │   ├── panel.lua       Commit list panel under diffview
│   │   │   ├── plan.lua        Loads .vreview/review_plan.json
│   │   │   └── order.lua       <leader>r review-order floating window
│   │   ├── dap/                Per-language DAP configs (c, java, lua)
│   │   ├── find_impls/         Fleet-wide find-implementations (glI); see plugins/find-impls.md
│   │   └── *.lua               reviewMode, claudeWarm, smartFileOpening, …
│   ├── autocmds/               general.lua, filetypes.lua, project.lua
│   ├── code_notes.lua          Code-anchored notes plugin (+ code_notes_init.lua)
│   ├── clang_format/, formatters/, custom/snippets/  supporting Lua
│   └── kitty+page.lua
├── after/, ftplugin/, syntax/, ftdetect/, spell/   standard Neovim runtime dirs
├── plugin/                     Auto-sourced loaders (find_impls.lua → :FindImpls + glI)
├── parser/                     Compiled tree-sitter parsers (gdb_backtrace.so)
├── queries/                    Tree-sitter queries (queries/gdb_backtrace/highlights.scm)
└── code_notes/                 Stored code notes data
```

## Conventions to follow

- **Plugins** are added as spec files under `lua/plugins/`; one file per plugin or
  tight domain group. Don't inline plugin specs into `init.lua`.
- **Bespoke logic** goes in `lua/addons/` (a module returning a table with a
  `setup()`/entry function, wired from `init.lua`). A multi-file system gets its
  own subdirectory with an `init.lua` (see `addons/vreview/`).
- **Autocmds** that are cross-cutting live in `lua/autocmds/`; plugin-specific ones
  live with the plugin.
- **`require` paths** mirror the directory: `require("addons.vreview")`,
  `require("addons.vreview.store")`, `require("config.keymaps")`.
- The companion CLI-side note: `~/.local/bin/vreview` is the shell launcher for the
  review system (documented in `plugins/vreview.md`); it lives outside this repo.

## Related knowledge outside this repo

- LLM/agent config management convention: `~/workspace/dots/llm_files` (the owner's
  broader steering/skills/agents system). This nvim `.kiro`/`.claude` is analogous
  but scoped to the editor config.
- The `review-cr-code` skill (in `llm_files`) generates the `.vreview/review_plan.json`
  that `vreview`'s `<leader>r` window consumes.
