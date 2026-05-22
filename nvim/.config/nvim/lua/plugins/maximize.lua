local M = {}

function M.setup()
	require("maximize").setup()

	vim.keymap.set("n", "<leader>z", function()
		require("maximize").toggle()
	end, { desc = "Toggle maximize", silent = true })
end

return M
