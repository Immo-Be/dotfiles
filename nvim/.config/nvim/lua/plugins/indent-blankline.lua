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
		local ibl = require("ibl")
		ibl.setup(opts)
		
		-- Add custom command to toggle indent guides
		vim.api.nvim_create_user_command("IndentGuidesToggle", function()
			vim.cmd("IBLToggle")
		end, { desc = "Toggle indent guides on/off" })
	end,
}
