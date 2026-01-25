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
		-- Set highlights before setup to ensure they're applied correctly
		vim.api.nvim_set_hl(0, "IblIndent", { fg = "#2a2a37" }) -- Very dim gray
		vim.api.nvim_set_hl(0, "IblScope", { fg = "#3e4451" }) -- Slightly more visible for scope
		
		local ibl = require("ibl")
		ibl.setup(opts)
		
		-- Refresh after a short delay to ensure correct rendering
		vim.defer_fn(function()
			vim.cmd("IBLDisable")
			vim.cmd("IBLEnable")
		end, 50)
		
		-- Add custom command to toggle indent guides
		vim.api.nvim_create_user_command("IndentGuidesToggle", function()
			vim.cmd("IBLToggle")
		end, { desc = "Toggle indent guides on/off" })
	end,
}
