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


ls.add_snippets("all", {
    s("ternary", {
		-- equivalent to "${1:cond} ? ${2:then} : ${3:else}"
		i(1, "cond"), t(" ? "), i(2, "then"), t(" : "), i(3, "else")
	})
})

ls.add_snippets("all",  {
	s("trigger", {
		t({"After expanding, the cursor is here ->"}), i(1),
		t({"", "After jumping forward once, cursor is here ->"}), i(2),
		t({"", "After jumping once more, the snippet is exited there ->"}), i(0),
	})
	}
)

local function reused_func(_,_, user_arg1)
	return user_arg1
end
ls.add_snippets("all", {
	s("trig", {
		f(reused_func, {}, {
			user_args = {"text"}
		}),
		f(reused_func, {}, {
			user_args = {"different text"}
		}),
	})
	})
