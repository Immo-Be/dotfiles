local M = {}

function M.setup()
	require("neo-tree").setup({
		filesystem = {
			follow_current_file = { enabled = true },
			hijack_netrw = true,
			use_libuv_file_watcher = true,
			filtered_items = {
				visible = true,
				hide_dotfiles = false,
				hide_gitignored = false,
			},
		},
	})

	vim.keymap.set("n", "<C-b>", ":Neotree toggle right<CR>", { desc = "Toggle Neo-tree" })
	vim.keymap.set("n", "<C-\\>", ":Neotree reveal right<CR>", { desc = "Reveal in Neo-tree" })
	vim.keymap.set("n", "<C-S-e>", ":Neotree focus<CR>", { desc = "Focus Neo-tree" })
	vim.keymap.set("n", "<C-S-b>", ":Neotree close<CR>", { desc = "Close Neo-tree" })

	vim.api.nvim_create_user_command("E", function()
		vim.cmd("Neotree current")
	end, { desc = "Open Neo-tree in current buffer" })
end

return M
