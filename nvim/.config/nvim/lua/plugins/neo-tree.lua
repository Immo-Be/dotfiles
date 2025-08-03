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
					window = {
						mappings = {
							["yy"] = "copy_path_to_clipboard", -- default
						},
					},
					commands = {
						copy_path_to_clipboard = function(state)
							local node = state.tree:get_node()
							local path = node:get_id()
							vim.fn.setreg("+", path) -- system clipboard
							print("Copied to clipboard: " .. path)
						end,
					},
					follow_current_file = { enabled = true }, -- ✅ Updated to the new format
					hijack_netrw = true,
					use_libuv_file_watcher = true,
					filtered_items = {
						visible = true, -- ✅ Show hidden files
						hide_dotfiles = false, -- ✅ Show dotfiles
						hide_gitignored = false, -- ✅ Show Git-ignored files
					},
				},
			})

			-- Keybindings
			vim.keymap.set("n", "<C-b>", ":Neotree toggle right<CR>", { noremap = true, silent = true }) -- Toggle File Explorer
			vim.keymap.set("n", "<C-\\>", ":Neotree reveal right<CR>", { noremap = true, silent = true }) -- Reveal current file
			vim.keymap.set("n", "<C-S-e>", ":Neotree focus<CR>", { noremap = true, silent = true }) -- Focus on Neo-tree
			vim.keymap.set("n", "<C-S-b>", ":Neotree close<CR>", { noremap = true, silent = true }) -- Close Neo-tree

			-- Copy file path to system clipboard
			vim.keymap.set(
				"n",
				"<leader>cp",
				':lua vim.fn.setreg("+", vim.fn.expand("%:p"))<CR>',
				{ noremap = true, silent = true }
			)

			-- Toggle hidden files manually
			vim.keymap.set("n", "<leader>th", ":Neotree toggle hidden<CR>", { noremap = true, silent = true })
		end,
	},
}
