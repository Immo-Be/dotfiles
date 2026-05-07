local M = {}

function M.setup()
	require("catppuccin").setup({

		transparent_background = true, -- disables setting the background color.
		float = {
			transparent = true, -- enable transparent floating windows
			solid = true, -- use solid styling for floating windows, see |winborder|
		},
		flavour = "frappe",
		color_overrides = {
			frappe = {
				-- base = "#272C36",
				-- mantle = "#272c36",
				-- crust = "#20252e",
			},
		},
		custom_highlights = function(colors)
			return {
				Normal = { bg = colors.base },
				NormalFloat = { bg = colors.base },
				StatusLine = { bg = colors.base },
				-- IblIndent = { fg = "#2a2a37" },
				-- IblScope = { fg = "#3e4451" },
			}
		end,
		integrations = {
			treesitter = true,
			telescope = true,
		},
	})

	vim.cmd.colorscheme("catppuccin")
end

return M
