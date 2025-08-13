require("luasnip.session.snippet_collection").clear_snippets("c")

local ls = require"luasnip"

local t = ls.text_node
local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node

local function add_arg_placeholders(args, snip, user_arg_1)
	local params = {}
	local format_string = args[1][1]
	local pattern = '%%[a-z]'
	local it = 0

	while true do
		it = string.find(format_string, pattern, it+1)
		if it == nil then break end

		table.insert(params, ", arg" .. tostring(#params + 1))
	end

	if #params == 0 then return "" end

	return table.concat(params, "")
end

ls.add_snippets("c", {
    s("d", {
        t({"printk(\"Shay @%s(%d): "}), i(1, "Debug print"),
        t({"\\n\", __func__, __LINE__"}),
        i(2),
        f(add_arg_placeholders, {1}, {}),
        t({");"}), i(0),
    })
})
