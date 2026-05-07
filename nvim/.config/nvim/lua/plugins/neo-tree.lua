local M = {}

function M.setup()
	require("neo-tree").setup({
		commands = {
			open_in_finder = function(state)
				local node = state.tree:get_node()
				if not node then
					return
				end

				vim.fn.jobstart({ "open", "-R", node:get_id() }, { detach = true })
			end,
			copy_path = function(state)
				local node = state.tree:get_node()
				if not node then
					return
				end

				local path = node:get_id()
				vim.fn.setreg("+", path)
				vim.fn.setreg("*", path)
				vim.notify("Copied path: " .. path)
			end,
		},
		filesystem = {
			follow_current_file = { enabled = true },
			hijack_netrw = true,
			use_libuv_file_watcher = true,
			window = {
				mappings = {
					["O"] = "open_in_finder",
					["Y"] = "copy_path",
				},
			},
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
