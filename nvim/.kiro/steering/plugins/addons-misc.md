# Miscellaneous addons (`lua/addons/`)

<!-- inclusion: manual -- load when working on one of the smaller self-written helpers. -->

The smaller self-written modules. Each is loaded from `init.lua` (some via
`.setup()`, some register a command/keymap on require). Larger systems have their
own docs: `vreview.md`, `reviewmode.md`.

## claudeWarm.lua
Pre-warms the Claude Code terminal on startup so the first `\ac` is instant instead
of a ~5s cold start. `M.setup()` (called from `init.lua`) `defer_fn`s: resolves the
git-root/cwd instance id, and if no instance exists yet, creates a **hidden**
terminal buffer running claude. No-op if the `claude-code` plugin isn't present.

## smartFileOpening.lua
Transforms a `code.amazon.com/packages/<pkg>/blobs/<hash>/--/<path>[#L<n>]` URL into
a local `src/<pkg>/<path>` path and opens it at the line. The inverse of
`copyWebLink`. Used when someone pastes a code-browser URL and you want the local
file.

## copyWebLink.lua
Copies a shareable code.amazon.com web link for the current file and line, derived
from the git remote/package. The inverse of `smartFileOpening`.

## CWLogsOps.lua
`GetCloudWatchLink()` — reads the current log line, extracts a `dom:<number>`, and
builds a CloudWatch console link from it. For Amazon oncall/log workflows.

## yankBuffers.lua
`:YankBuffers` command — copies the file paths of all listed buffers to the `+`
(system clipboard) register, one per line.

## lsp_references_filter.lua
Filters noisy/irrelevant LSP references (e.g. generated or vendored paths) so
reference lists stay useful.

## instance_sync.lua
Scaffolding for syncing local edits to a remote dev instance (dev-desktop /
dev-kermit). Currently minimal (`send_changed_files` is a stub) — the real sync is
handled externally (ninja-dev-sync). Extend here if in-editor sync is wanted.

## brazil_picker.lua
A picker for Brazil packages/workspaces (integrates with the fuzzy finder).

## debug_setup.lua, dap/, dapui_custom.lua
DAP (debug adapter) configuration. `dap/c.lua`, `dap/java.lua`, `dap/lua.lua` are
per-language adapter configs; `dapui_custom.lua` customizes the DAP UI layout;
`debug_setup.lua` wires it together. Also see `plugins/nvim-gdb.lua` for the
gdb-based alternative.

## highlight_sections.lua
Visual-mode section highlighter. Select lines in visual mode, press `<leader>ht`,
and a `vim.ui.select` floating menu offers:
- **Add color column** — places a colored `▌` sign-text extmark in the sign column
  for each selected line. Each invocation cycles through a 10-color palette so
  different sections get visually distinct colors within the same session.
- **Remove color** — deletes all highlight_sections extmarks on the selected lines.

Uses the `highlight_sections` namespace for extmarks. Colors are defined in
`palette` (hex values) and highlight groups are created lazily as `HlSection_N`.
No persistent state — marks disappear on buffer close/session end.

## code_notes (lua/code_notes.lua + code_notes_init.lua)
Code-anchored notes: attach notes to specific code locations. `code_notes_init.lua`
just calls `require("code_notes").setup()` from `init.lua`. Note data is stored
under the `code_notes/` directory at the config root.
