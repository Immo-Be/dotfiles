local M = {}

function M.init()
	vim.g.tmux_navigator_no_mappings = 1
	vim.g.tmux_navigator_disable_when_zoomed = 1
end

function M.setup()
	vim.keymap.set("n", "<C-h>", function()
		if vim.fn.win_gettype() == "popup" or vim.api.nvim_win_get_config(0).relative ~= "" then
			vim.cmd("wincmd h")
		else
			vim.cmd("TmuxNavigateLeft")
		end
	end, { desc = "Move left" })

	vim.keymap.set("n", "<C-j>", function()
		if vim.fn.win_gettype() == "popup" or vim.api.nvim_win_get_config(0).relative ~= "" then
			vim.cmd("wincmd j")
		else
			vim.cmd("TmuxNavigateDown")
		end
	end, { desc = "Move down" })

	vim.keymap.set("n", "<C-k>", function()
		if vim.fn.win_gettype() == "popup" or vim.api.nvim_win_get_config(0).relative ~= "" then
			vim.cmd("wincmd k")
		else
			vim.cmd("TmuxNavigateUp")
		end
	end, { desc = "Move up" })

	vim.keymap.set("n", "<C-l>", function()
		if vim.fn.win_gettype() == "popup" or vim.api.nvim_win_get_config(0).relative ~= "" then
			vim.cmd("wincmd l")
		else
			vim.cmd("TmuxNavigateRight")
		end
	end, { desc = "Move right" })

	vim.keymap.set("n", "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", { desc = "Move to last" })
end

return M
