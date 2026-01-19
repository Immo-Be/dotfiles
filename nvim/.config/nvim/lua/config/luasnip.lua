local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

-- Helper function to capitalize first letter
local function capitalize(text)
	return text:sub(1, 1):upper() .. text:sub(2)
end

ls.add_snippets("typescriptreact", {
	s("uss", {
		t("const ["),
		i(1, "state"),
		t(", set"),
		f(function(args)
			return capitalize(args[1][1])
		end, { 1 }),
		t("] = useState<"),
		i(2, "type"),
		t(">("),
		i(3, "initialValue"),
		t(")"),
	}),
})

ls.add_snippets("javascriptreact", {
	s("uss", {
		t("const ["),
		i(1, "state"),
		t(", set"),
		f(function(args)
			return capitalize(args[1][1])
		end, { 1 }),
		t("] = useState("),
		i(2, "initialValue"),
		t(")"),
	}),
})
