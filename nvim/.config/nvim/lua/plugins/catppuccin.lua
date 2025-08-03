return {
	-- Lazy
	-- {
	-- 	"olimorris/onedarkpro.nvim",
	-- 	priority = 1000, -- Ensure it loads first
	-- },
	-- 	"navarasu/onedark.nvim",
	-- 	name = "onedark",
	-- 	config = function()
	-- 		require("onedark").setup({
	--        style = "warm",
	--      })
	-- 		vim.cmd("colorscheme onedark")
	-- 	end,
	-- },
	-- {
	-- 	"projekt0n/github-nvim-theme",
	-- 	name = "github-theme",
	-- 	lazy = false, -- make sure we load this during startup if it is your main colorscheme
	-- 	priority = 1000, -- make sure to load this before all the other start plugins
	-- 	config = function()
	-- 		require("github-theme").setup({
	-- 			-- ...
	-- 		})
	-- 		-- vim.cmd("colorscheme github_dark_dimmed")
	-- 	end,
	-- },
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000, -- Load before other plugins
		config = function()
			require("catppuccin").setup({
				flavour = "frappe", -- Choose "latte", "frappe", "macchiato", "mocha"
				integrations = {
					treesitter = true,
					telescope = true,
				},
			})
			-- somewhere in your config:
			-- vim.cmd("colorscheme onedark")
			vim.cmd.colorscheme("catppuccin")
		end,
	},
}
