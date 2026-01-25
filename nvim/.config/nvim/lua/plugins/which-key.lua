return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		-- your configuration comes here
		-- or leave it empty to use the default settings
		plugins = {
			marks = true, -- shows a list of your marks on ' and `
			registers = true, -- shows your registers on " in NORMAL or <C-r> in INSERT mode
			spelling = {
				enabled = true,
				suggestions = 20,
			},
			presets = {
				operators = true, -- adds help for operators like d, y, ...
				motions = true, -- adds help for motions
				text_objects = true, -- help for text objects triggered after entering an operator
				windows = true, -- default bindings on <c-w>
				nav = true, -- misc bindings to work with windows
				z = true, -- bindings for folds, spelling and others prefixed with z
				g = true, -- bindings for prefixed with g
			},
		},
		win = {
			border = "rounded",
		},
	},
	config = function(_, opts)
		local wk = require("which-key")
		wk.setup(opts)

		-- Register key groups for better organization
		wk.add({
			-- Leader key groups
			{ "<leader>b", group = "Buffer" },
			{ "<leader>c", group = "Code/Console" },
			{ "<leader>d", group = "Diagnostics/Diff" },
			{ "<leader>f", group = "Find/Files" },
			{ "<leader>h", group = "Git (Hunk)" },
			{ "<leader>s", group = "Swap/Signature" },
			{ "<leader>t", group = "Tab/Toggle" },
			{ "<leader>w", group = "Workspace" },
			{ "<leader><leader>", group = "Extra commands" },

			-- Bracket navigation groups
			{ "[", group = "Previous" },
			{ "]", group = "Next" },

			-- g prefix groups (covered by presets but we add custom ones)
			{ "g+", desc = "Increment numbers sequentially" },
			{ "g-", desc = "Decrement numbers sequentially" },
		})
	end,
}
