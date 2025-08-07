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
				color_overrides = {
					frappe = {
						base = "#272C36", -- main background
						mantle = "#272C36", -- secondary background
						crust = "#272C36", -- outer borders / deepest bg
					},
				},
				custom_highlights = function(colors)
					return {
						Normal = { bg = colors.base },
						NormalFloat = { bg = colors.base },
						StatusLine = { bg = colors.base },
					}
				end,
				integrations = {
					treesitter = true,
					telescope = true,
				},
			})

			vim.cmd.colorscheme("catppuccin")
		end,
	},
}
