-- Load the addon
local addon = require('addons.lsp_references_filter')

-- Test cases
local tests = {
    {
        file = "/local/home/shayagr/workspace/brazil/dev-kermit/src/OscarMysql80/sql/sql_optimizer.cc",
        line = 11860,
        symbol = "subquery",
        expected = true,
        desc = "Assignment: subquery = ..."
    },
    {
        file = "/local/home/shayagr/workspace/brazil/dev-kermit/src/OscarMysql80/sql/sql_optimizer.cc",
        line = 11861,
        symbol = "subquery",
        expected = false,
        desc = "Comparison: subquery == nullptr"
    },
}

print("\n=== Testing is_assignment function ===\n")

local passed = 0
local failed = 0

for i, test in ipairs(tests) do
    local result = addon.is_assignment(test.file, test.line, test.symbol)
    local status = result == test.expected and "✓ PASS" or "✗ FAIL"
    
    if result == test.expected then
        passed = passed + 1
    else
        failed = failed + 1
    end
    
    print(string.format("[%d] %s - %s", i, status, test.desc))
    print(string.format("    Expected: %s, Got: %s", test.expected, result))
end

print(string.format("\n=== Results: %d passed, %d failed ===\n", passed, failed))
