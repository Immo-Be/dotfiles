return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		cmd = "Neotree",
		keys = {
			{ "<C-b>", ":Neotree toggle right<CR>", desc = "Toggle Neo-tree" },
			{ "<C-\\>", ":Neotree reveal right<CR>", desc = "Reveal in Neo-tree" },
			{ "<C-S-e>", ":Neotree focus<CR>", desc = "Focus Neo-tree" },
			{ "<C-S-b>", ":Neotree close<CR>", desc = "Close Neo-tree" },
		},
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

			-- Create :E command to open neo-tree in current buffer
			vim.api.nvim_create_user_command("E", function()
				vim.cmd("Neotree current")
			end, { desc = "Open Neo-tree in current buffer" })
		end,
	},
}
