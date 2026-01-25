return {
	"lukas-reineke/indent-blankline.nvim",
	main = "ibl",
	event = { "BufReadPost", "BufNewFile" },
	opts = {
		indent = {
			char = "▏", -- Very subtle thin line
			tab_char = "▏",
		},
		scope = {
			enabled = true, -- Highlight current scope
			show_start = true,
			show_end = false,
			highlight = { "IblScope" }, -- Use dimmer highlight
		},
		exclude = {
			filetypes = {
				"help",
				"alpha",
				"dashboard",
				"neo-tree",
				"Trouble",
				"trouble",
				"lazy",
				"mason",
				"notify",
				"toggleterm",
				"lazyterm",
			},
		},
	},
	config = function(_, opts)
		require("ibl").setup(opts)
		
		-- Make indent lines very subtle by setting a dimmer color
		vim.api.nvim_set_hl(0, "IblIndent", { fg = "#2a2a37" }) -- Very dim gray
		vim.api.nvim_set_hl(0, "IblScope", { fg = "#3e4451" }) -- Slightly more visible for scope
	end,
}
