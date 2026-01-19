return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		config = function()
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

			-- Keybindings
			vim.keymap.set("n", "<C-b>", ":Neotree toggle right<CR>", { noremap = true, silent = true })
			vim.keymap.set("n", "<C-\\>", ":Neotree reveal right<CR>", { noremap = true, silent = true })
			vim.keymap.set("n", "<C-S-e>", ":Neotree focus<CR>", { noremap = true, silent = true })
			vim.keymap.set("n", "<C-S-b>", ":Neotree close<CR>", { noremap = true, silent = true })

			-- Create :E command to open neo-tree in current buffer
			vim.api.nvim_create_user_command("E", function()
				vim.cmd("Neotree current")
			end, { desc = "Open Neo-tree in current buffer" })
		end,
	},
}
