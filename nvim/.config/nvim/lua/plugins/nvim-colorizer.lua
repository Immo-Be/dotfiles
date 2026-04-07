local M = {}

function M.setup()
	require("colorizer").setup({
			-- Filetypes to enable colorizer for
			-- Use "*" for all files, or specify individual filetypes
			"*", -- Enable for all filetypes
		}, {
			-- Color format options
			RGB = true, -- #RGB hex codes (3 digits)
			RRGGBB = true, -- #RRGGBB hex codes (6 digits)
			names = true, -- CSS color names like "red", "blue", etc.
			RRGGBBAA = true, -- #RRGGBBAA hex codes with alpha (8 digits)
			AARRGGBB = true, -- 0xAARRGGBB hex codes (Android style)
			rgb_fn = true, -- CSS rgb() and rgba() functions
			hsl_fn = true, -- CSS hsl() and hsla() functions
			css = true, -- Enable all CSS features (names, rgb_fn, hsl_fn)
			css_fn = true, -- Enable all CSS *functions* (rgb_fn, hsl_fn)
			-- Mode options: "foreground", "background", "virtualtext"
			mode = "background", -- Set the display mode (background highlight)
	})

	vim.keymap.set("n", "<leader>tc", ":ColorizerToggle<CR>", { desc = "Toggle colorizer", silent = true })

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
		pattern = { "*.css", "*.scss", "*.sass", "*.less", "*.html", "*.jsx", "*.tsx", "*.js", "*.ts" },
		callback = function()
			require("colorizer").attach_to_buffer(0)
		end,
	})
end

return M
