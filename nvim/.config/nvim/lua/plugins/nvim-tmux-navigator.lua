return {
	"christoomey/vim-tmux-navigator",
	lazy = false, -- Ensure it's always loaded
	init = function()
		-- Disable default mappings from the plugin
		vim.g.tmux_navigator_no_mappings = 1
		vim.g.tmux_navigator_disable_when_zoomed = 1
	end,
	keys = {
		{
			"<C-h>",
			function()
				-- Check if we're in a floating/popup window
				if vim.fn.win_gettype() == "popup" or vim.api.nvim_win_get_config(0).relative ~= "" then
					vim.cmd("wincmd h")
				else
					vim.cmd("TmuxNavigateLeft")
				end
			end,
			desc = "Move left",
		},
		{
			"<C-j>",
			function()
				if vim.fn.win_gettype() == "popup" or vim.api.nvim_win_get_config(0).relative ~= "" then
					vim.cmd("wincmd j")
				else
					vim.cmd("TmuxNavigateDown")
				end
			end,
			desc = "Move down",
		},
		{
			"<C-k>",
			function()
				if vim.fn.win_gettype() == "popup" or vim.api.nvim_win_get_config(0).relative ~= "" then
					vim.cmd("wincmd k")
				else
					vim.cmd("TmuxNavigateUp")
				end
			end,
			desc = "Move up",
		},
		{
			"<C-l>",
			function()
				if vim.fn.win_gettype() == "popup" or vim.api.nvim_win_get_config(0).relative ~= "" then
					vim.cmd("wincmd l")
				else
					vim.cmd("TmuxNavigateRight")
				end
			end,
			desc = "Move right",
		},
		{ "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Move to last" },
	},
}

