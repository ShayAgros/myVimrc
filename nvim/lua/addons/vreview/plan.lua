-- vreview.plan: locate and load the workspace review plan (.vreview/review_plan.json).
--
-- The plan is written by the review-cr-code skill at the Brazil workspace root
-- and describes which packages changed and the recommended review order:
--
--   {
--     "cr": "CR-XXXXXXXX" | null,
--     "base": "mainline" | null,
--     "packages": [
--       { "order": 1, "name": "ConstellationSqlParser",
--         "path": "src/ConstellationSqlParser",
--         "vreview_arg": "mainline",   -- exact arg to hand to vreview / DiffviewOpen
--         "commits": 2,                -- commits in the range (0 = working tree)
--         "summary": "Parser: PIN/UNPIN keywords" }
--     ]
--   }

local M = {}

local function read_file(path)
    local fd = io.open(path, "r")
    if not fd then return nil end
    local data = fd:read("*a")
    fd:close()
    return data
end

-- vim.json.decode represents JSON `null` as vim.NIL (a userdata), which is
-- TRUTHY in Lua — so `if obj.cr then ...` passes for a null field and later
-- string ops crash. Recursively replace vim.NIL with real nil.
local function denil(v)
    if v == vim.NIL then return nil end
    if type(v) == "table" then
        for k, val in pairs(v) do v[k] = denil(val) end
    end
    return v
end

-- Find the Brazil workspace root by walking up from `start` looking for a
-- .vreview/review_plan.json, then (fallback) a packageInfo marker.
-- Returns workspace_root, plan_path (plan_path may be nil if only packageInfo found).
function M.find_workspace_root(start)
    start = start or vim.fn.getcwd()

    -- Walk parents explicitly looking for .vreview/review_plan.json (vim.fs.find
    -- matches leaf names, not nested paths, so we do it by hand).
    local dir = vim.fn.fnamemodify(start, ":p")
    while dir and dir ~= "/" do
        local plan = dir .. "/.vreview/review_plan.json"
        if vim.fn.filereadable(plan) == 1 then
            return dir:gsub("/$", ""), plan
        end
        local parent = vim.fn.fnamemodify(dir, ":h")
        if parent == dir then break end
        dir = parent
    end

    -- Fallback: nearest ancestor with a packageInfo (the Brazil workspace root
    -- in this setup lives at the dir that holds packageInfo).
    local ws = vim.fs.root(start, "packageInfo")
    if ws then return ws, nil end
    return nil, nil
end

-- Load and validate the plan. Returns a table { root, cr, base, packages } or nil.
function M.load(start)
    local root, plan_path = M.find_workspace_root(start)
    if not root or not plan_path then return nil, root end

    local data = read_file(plan_path)
    if not data then return nil, root end
    local ok, obj = pcall(vim.json.decode, data)
    if not ok or type(obj) ~= "table" or type(obj.packages) ~= "table" then
        return nil, root
    end
    obj = denil(obj)   -- JSON null -> real nil (vim.NIL is truthy otherwise)

    -- Sort packages by order (stable) and normalize absolute paths.
    table.sort(obj.packages, function(a, b)
        return (a.order or math.huge) < (b.order or math.huge)
    end)
    for _, p in ipairs(obj.packages) do
        if p.path and not p.path:match("^/") then
            p.abs_path = root .. "/" .. p.path
        else
            p.abs_path = p.path
        end
    end

    return {
        root = root,
        cr = obj.cr,
        base = obj.base,
        packages = obj.packages,
    }
end

return M
