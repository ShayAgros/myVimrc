local addon = require('addons.lsp_references_filter')

local tests = {
    {
        file = "/local/home/shayagr/workspace/brazil/dev-kermit/src/OscarMysql80/sql/item_subselect.cc",
        line = 157,
        symbol = "item",
        expected = true,
        desc = "Field assignment: unit->item = this"
    },
    {
        file = "/local/home/shayagr/workspace/brazil/dev-kermit/src/OscarMysql80/sql/sql_optimizer.cc",
        line = 11860,
        symbol = "subquery",
        expected = true,
        desc = "Variable assignment: subquery = ..."
    },
}

print("\n=== Testing field assignment detection ===\n")

for i, test in ipairs(tests) do
    local result = addon.is_assignment(test.file, test.line, test.symbol)
    local status = result == test.expected and "✓ PASS" or "✗ FAIL"
    print(string.format("[%d] %s - %s", i, status, test.desc))
    print(string.format("    Expected: %s, Got: %s", test.expected, result))
end
