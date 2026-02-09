-- flash.nvim - Enhanced navigation with labeled jumps
-- Supercharges f/t/s motions by adding labels for instant jumping
return {
	"folke/flash.nvim",
	event = "VeryLazy",
	opts = {
		-- Labels to use for jump targets
		labels = "asdfghjklqwertyuiopzxcvbnm",
		-- Search options
		search = {
			-- Search mode: "exact", "search", or "fuzzy"
			mode = "exact",
			-- Incremental search (show results as you type)
			incremental = false,
			-- Multi window search (search across all visible windows)
			multi_window = true,
			-- Forward search direction by default
			forward = true,
			-- Wrap search around buffer ends
			wrap = true,
		},
		-- Jump behavior
		jump = {
			-- Jump position: "start", "end", "range"
			jumplist = true, -- Add jumps to jumplist
			pos = "start", -- Jump to start of match
			-- Automatically jump when there's only one match
			autojump = false,
		},
		-- Label appearance
		label = {
			-- Show labels above, below, or inline
			uppercase = false,
			-- Rainbow labels (different colors for different distances)
			rainbow = {
				enabled = false,
				-- Shade factor (0.0-1.0)
				shade = 5,
			},
			-- Label format
			format = function(opts)
				return { { opts.match.label, opts.hl_group } }
			end,
		},
		-- Highlight configuration
		highlight = {
			-- Show backdrop (dim the rest of the text)
			backdrop = true,
			-- Priority for highlighting
			priority = 5000,
		},
		-- Modes configuration
		modes = {
			-- Character search (f/F/t/T motions)
			char = {
				enabled = true,
				-- Keys to trigger flash in char mode
				keys = { "f", "F", "t", "T" },
				-- Search configuration for char mode
				search = { wrap = false },
				-- Highlight matches
				highlight = { backdrop = true },
				-- Multi-line search for char mode
				multi_line = true,
				-- Label after reaching the target
				label = { exclude = "hjkliardc" },
				-- Configuration for ";" and "," repeat
				jump = { register = false },
			},
			-- Search mode (/)
			search = {
				enabled = true,
				-- Show labels during / search
				highlight = { backdrop = false },
				-- Jump with <CR> in search mode
				jump = { history = true, register = true, nohlsearch = true },
				-- Search pattern configuration
				search = {
					mode = "search",
					incremental = true,
				},
			},
			-- Treesitter search (select by syntax node)
			treesitter = {
				labels = "abcdefghijklmnopqrstuvwxyz",
				jump = { pos = "range" },
				-- Highlight the entire range
				highlight = {
					backdrop = false,
					matches = false,
				},
			},
		},
	},
	keys = {
		-- Flash search (like enhanced / search with labels)
		-- Using <leader>s instead of 's' to preserve standard Vim 's' (substitute character)
		{
			"<leader>s",
			mode = { "n", "x", "o" },
			function()
				require("flash").jump()
			end,
			desc = "Flash jump",
		},
		-- Flash treesitter (select by syntax node)
		-- Using <leader>S instead of 'S' to preserve standard Vim 'S' (substitute line)
		{
			"<leader>S",
			mode = { "n", "x", "o" },
			function()
				require("flash").treesitter()
			end,
			desc = "Flash Treesitter",
		},
		-- Remote flash (jump to any location and execute operator)
		{
			"r",
			mode = "o",
			function()
				require("flash").remote()
			end,
			desc = "Remote Flash",
		},
		-- Treesitter search (visual mode)
		{
			"R",
			mode = { "o", "x" },
			function()
				require("flash").treesitter_search()
			end,
			desc = "Treesitter Search",
		},
		-- Toggle flash in search mode
		{
			"<c-s>",
			mode = { "c" },
			function()
				require("flash").toggle()
			end,
			desc = "Toggle Flash Search",
		},
	},
}
