return {
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
						mantle = "#272c36", -- secondary background
						crust = "#20252e", -- outer borders / deepest bg
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
