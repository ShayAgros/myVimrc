-- We align to Amazon's common coding standard
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- helper function for checking if a table contains a value
local function contains(table, value)
    for _, table_value in ipairs(table) do
        if table_value == value then
            return true
        end
    end

    return false
end

-- helper function for finding a filename in a directory which matches
-- the specified pattern
local function find_file(directory, pattern)
    local filename_found = ''
    local pfile = io.popen('ls "' .. directory .. '"')

    if (pfile == nil) then
        return ''
    end

    for filename in pfile:lines() do
        if (string.find(filename, pattern) ~= nil) then
            filename_found = filename
            break
        end
    end

    return filename_found
end

-- gathers all of the bemol-generated files and adds them to the LSP workspace
local function bemol()
    local bemol_dir = vim.fs.find({ ".bemol" }, { upward = true, type = "directory" })[1]
    local ws_folders_lsp = {}
    if bemol_dir then
        local file = io.open(bemol_dir .. "/ws_root_folders", "r")
        if file then
            for line in file:lines() do
                table.insert(ws_folders_lsp, line)
            end
            file:close()
        end

        for _, line in ipairs(ws_folders_lsp) do
            if not contains(vim.lsp.buf.list_workspace_folders(), line) then
                vim.lsp.buf.add_workspace_folder(line)
            end
        end
    end
end

local jdtls = require "jdtls"
local jdtls_setup = require "jdtls.setup"

local home = os.getenv("HOME")
local root_markers = { ".bemol", }
local root_dir = jdtls_setup.find_root(root_markers)

if not root_dir then
    root_dir = vim.fn.fnamemodify("%", ":p:h")   
end

local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")

-- If the project is part of 'patches' directory then all brazil workspaces would
-- simply be called 'workspace'. To distinguish them use the project name
local patch_name = string.match(root_dir, "workspace/patches/([^/]+)")
if patch_name then
    project_name = patch_name .. "-" .. project_name
end

local workspace_dir = home .. "/.cache/jdtls/workspace/" .. project_name
local path_to_jdtls = home .. "/workspace/software/jdtls"
local os_type = vim.fn.has("macunix") == 1 and "mac" or "linux"
local path_to_config = path_to_jdtls .. "/config_" .. os_type
local path_to_lombok = path_to_jdtls .. "/lombok.jar"
local path_to_plugins = path_to_jdtls .. "/plugins/"
-- the eclipse jar is suffixed with a bunch of version nonsense, so we find it by pattern matching
local path_to_jar = path_to_plugins .. find_file(path_to_plugins, "org.eclipse.equinox.launcher_")

local bundles = {
  vim.fn.glob(home .. "/workspace/software/java-debug/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-*.jar", true),
}

local vscode_test_jars = vim.fn.glob(home .. "/workspace/software/vscode-java-test/server/*.jar", true)
if vscode_test_jars ~= "" then
  vim.list_extend(bundles, vim.split(vscode_test_jars, "\n"))
end

-- jdtls requires Java 21+. The exact JVM path varies by machine: Amazon Corretto
-- installs carry a version suffix (amazon-corretto-21.0.10.7.1-linux-x64) while
-- OpenJDK uses a different stem. Probe candidates instead of hardcoding one path.
local function find_java21()
    local candidates = {}
    -- Prefer Corretto 21 (matches the Amazon build fleet).
    vim.list_extend(candidates, vim.fn.glob("/usr/lib/jvm/*corretto-21*/bin/java", true, true))
    vim.list_extend(candidates, vim.fn.glob("/usr/lib/jvm/java-21-amazon-corretto*/bin/java", true, true))
    -- Fall back to any OpenJDK 21.
    vim.list_extend(candidates, vim.fn.glob("/usr/lib/jvm/*-21-openjdk*/bin/java", true, true))
    vim.list_extend(candidates, vim.fn.glob("/usr/lib/jvm/java-1.21.*/bin/java", true, true))
    for _, p in ipairs(candidates) do
        if vim.fn.executable(p) == 1 then
            return p
        end
    end
    return nil
end

local java_bin = find_java21()
if not java_bin then
    vim.api.nvim_echo({
        { "[jdtls] No Java 21+ runtime found under /usr/lib/jvm; jdtls not started. "
            .. "Install Amazon Corretto 21 or edit ftplugin/java.lua.", "WarningMsg" },
    }, true, {})
    return
end

