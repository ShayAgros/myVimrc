-- find_impls — fleet-wide "find implementations", including packages NOT in the
-- local workspace (which jdtls/`gli` cannot reach).
--
-- Works on either a TYPE or a METHOD under the cursor:
--   • TYPE   (e.g. `ConstellationEngineLogic`) → implementing classes/subtypes.
--   • METHOD (e.g. `engineLogic.extractSchemaFromInitDb(...)`) → the declaring
--     type is resolved via LSP, then each implementor is scanned for the
--     overriding method (or flagged as inheriting the default).
--
-- Pipeline (no AI):
--   1. resolve target      → LSP definition classifies method-vs-type + names
--   2. `csimpl impls <T>`  → candidate .java files fleet-wide (broad net)
--   3. tree-sitter verify  → keep only real subtypes; locate method in each
--   4. Snacks picker       → in-workspace files open locally; out-of-workspace
--                            files are fetched (raw blob) to a cache and opened.
--
-- Command: :FindImpls [Type]   (explicit arg forces TYPE mode; else uses cursor)
local M = {}

local CACHE = vim.fn.expand("~/.cache/csimpl")

-- ── workspace resolution ────────────────────────────────────────────────────
local function ws_roots()
  local roots = {}
  local bemol = vim.fs.find({ ".bemol" }, { upward = true, type = "directory" })[1]
  if bemol then
    local f = io.open(bemol .. "/ws_root_folders", "r")
    if f then
      for line in f:lines() do
        if line ~= "" then roots[#roots + 1] = line end
      end
      f:close()
    end
  end
  return roots
end

local function resolve_local(roots, cand)
  for _, root in ipairs(roots) do
    if root:match("/" .. vim.pesc(cand.repo) .. "$") then
      local p = root .. "/" .. cand.path
      if vim.uv.fs_stat(p) then return p end
    end
  end
  return nil
end

local function read_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local c = f:read("*a"); f:close(); return c
end

local function write_cache(cand, content)
  local full = string.format("%s/%s/%s/%s", CACHE, cand.repo, cand.branch, cand.path)
  vim.fn.mkdir(vim.fn.fnamemodify(full, ":h"), "p")
  local f = io.open(full, "w")
  if f then f:write(content); f:close() end
  return full
end

-- ── tree-sitter helpers ─────────────────────────────────────────────────────
local DECL_TYPES = {
  class_declaration = true, interface_declaration = true,
  enum_declaration = true, record_declaration = true,
}
local SUPER_NODES = {
  superclass = true, super_interfaces = true,
  extends_interfaces = true, interfaces = true,
}

local function collect_type_idents(node, content, acc)
  for child in node:iter_children() do
    local t = child:type()
    if t == "type_identifier" then
      acc[vim.treesitter.get_node_text(child, content)] = true
    elseif t == "scoped_type_identifier" then
      local txt = vim.treesitter.get_node_text(child, content)
      acc[txt] = true
      local last = txt:match("([%w_]+)%s*$")
      if last then acc[last] = true end
    end
    collect_type_idents(child, content, acc)
  end
end

local function decl_supertypes(node, content)
  local supers = {}
  for child in node:iter_children() do
    if SUPER_NODES[child:type()] then collect_type_idents(child, content, supers) end
  end
  return supers
end

-- Find a *concrete* method_declaration named `method` inside a type decl's body
-- (concrete = has a block body; excludes abstract/interface-abstract methods).
-- Returns start {row0,col0} of the method name, or nil.
local function find_concrete_method(decl, content, method)
  local body
  for child in decl:iter_children() do
    local t = child:type()
    if t == "class_body" or t == "interface_body" or t == "enum_body"
        or t == "enum_body_declarations" then
      body = child; break
    end
  end
  if not body then return nil end
  for child in body:iter_children() do
    if child:type() == "method_declaration" then
      local namenode = child:field("name")[1]
      if namenode and vim.treesitter.get_node_text(namenode, content) == method then
        local has_block = false
        for c in child:iter_children() do
          if c:type() == "block" then has_block = true; break end
        end
        if has_block then
          local r, c = namenode:start()
          return { row0 = r, col0 = c }
        end
      end
    end
  end
  return nil
end

-- Core analysis.
--   TYPE mode  (method == nil): every subtype of `type_name` → class name.
--   METHOD mode: every *concrete* declaration of `method` in the declaring type
--     itself OR in a subtype that overrides it (matches jdtls semantics —
--     includes the interface default, excludes subtypes that only inherit it).
function M.analyze(content, type_name, method)
  local ok, parser = pcall(vim.treesitter.get_string_parser, content, "java")
  if not ok or not parser then return {} end
  local tree = (parser:parse() or {})[1]
  if not tree then return {} end
  local root = tree:root()

  local hits = {}
  local function walk(node)
    for child in node:iter_children() do
      if DECL_TYPES[child:type()] then
        local namenode = child:field("name")[1]
        local this_name = namenode and vim.treesitter.get_node_text(namenode, content) or nil
        local supers = decl_supertypes(child, content)
        local is_subtype = supers[type_name] == true
        local is_declaring = (this_name == type_name)
        if method then
          if is_subtype or is_declaring then
            local m = find_concrete_method(child, content, method)
            if m then
              hits[#hits + 1] = {
                row0 = m.row0, col0 = m.col0,
                label = is_declaring and "declaration" or "override",
              }
            end
            -- no concrete method here → inherits default / abstract → skip
          end
        elseif is_subtype then
          local nr, nc = 0, 0
          if namenode then nr, nc = namenode:start() end
          hits[#hits + 1] = { row0 = nr, col0 = nc, label = "" }
        end
      end
      walk(child) -- nested types
    end
  end
  walk(root)
  return hits
end

-- Back-compat / unit-test seam: positions of subtypes of `iface`.
function M.verify(content, iface)
  local out = {}
  for _, h in ipairs(M.analyze(content, iface, nil)) do
    out[#out + 1] = { line0 = h.row0, col0 = h.col0 }
  end
  return out
end

-- ── item building ───────────────────────────────────────────────────────────
local function add_items(items, target, content, file, cand, in_ws)
  local lines = vim.split(content, "\n", { plain = true })
  for _, h in ipairs(M.analyze(content, target.type_name, target.method)) do
    local text = lines[h.row0 + 1] or ""
    items[#items + 1] = {
      file = file,
      pos = { h.row0 + 1, h.col0 + 1 },
      line = text,
      text = text,
      repo = cand.repo,
      in_ws = in_ws,
      label = h.label,
    }
  end
end

-- ── presentation ────────────────────────────────────────────────────────────
local function show(target, items)
  local what = target.method and (target.type_name .. "." .. target.method) or target.type_name
  if #items == 0 then
    vim.notify("find_impls: no implementations of '" .. what .. "' found", vim.log.levels.WARN)
    return
  end
  table.sort(items, function(a, b)
    if a.in_ws ~= b.in_ws then return a.in_ws end
    return a.file < b.file
  end)

  if #items == 1 then
    local it = items[1]
    vim.cmd("edit " .. vim.fn.fnameescape(it.file))
    vim.api.nvim_win_set_cursor(0, { it.pos[1], it.pos[2] - 1 })
    vim.notify("find_impls: 1 implementation (" .. it.repo ..
      (it.in_ws and "" or ", fetched") .. ")")
    return
  end

  local snacks_ok = pcall(require, "snacks")
  if not snacks_ok or not Snacks or not Snacks.picker then
    local qf = {}
    for _, it in ipairs(items) do
      qf[#qf + 1] = { filename = it.file, lnum = it.pos[1], col = it.pos[2], text = it.text }
    end
    vim.fn.setqflist(qf, "r"); vim.cmd("copen")
    return
  end

  local formatters = require("formatters.snacks_formatters")
  Snacks.picker({
    source = "csimpl_implementations",
    finder = function() return items end,
    format = formatters.Shayagr_format_brazil_ws or Snacks.picker.format.file,
    preview = formatters.Shayagr_workspace_aware_file_preview,
    jump = { tagstack = true },
  })
end

-- ── orchestration ───────────────────────────────────────────────────────────
local function run_search(target, on_done)
  on_done = on_done or function(items) show(target, items) end
  vim.system({ "csimpl", "impls", target.type_name, "--json" }, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        vim.notify("find_impls: csimpl failed: " .. (res.stderr or ""), vim.log.levels.ERROR)
        return on_done({})
      end
      local ok, cands = pcall(vim.json.decode, res.stdout)
      if not ok or type(cands) ~= "table" then
        vim.notify("find_impls: bad JSON from csimpl", vim.log.levels.ERROR)
        return on_done({})
      end
      local roots = ws_roots()
      local items = {}
      local pending = #cands
      if pending == 0 then return on_done(items) end
      local function done()
        pending = pending - 1
        if pending == 0 then on_done(items) end
      end
      for _, cand in ipairs(cands) do
        local localp = resolve_local(roots, cand)
        if localp then
          local content = read_file(localp)
          if content then add_items(items, target, content, localp, cand, true) end
          done()
        else
          vim.system({ "csimpl", "cat", cand.repo, cand.branch, cand.path }, { text = true },
            function(r2)
              vim.schedule(function()
                local c = r2.stdout
                if r2.code == 0 and c and #c > 0 and not c:match("^%s*<") then
                  add_items(items, target, c, write_cache(cand, c), cand, false)
                end
                done()
              end)
            end)
        end
      end
    end)
  end)
end

-- Classify an LSP definition site into {kind, type_name, method} using tree-sitter.
local function classify_definition(file, row0, col0)
  local content = read_file(file)
  if not content then return nil end
  local ok, parser = pcall(vim.treesitter.get_string_parser, content, "java")
  if not ok or not parser then return nil end
  local tree = (parser:parse() or {})[1]
  if not tree then return nil end
  local node = tree:root():named_descendant_for_range(row0, col0, row0, col0)
  while node do
    local t = node:type()
    if t == "method_declaration" then
      local mn = node:field("name")[1]
      local method = mn and vim.treesitter.get_node_text(mn, content) or nil
      local p = node:parent()
      while p and not DECL_TYPES[p:type()] do p = p:parent() end
      local tn = p and p:field("name")[1]
      local type_name = tn and vim.treesitter.get_node_text(tn, content) or nil
      if method and type_name then
        return { kind = "method", type_name = type_name, method = method }
      end
      return nil
    elseif DECL_TYPES[t] then
      local tn = node:field("name")[1]
      local type_name = tn and vim.treesitter.get_node_text(tn, content) or nil
      if type_name then return { kind = "type", type_name = type_name } end
      return nil
    end
    node = node:parent()
  end
  return nil
end

-- Resolve the target (type or method) under the cursor via LSP definition.
local function resolve_target(bufnr, cb)
  local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/definition" })
  local cword = vim.fn.expand("<cword>")
  if #clients == 0 then
    return cb({ kind = "type", type_name = cword })
  end
  local params = vim.lsp.util.make_position_params(0, clients[1].offset_encoding)
  vim.lsp.buf_request(bufnr, "textDocument/definition", params, function(err, result)
    vim.schedule(function()
      if err or not result or vim.tbl_isempty(result) then
        return cb({ kind = "type", type_name = cword })
      end
      local loc = result[1] or result
      local uri = loc.uri or loc.targetUri
      local range = loc.targetSelectionRange or loc.targetRange or loc.range
      local file = vim.uri_to_fname(uri)
      local t = classify_definition(file, range.start.line, range.start.character)
      if t then return cb(t) end
      cb({ kind = "type", type_name = cword })
    end)
  end)
end

-- ── entry points ────────────────────────────────────────────────────────────
function M.find(arg, on_done)
  if vim.fn.executable("csimpl") == 0 then
    vim.notify("find_impls: `csimpl` not on PATH", vim.log.levels.ERROR)
    return
  end
  if arg and arg ~= "" then -- explicit type
    vim.notify("find_impls: searching implementors of '" .. arg .. "'…")
    return run_search({ kind = "type", type_name = arg }, on_done)
  end
  local bufnr = vim.api.nvim_get_current_buf()
  resolve_target(bufnr, function(target)
    if not target or not target.type_name then
      vim.notify("find_impls: could not resolve a type/method under cursor", vim.log.levels.WARN)
      return
    end
    local what = target.method and (target.type_name .. "." .. target.method) or target.type_name
    vim.notify("find_impls: searching implementations of '" .. what .. "'…")
    run_search(target, on_done)
  end)
end

vim.api.nvim_create_user_command("FindImpls", function(o) M.find(o.args) end, {
  nargs = "?", desc = "Fleet-wide find implementations (csimpl + tree-sitter)",
})

-- test/debug seams
M._classify_definition = classify_definition
M._resolve_target = resolve_target

return M
