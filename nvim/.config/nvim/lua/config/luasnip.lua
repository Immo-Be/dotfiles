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
	s("useState", {
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
	s("useState", {
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

for _, ft in ipairs({ "css", "scss", "sass", "less" }) do
	ls.add_snippets(ft, {
		s("abs", {
			t("position: absolute;"),
			t({ "", "top: 50%;" }),
			t({ "", "left: 50%;" }),
			t({ "", "transform: translate(-50%, -50%);" }),
		}),
		s("reset", {
			t({
				"@layer {",
				"\t*,",
				"\t*::before,",
				"\t*::after {",
				"\t\tbox-sizing: border-box;",
				"\t}",
				"",
				"\t* {",
				"\t\tmargin: 0;",
				"\t}",
				"",
				"\tbody {",
				"\t\tmin-height: 100vh;",
				"\t\tline-height: 1.5;",
				"\t\t-webkit-font-smoothing: antialiased;",
				"\t}",
				"",
				"\timg,",
				"\tpicture,",
				"\tvideo,",
				"\tcanvas,",
				"\tsvg {",
				"\t\tdisplay: block;",
				"\t\tmax-width: 100%;",
				"\t}",
				"",
				"\tinput,",
				"\tbutton,",
				"\ttextarea,",
				"\tselect {",
				"\t\tfont: inherit;",
				"\t}",
				"",
				"\tp,",
				"\th1,",
				"\th2,",
				"\th3,",
				"\th4,",
				"\th5,",
				"\th6 {",
				"\t\toverflow-wrap: break-word;",
				"\t}",
				"",
				"\tp {",
				"\t\ttext-wrap: pretty;",
				"\t}",
				"",
				"\th1,",
				"\th2,",
				"\th3,",
				"\th4,",
				"\th5,",
				"\th6 {",
				"\t\ttext-wrap: balance;",
				"\t}",
				"",
				"\t#root,",
				"\t#__next {",
				"\t\tisolation: isolate;",
				"\t}",
				"}",
			}),
		}),
	})
end
