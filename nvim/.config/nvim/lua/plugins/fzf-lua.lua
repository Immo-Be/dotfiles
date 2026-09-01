local M = {}

function M.setup()
	require("fzf-lua").setup({
		{ "telescope", "hide" },
		keymap = {
			fzf = {
				-- Add every result matching the current query to the quickfix list.
				["ctrl-q"] = "select-all+accept",
			},
		},
	})
end

return M