local config = {
    cmd = {
        -- jdtls requires Java 21+ (resolved dynamically above)
        java_bin,
        "-Declipse.application=org.eclipse.jdt.ls.core.id1",
        "-Dosgi.bundles.defaultStartLevel=4",
        "-Declipse.product=org.eclipse.jdt.ls.core.product",
        "-Dlog.protocol=true",
        "-Dlog.level=ALL",
        "-Xmx1g",
        "-javaagent:" .. path_to_lombok,
        "--add-modules=ALL-SYSTEM",
        "--add-opens",
        "java.base/java.util=ALL-UNNAMED",
        "--add-opens",
        "java.base/java.lang=ALL-UNNAMED",

        "-jar",
        path_to_jar,

        "-configuration",
        path_to_config,

        "-data",
        workspace_dir,
    },

    init_options = {
        bundles = bundles
    },

    root_dir = root_dir,

    capabilities = {
        workspace = {
            configuration = true
        },
        textDocument = {
            completion = {
                completionItem = {
                    snippetSupport = true
                }
            }
        }
    },

    settings = {
        java = {
            references = {
                includeDecompiledSources = true,
            },
            eclipse = {
                downloadSources = true,
            },
            maven = {
                downloadSources = true,
            },
            sources = {
                organizeImports = {
                    starThreshold = 9999,
                    staticStarThreshold = 9999,
                },
            },
        }
    },

    on_attach = function()
        bemol()
        require('jdtls').setup_dap({ hotcodereplace = 'auto' })
    end,
}

jdtls.start_or_attach(config)



-- LSP-based [[ and ]] navigation.
-- [[  Jump to the start of the enclosing scope:
--       - inside a method body     → the method's signature line
--       - in a javadoc / between    → the enclosing class/interface
--       - at a signature line       → walk up to the parent scope
-- ]]  Jump to the next method/class signature below the cursor.
local function lsp_jump_to_function(direction)
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    local has_lsp = next(clients) ~= nil

    if not has_lsp then
        vim.notify("[[ / ]]: No LSP attached, using default motion", vim.log.levels.INFO)
        local keys = direction == "prev" and "[[" or "]]"
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
        return
    end

    local current_line = vim.api.nvim_win_get_cursor(0)[1] - 1

    local ok, _ = pcall(vim.lsp.buf_request, 0, "textDocument/documentSymbol", {
        textDocument = vim.lsp.util.make_text_document_params()
    }, function(err, result)
        if err or not result then
            vim.notify("[[ / ]]: LSP documentSymbol failed, using default motion", vim.log.levels.INFO)
            local keys = direction == "prev" and "[[" or "]]"
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
            return
        end

        -- Collect every navigable symbol with its signature line and full range.
        -- SymbolKind: 5=Class, 6=Method, 9=Constructor, 11=Interface, 12=Function, 10=Enum, 23=Struct
        local symbols = {}
        local function collect(syms)
            for _, s in ipairs(syms) do
                local kind = s.kind
                if kind == 5 or kind == 6 or kind == 9 or kind == 10
                    or kind == 11 or kind == 12 or kind == 23 then
                    local sig = s.selectionRange and s.selectionRange.start.line
                        or s.range and s.range.start.line
                    local fin = s.range and s.range["end"].line or sig
                    if sig then
                        table.insert(symbols, { sig = sig, fin = fin })
                    end
                end
                if s.children then collect(s.children) end
            end
        end
        collect(result)

        local target_line = nil

        if direction == "next" then
            -- Smallest signature line strictly below the cursor.
            local best = nil
            for _, s in ipairs(symbols) do
                if s.sig > current_line and (best == nil or s.sig < best) then
                    best = s.sig
                end
            end
            target_line = best
        else
            -- Enclosing scope: largest signature line strictly above the cursor
            -- whose range still contains the cursor. Walks up one level each press.
            local best = nil
            for _, s in ipairs(symbols) do
                if s.sig < current_line and s.fin >= current_line then
                    if best == nil or s.sig > best then
                        best = s.sig
                    end
                end
            end
            -- Fallback: if nothing encloses (e.g. cursor below all code), take the
            -- nearest signature line above.
            if best == nil then
                for _, s in ipairs(symbols) do
                    if s.sig < current_line and (best == nil or s.sig > best) then
                        best = s.sig
                    end
                end
            end
            target_line = best
        end

        if target_line then
            vim.cmd("normal! m'")
            vim.api.nvim_win_set_cursor(0, { target_line + 1, 0 })
        end
    end)

    if not ok then
        vim.notify("[[ / ]]: LSP request error, using default motion", vim.log.levels.INFO)
        local keys = direction == "prev" and "[[" or "]]"
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
    end
end

vim.keymap.set("n", "[[", function() lsp_jump_to_function("prev") end,
    { buffer = true, silent = true, desc = "Previous function (LSP)" })
vim.keymap.set("n", "]]", function() lsp_jump_to_function("next") end,
    { buffer = true, silent = true, desc = "Next function (LSP)" })
