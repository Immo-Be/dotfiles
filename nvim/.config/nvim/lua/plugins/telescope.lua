return {
	{
		"nvim-telescope/telescope.nvim",
		desc = "Fuzzy finder over lists",
		branch = "0.1.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-ui-select.nvim",
		},
		config = function()
			local telescope = require("telescope")
			local builtin = require("telescope.builtin")

			-- Opens marked items in a quickfix list.
			-- if there are no marked items, it opens all items in a quickfix list.
			local actions = require("telescope.actions")
			local action_state = require("telescope.actions.state")

			local smart_send_to_qflist = function(prompt_bufnr)
				local picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)

				local multi = picker:get_multi_selection()
				if not vim.tbl_isempty(multi) then
					actions.send_selected_to_qflist(prompt_bufnr)
				else
					actions.send_to_qflist(prompt_bufnr)
				end
				actions.open_qflist(prompt_bufnr)
			end

			-- Custom action: Open file in new vertical split to the far left
			local open_in_left_split = function(prompt_bufnr)
				local entry = action_state.get_selected_entry()
				actions.close(prompt_bufnr)
				
				-- Create a vertical split to the far left
				vim.cmd("leftabove vsplit")
				
				-- Open the selected file
				if entry.path or entry.filename then
					vim.cmd("edit " .. (entry.path or entry.filename))
				elseif entry.bufnr then
					vim.cmd("buffer " .. entry.bufnr)
				end
			end

			-- Setup Telescope with UI-Select extension
			telescope.setup({
				defaults = {
					-- we are storing results in sqlite3 database. Please also remove sqlite.lua if this is not needed
					history = {
						path = "~/.local/share/nvim/databases/telescope_history.sqlite3",
						limit = 100,
					},
					file_ignore_patterns = {}, -- Optional: Ignore .git folder
					no_ignore = true, -- ✅ Show gitignored files
					mappings = {
						i = {
							["<C-q>"] = smart_send_to_qflist,
							["l"] = open_in_left_split,
						},
						n = {
							["<C-q>"] = smart_send_to_qflist,
							["l"] = open_in_left_split,
						},
					},
				},
				pickers = {
					find_files = {
						-- add "--no-ignore" to show all files, except .git folder
						find_command = { "rg", "--files", "--hidden", "--glob", "!.git/*" },
						hidden = true, -- ✅ Show hidden files excluding .git
					},
				},
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
				},
			})

			-- Load the ui-select extension
			telescope.load_extension("ui-select")

			-- Keybindings
			vim.keymap.set("n", "<leader>f", builtin.find_files, { desc = "Find Files" })
			vim.keymap.set("n", "<leader>b", builtin.buffers, { desc = "Buffers" })
			vim.keymap.set("n", "<leader>h", builtin.help_tags, { desc = "Help Tags" })

      -- I deactivated find_files in favour of this custom multigrep function
      -- here i can type double + file extensions to optionally search only specific files
			-- custom function
			-- vim.keymap.set("n", "<leader>g", builtin.live_grep, { desc = "Live Grep" })
			-- Custom keymap to search only in node_modules
			require("config.telescope.multigrep").setup()

			vim.keymap.set("n", "<leader>n", function()
				builtin.live_grep({
					search_dirs = { "node_modules" },
					prompt_title = "Live Grep in node_modules",
				})
			end, { desc = "Live Grep in node_modules" })


			-- ✅ Use Telescope for LSP Code Actions
		end,
	},
}
