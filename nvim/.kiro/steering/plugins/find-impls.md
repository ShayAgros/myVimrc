# find_impls — fleet-wide "find implementations" (`glI`)

<!-- inclusion: manual -- load when working on cross-repo implementation search / csimpl. -->

Find implementations of a Java type **or** method across **all** Amazon
repositories — including packages that are **not** checked out in the local
Brazil workspace. This is the complement to `gli` (jdtls
`textDocument/implementation`), which only sees the local workspace + its
forward-dependency classpath.

- Addon: `lua/addons/find_impls/init.lua`
- CLI:   `~/.local/bin/csimpl` (not in this repo — user script)
- Loader/keymaps: `plugin/find_impls.lua`

## Why it exists

jdtls implementation search resolves **subtypes**, which live in packages that
*depend on* the type's package (reverse dependencies). Those jars are **not** on
the defining package's classpath and their source isn't in the workspace, so
jdtls never indexes them. Definitions flow *down* the dependency graph (forward
deps → on classpath → jdtls sees them); implementors flow *up* (reverse deps →
invisible to jdtls). Concretely: with only `ConstellationRouterBase` +
`ConstellationRouterMysql` checked out, `gli` on `ConstellationEngineLogic` finds
the Base default + the Mysql impl but **misses** `ConstellationEngineLogicPostgres`
in the un-checked-out `ConstellationRouterPostgres`. `glI` finds it.

## Pipeline (no AI in the loop)

1. **Resolve target** (`resolve_target`) — if the cursor word isn't given
   explicitly, run LSP `textDocument/definition` and classify the definition site
   with tree-sitter (`classify_definition`) into either:
   - `{kind="type", type_name}` — cursor was on a type name, or
   - `{kind="method", type_name, method}` — cursor was on a method; `type_name`
     is the **declaring** type (e.g. the interface that declares the method).
   Falls back to `{kind="type", type_name=<cword>}` if no LSP.
2. **Search** (`csimpl impls <type_name> --json`) — broad candidate net:
   query `"<type> fp:*.java"` against the code-search backend. Deliberately
   broad; tree-sitter does the precise filtering.
3. **Verify + locate** (`M.analyze`, per candidate file) — see semantics below.
4. **Present** (`show`) — Snacks picker (reusing `formatters.snacks_formatters`);
   1 hit jumps directly; falls back to quickfix if Snacks is absent.
   In-workspace files open locally; out-of-workspace files are fetched
   (`csimpl cat` → raw blob) into `~/.cache/csimpl/<repo>/<branch>/<path>` and
   opened from there.

## `M.analyze(content, type_name, method)` — the precise rule

Tree-sitter (`get_string_parser`, `java`) walks every `class/interface/enum/
record_declaration` (nested too):

- **TYPE mode** (`method == nil`): emit a hit at the type's **name** for every
  declaration whose superclass/implemented/extended interfaces include
  `type_name` (a **subtype**). The declaring type itself is **excluded**.
- **METHOD mode**: emit a hit at the **method name** only for a **concrete**
  `method_declaration` named `method` (concrete = has a `block` body — so an
  interface `default`/body method qualifies, an abstract method does not), found
  in **either** the declaring type itself (label `declaration`) **or** a subtype
  that actually overrides it (label `override`). Subtypes that merely implement
  the interface but only **inherit the default are NOT emitted**. This mirrors
  jdtls: the Base `default` method IS listed; a non-overriding subtype is not.

Supertype matching (`decl_supertypes` + `collect_type_idents`) is by **simple
name** and handles generics (`Foo<Bar>`) and scoped names
(`Outer.Foo` → matches `Foo`), across grammar versions, by scanning
`superclass`/`super_interfaces`/`extends_interfaces` subtrees rather than relying
on exact field names.

`M.verify(content, iface)` is a thin type-mode wrapper kept as a unit-test seam.
`M._classify_definition` / `M._resolve_target` are exposed for debugging.

## `csimpl` CLI (`~/.local/bin/csimpl`)

Talks directly to the code-search Coral service used by the code.amazon.com
search UI / builder-mcp, via **midway-authenticated `mcurl`**:

- Endpoint: `POST https://codesearch-query-sso.corp.amazon.com/midway/`
- Headers: `accept: application/json`, `content-encoding: amz-1.0`,
  `content-type: application/json`,
  `x-amz-target: com.amazon.codesearch.query.CodeSearchQueryService.SearchCodeV2`
- Body: `{query, maxResults, rankingType:"query-relevance", snippetConfig, nextToken?}`
- Response: `{hits:[{repository.name, filePath, branches, snippets}], nextToken, totalHits}`
- Raw blob fetch (for out-of-workspace files):
  `code.amazon.com/packages/<repo>/blobs/<branch>/--/<path>?raw=1`

Subcommands: `search <query>` (raw), `impls <Type>` (candidate `.java` files,
JSON), `cat <repo> <branch> <path>` (raw blob to stdout). It appends a
`%{http_code}` sentinel to every `mcurl` call and **fails loudly on 401/403** with
"Run `mwinit`" instead of silently parsing an auth-error body into empty results
(that silent-empty behavior was the original "it just fails" bug).

## Usage / keymaps

- `glI` — buffer-local in Java files (set by `plugin/find_impls.lua`); acts on the
  type/method under the cursor. The out-of-workspace complement to `gli`.
- `:FindImpls` — same, on `<cword>`.
- `:FindImpls SomeType` — explicit **type** mode.

**Gotchas**
- Run it in a **normal file buffer**, not a diffview/edited review buffer — it
  relies on `<cword>` + LSP at the cursor; in a diff buffer LSP may be detached
  and line/column offsets shift.
- Requires a valid midway session (`mwinit`); the addon surfaces `csimpl`'s auth
  error via `vim.notify`.
- Broad-net + tree-sitter covers direct `implements`/`extends`. A leaf that
  `extends AbstractFoo` where only `AbstractFoo` implements the interface is a
  known gap (would need a recursive pass).

## Testing

Pure-Lua unit tests drive `M.analyze` on synthetic + real snippets (override vs
inherit-default vs interface-self vs generic vs scoped supertype). End-to-end is
exercised headlessly with warm jdtls:
```
nvim --headless -u ~/.config/nvim/init.lua <QueryRoutingHandler.java> -c "luafile <probe.lua>"
```
Verified on `engineLogic.extractSchemaFromInitDb(...)`: returns Base `default`
(`declaration`) + Mysql `override`, excludes Postgres (inherits default), matching
`gli` for the in-workspace results while additionally reaching out-of-workspace
overriders.
