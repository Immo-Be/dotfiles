local M = {}

local opts = {
	-- Disable by default - use :WhichKey to show bindings manually
	delay = 999999, -- Effectively disable automatic popup
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
}

function M.setup()
	local wk = require("which-key")
	wk.setup(opts)

	wk.add({
		-- Leader key groups
		{ "<leader>b", group = "Buffer" },
		{ "<leader>c", group = "Code/Console" },
		{ "<leader>d", group = "Diagnostics/Diff" },
		{ "<leader>e", desc = "Open file explorer" },
		{ "<leader>E", desc = "Open explorer at cwd" },
		{ "<leader>f", group = "Find" },
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

	local auto_enabled = false
	vim.api.nvim_create_user_command("WhichKeyToggle", function()
		auto_enabled = not auto_enabled
		if auto_enabled then
			wk.setup({ delay = 500 })
			vim.notify("Which-key auto-popup enabled", vim.log.levels.INFO)
		else
			wk.setup({ delay = 999999 })
			vim.notify("Which-key auto-popup disabled", vim.log.levels.INFO)
		end
	end, { desc = "Toggle which-key automatic popup" })
end

return M
