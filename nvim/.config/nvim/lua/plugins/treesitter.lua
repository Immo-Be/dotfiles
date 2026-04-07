local M = {}

function M.setup()
	require("nvim-treesitter.configs").setup({
		ensure_installed = {
			"markdown",
			"markdown_inline",
			"toml",
			"yaml",
			"go",
			"gotmpl",
			"javascript",
			"typescript",
			"tsx", -- TypeScript + React TSX
			"svelte",
			"html",
			"css",
			"json", -- Web dev essentials
			"lua",
			"vim", -- Neovim scripting
			"astro",
		},
		sync_install = false,
		highlight = { enable = true, additional_vim_regex_highlighting = false },
		indent = { enable = true },
		autotag = { enable = true }, -- Auto-close & rename JSX/Svelte tags
		-- Note: rainbow-delimiters is configured separately below (not in treesitter config)

		-- ⬇️ Incremental selection = grow/shrink by syntax node
		incremental_selection = {
			enable = true,
			keymaps = {
				init_selection = "<CR>", -- Start selection with Enter
				node_incremental = "<CR>", -- Expand selection with Enter
				node_decremental = "-", -- Shrink selection with -
				scope_incremental = "grc",
			},
		},

		matchup = { enable = true }, -- optional, enhances tag motions
		-- Treesitter Textobjects
		textobjects = {
			select = {
				enable = true,
				lookahead = true,
				keymaps = {
					["af"] = "@function.outer",
					["if"] = "@function.inner",
					["ac"] = "@class.outer",
					["ic"] = "@class.inner",
					["al"] = "@loop.outer",
					["il"] = "@loop.inner",
					["aa"] = "@parameter.outer",
					["ia"] = "@parameter.inner",
				},
			},
			move = {
				enable = true,
				set_jumps = true,
				goto_next_start = {
					["]m"] = { query = "@function.outer", desc = "Next function" },
					-- these are not used becase we use [ / [c for navigating between changes
					-- ["]c"] = { query = "@class.outer", desc = "Next class" },
					["]a"] = { query = "@parameter.outer", desc = "Next parameter" },
					["]r"] = { query = "@return.outer", desc = "Next return statement" },
				},
				goto_next_end = {
					["]M"] = "@function.outer",
					["]C"] = "@class.outer",
					["]A"] = "@parameter.outer",
				},
				goto_previous_start = {
					["[m"] = { query = "@function.outer", desc = "Previous function" },
					-- ["[c"] = { query = "@class.outer", desc = "Previous class" },
					["[a"] = { query = "@parameter.outer", desc = "Previous parameter" },
					["[r"] = { query = "@return.outer", desc = "Previous return statement" }, -- Jump to previous return statement
				},
				goto_previous_end = {
					["[M"] = "@function.outer",
					["[C"] = "@class.outer",
					["[A"] = "@parameter.outer",
				},
			},
			swap = {
				enable = true,
				swap_next = {
					["<leader>sp"] = "@parameter.inner",
				},
				swap_previous = {
					["<leader>sP"] = "@parameter.inner",
				},
			},
		},
	})

	vim.keymap.set("x", "+", "<CR>", { remap = true, desc = "Expand selection (alias for Enter)" })

	require("treesitter-context").setup({
		enable = true,
		throttle = true,
		max_lines = 2,
		patterns = {
			default = {
				"class",
				"function",
				"method",
			},
		},
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
