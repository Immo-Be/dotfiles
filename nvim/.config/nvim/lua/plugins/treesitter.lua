local M = {}

local desired_parsers = {
	"markdown",
	"markdown_inline",
	"toml",
	"yaml",
	"go",
	"gotmpl",
	"javascript",
	"typescript",
	"tsx",
	"svelte",
	"html",
	"css",
	"json",
	"lua",
	"vim",
	"astro",
}

local desired_parser_set = {}
for _, parser in ipairs(desired_parsers) do
	desired_parser_set[parser] = true
end

local function ensure_parsers_installed()
	if #vim.api.nvim_list_uis() == 0 then
		return
	end

	local treesitter = require("nvim-treesitter")
	local installed = {}
	for _, parser in ipairs(treesitter.get_installed()) do
		installed[parser] = true
	end

	local missing = {}
	for _, parser in ipairs(desired_parsers) do
		if not installed[parser] then
			table.insert(missing, parser)
		end
	end

	if #missing == 0 then
		return
	end

	vim.schedule(function()
		treesitter.install(missing, { summary = true })
	end)
end

local function enable_treesitter(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(bufnr) or not vim.bo[bufnr].buflisted then
		return
	end

	local filetype = vim.bo[bufnr].filetype
	if filetype == "" then
		return
	end

	local lang = vim.treesitter.language.get_lang(filetype)
	if not lang then
		return
	end

	local ok = pcall(vim.treesitter.start, bufnr, lang)
	if not ok then
		return
	end

	if desired_parser_set[lang] then
		vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		vim.bo[bufnr].syntax = "off"
	end
end

local function setup_textobjects()
	require("nvim-treesitter-textobjects").setup({
		select = {
			lookahead = true,
		},
		move = {
			set_jumps = true,
		},
	})

	local select = require("nvim-treesitter-textobjects.select")
	local move = require("nvim-treesitter-textobjects.move")
	local swap = require("nvim-treesitter-textobjects.swap")

	local select_keymaps = {
		["af"] = "@function.outer",
		["if"] = "@function.inner",
		["ac"] = "@class.outer",
		["ic"] = "@class.inner",
		["al"] = "@loop.outer",
		["il"] = "@loop.inner",
		["aa"] = "@parameter.outer",
		["ia"] = "@parameter.inner",
	}

	for lhs, query in pairs(select_keymaps) do
		vim.keymap.set({ "x", "o" }, lhs, function()
			select.select_textobject(query, "textobjects")
		end)
	end

	local next_start = {
		["]m"] = { query = "@function.outer", desc = "Next function" },
		["]a"] = { query = "@parameter.outer", desc = "Next parameter" },
		["]r"] = { query = "@return.outer", desc = "Next return statement" },
	}

	for lhs, entry in pairs(next_start) do
		vim.keymap.set({ "n", "x", "o" }, lhs, function()
			move.goto_next_start(entry.query, "textobjects")
		end, { desc = entry.desc })
	end

	local next_end = {
		["]M"] = { query = "@function.outer", desc = "Next function end" },
		["]C"] = { query = "@class.outer", desc = "Next class end" },
		["]A"] = { query = "@parameter.outer", desc = "Next parameter end" },
	}

	for lhs, entry in pairs(next_end) do
		vim.keymap.set({ "n", "x", "o" }, lhs, function()
			move.goto_next_end(entry.query, "textobjects")
		end, { desc = entry.desc })
	end

	local prev_start = {
		["[m"] = { query = "@function.outer", desc = "Previous function" },
		["[a"] = { query = "@parameter.outer", desc = "Previous parameter" },
		["[r"] = { query = "@return.outer", desc = "Previous return statement" },
	}

	for lhs, entry in pairs(prev_start) do
		vim.keymap.set({ "n", "x", "o" }, lhs, function()
			move.goto_previous_start(entry.query, "textobjects")
		end, { desc = entry.desc })
	end

	local prev_end = {
		["[M"] = { query = "@function.outer", desc = "Previous function end" },
		["[C"] = { query = "@class.outer", desc = "Previous class end" },
		["[A"] = { query = "@parameter.outer", desc = "Previous parameter end" },
	}

	for lhs, entry in pairs(prev_end) do
		vim.keymap.set({ "n", "x", "o" }, lhs, function()
			move.goto_previous_end(entry.query, "textobjects")
		end, { desc = entry.desc })
	end

	vim.keymap.set("n", "<leader>sp", function()
		swap.swap_next("@parameter.inner")
	end, { desc = "Swap with next parameter" })

	vim.keymap.set("n", "<leader>sP", function()
		swap.swap_previous("@parameter.inner")
	end, { desc = "Swap with previous parameter" })
end

function M.setup()
	ensure_parsers_installed()

	local treesitter_group = vim.api.nvim_create_augroup("TreesitterSetup", { clear = true })
	vim.api.nvim_create_autocmd("FileType", {
		group = treesitter_group,
		pattern = "*",
		callback = function(args)
			enable_treesitter(args.buf)
		end,
	})

	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		enable_treesitter(bufnr)
	end

	require("nvim-ts-autotag").setup({
		opts = {
			enable_close = true,
			enable_rename = true,
			enable_close_on_slash = false,
		},
	})

	setup_textobjects()

	require("treesitter-context").setup({
		enable = true,
		max_lines = 2,
		multiline_threshold = 20,
		trim_scope = "outer",
		mode = "cursor",
	})

	vim.keymap.set("n", "[f", function()
		require("treesitter-context").go_to_context()
	end, { desc = "Jump to sticky function" })

	local rainbow_delimiters = require("rainbow-delimiters")
	require("rainbow-delimiters.setup").setup({
		strategy = {
			[""] = rainbow_delimiters.strategy["global"],
			vim = rainbow_delimiters.strategy["local"],
		},
		query = {
			[""] = "rainbow-delimiters",
			lua = "rainbow-blocks",
		},
		priority = {
			[""] = 110,
			lua = 210,
		},
		highlight = {
			"RainbowDelimiterRed",
			"RainbowDelimiterYellow",
			"RainbowDelimiterBlue",
			"RainbowDelimiterOrange",
			"RainbowDelimiterGreen",
			"RainbowDelimiterViolet",
			"RainbowDelimiterCyan",
		},
	})
end

return M
