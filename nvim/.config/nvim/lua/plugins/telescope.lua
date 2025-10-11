return {
	{
		"nvim-telescope/telescope.nvim",
		-- "nvim-telescope/telescope-smart-history.nvim",
		branch = "0.1.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-ui-select.nvim", -- ✅ Add this line
			-- "nvim-telescope/telescope-smart-history.nvim",
		},
		config = function()
			local telescope = require("telescope")
			local builtin = require("telescope.builtin")

			-- Opens marked items in a quickfix list.
			-- if there are no marked items, it opens all items in a quickfix list.
			local actions = require("telescope.actions")

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
						i = { ["<C-q>"] = smart_send_to_qflist },
						n = { ["<C-q>"] = smart_send_to_qflist },
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
					-- ["smart_history"] = {
					-- 	require("nvim-telescope/telescope-smart-history.nvim"),
					-- },
				},
			})

			-- Load the ui-select extension
			telescope.load_extension("ui-select")
			-- -- Load the smart_history extension
			-- telescope.load_extension("smart_history")

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
