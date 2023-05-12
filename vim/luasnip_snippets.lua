local ls = require"luasnip"
local s = ls.snippet
local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local events = require("luasnip.util.events")
local ai = require("luasnip.nodes.absolute_indexer")
local fmt = require("luasnip.extras.fmt").fmt
local m = require("luasnip.extras").m
local lambda = require("luasnip.extras").l

ls.cleanup()

ls.add_snippets("all", {
    s("ternary", {
		-- equivalent to "${1:cond} ? ${2:then} : ${3:else}"
		i(1, "cond"), t(" ? "), i(2, "then"), t(" : "), i(3, "else")
	})
})

local function add_arg_placeholders(args, snip, user_arg_1)
	local params = {}
	local format_string = args[1][1]
	local pattern = '%%[dsluf]'
	local i = 0

	while true do
		i = string.find(format_string, pattern, i+1)
		if i == nil then break end

		table.insert(params, ", arg" .. tostring(#params + 1))
	end

	if #params == 0 then return "" end

	return table.concat(params, "")
end

my_snip = s("prk", {
	t({"printk(\"Shay @%s(%d): "}), i(1, "Debug print"),
	t({"\\n\", __func__, __LINE__"}),
	i(2),
	f(add_arg_placeholders, {1}, {}),
	t({");"}), i(0),
})

--  printk("Shay @%s(%d): ${1}\n", __func__, __LINE__, ${2});
ls.add_snippets("c", {
		my_snip
	})
ls.add_snippets("cpp", {
		my_snip
	})

test_snip = s("trig", c(1, {
 	t("Ugh boring, a text node"),
 	i(nil, "At least I can edit something now..."),
 	f(function(args) return "Still only counts as text!!" end, {})
 }))
ls.add_snippets("all", {
		test_snip
	})

test_snip = s("trig", c(1, {
 	t("Ugh boring, a text node"),
 	i(nil, "At least I can edit something now..."),
 	f(function(args) return "Still only counts as text!!" end, {})
 }))

-- #ifndef HEADER_NAME_H
-- #define HEADER_NAME_H
--
-- #endif /* HEADER_NAME_H */
header = s("header", {
	f(function(args, snip)
		buf_name = vim.api.nvim_eval("expand('%:t:r')")
		buf_name = string.upper(buf_name) .. "_H"
		return {"##ifndef " .. buf_name, "#define " .. buf_name, ""} end, {}),
	i(0),

	f(function(args, snip)
		buf_name = vim.api.nvim_eval("expand('%:t:r')")
		buf_name = string.upper(buf_name) .. "_H"
		return {"", "#endif /* " .. buf_name .. " */"} end, {})
})
ls.add_snippets("cpp", {
		header
	})
ls.add_snippets("c", {
		header
	})

config_file_snippet = s("draft", {
	t('DEPS_APT=""'),
	t("\n\n"),
	t("function check_if_installed() {

		return 1
	}"),
	t("\n\n"),
	t("funcion install_component() {

		return 0
	}"),
})

ls.add_snippets("c", {
		header
	})
--printk("Shay @%s(%d): sq: %u, cq: %u, adapter: %f\n", __func__, __LINE__);
