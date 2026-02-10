return {
	"christoomey/vim-tmux-navigator",
	lazy = false, -- Ensure it's always loaded
	keys = {
		{ "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Move left" },
		{ "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Move down" },
		{ "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Move up" },
		{ "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Move right" },
		{ "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Move to last" },
	},
	config = function()
		-- Disable tmux navigator in OpenCode floating windows
		vim.g.tmux_navigator_no_mappings = 0
		vim.g.tmux_navigator_disable_when_zoomed = 1

		-- Add autocmd to disable tmux navigation in OpenCode windows
		vim.api.nvim_create_autocmd({ "FileType", "WinEnter" }, {
			pattern = "*",
			callback = function()
				local ft = vim.bo.filetype
				-- Check if this is an OpenCode window (adjust pattern as needed)
				if ft == "opencode" or vim.fn.win_gettype() == "popup" then
					-- In OpenCode windows, use normal Ctrl-hjkl for window navigation
					vim.keymap.set("n", "<C-h>", "<C-w>h", { buffer = true, silent = true })
					vim.keymap.set("n", "<C-j>", "<C-w>j", { buffer = true, silent = true })
					vim.keymap.set("n", "<C-k>", "<C-w>k", { buffer = true, silent = true })
					vim.keymap.set("n", "<C-l>", "<C-w>l", { buffer = true, silent = true })
				end
			end,
		})
	end,
}

