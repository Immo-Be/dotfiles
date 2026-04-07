local M = {}

function M.setup()
	require("illuminate").configure({
			-- Providers: priority order for getting references
			providers = {
				"lsp", -- Use LSP for semantic highlighting (best)
				"treesitter", -- Fallback to treesitter
				"regex", -- Last resort fallback
			},
			-- Delay in milliseconds before highlighting (100ms = responsive but not distracting)
			delay = 100,
			-- Filetypes to enable illuminate on
			filetypes_denylist = {
				"dirbuf",
				"dirvish",
				"fugitive",
				"alpha",
				"neo-tree",
				"NvimTree",
				"Trouble",
				"lazy",
				"mason",
				"notify",
				"toggleterm",
				"qf", -- quickfix
				"help",
				"man",
				"markdown", -- Disable for markdown (too noisy)
				"text",
				"TelescopePrompt",
			},
			-- Don't highlight in very large files (performance)
			large_file_cutoff = 2000,
			-- Increase performance by only highlighting visible lines
			large_file_overrides = {
				providers = { "lsp" }, -- Only use LSP for large files
			},
			-- Minimum number of matches required to highlight (avoid highlighting common words)
			min_count_to_highlight = 2,
	})

	vim.api.nvim_set_hl(0, "IlluminatedWordText", { underline = true })
	vim.api.nvim_set_hl(0, "IlluminatedWordRead", { underline = true })
	vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { underline = true, bold = true })

	vim.keymap.set("n", "]r", function()
		require("illuminate").goto_next_reference()
	end, { desc = "Next reference" })

	vim.keymap.set("n", "[r", function()
		require("illuminate").goto_prev_reference()
	end, { desc = "Previous reference" })

	vim.api.nvim_create_user_command("IlluminateToggle", function()
		require("illuminate").toggle()
	end, { desc = "Toggle illuminate highlighting" })
end

return M
