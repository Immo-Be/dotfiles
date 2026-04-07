local M = {}

function M.setup()
	local telescope = require("telescope")
	local builtin = require("telescope.builtin")
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

	local open_in_left_split = function(prompt_bufnr)
		local entry = action_state.get_selected_entry()
		actions.close(prompt_bufnr)
		vim.cmd("rightbelow vsplit")
		if entry.path or entry.filename then
			vim.cmd("edit " .. (entry.path or entry.filename))
		elseif entry.bufnr then
			vim.cmd("buffer " .. entry.bufnr)
		end
	end

	local open_in_horizontal_split = function(prompt_bufnr)
		local entry = action_state.get_selected_entry()
		actions.close(prompt_bufnr)
		vim.cmd("rightbelow split")
		if entry.path or entry.filename then
			vim.cmd("edit " .. (entry.path or entry.filename))
		elseif entry.bufnr then
			vim.cmd("buffer " .. entry.bufnr)
		end
	end

	local open_in_vsplit_current = function(prompt_bufnr)
		local entry = action_state.get_selected_entry()
		actions.close(prompt_bufnr)
		vim.cmd("vsplit")
		if entry.path or entry.filename then
			vim.cmd("edit " .. (entry.path or entry.filename))
		elseif entry.bufnr then
			vim.cmd("buffer " .. entry.bufnr)
		end
	end

	telescope.setup({
		defaults = {
			history = {
				path = "~/.local/share/nvim/databases/telescope_history.sqlite3",
				limit = 100,
			},
			file_ignore_patterns = {},
			no_ignore = true,
			mappings = {
				i = {
					["<C-q>"] = smart_send_to_qflist,
					["<Up>"] = actions.cycle_history_prev,
					["<Down>"] = actions.cycle_history_next,
				},
				n = {
					["<C-q>"] = smart_send_to_qflist,
					["l"] = open_in_left_split,
					["h"] = open_in_horizontal_split,
					["v"] = open_in_vsplit_current,
				},
			},
		},
		pickers = {
			find_files = {
				find_command = { "rg", "--files", "--hidden", "--glob", "!.git/*" },
				hidden = true,
			},
		},
		extensions = {
			["ui-select"] = {
				require("telescope.themes").get_dropdown({}),
			},
		},
	})

	telescope.load_extension("ui-select")

	vim.keymap.set("n", "<leader>f", builtin.find_files, { desc = "Find Files" })
	vim.keymap.set("n", "<leader>b", builtin.buffers, { desc = "Buffers" })
	vim.keymap.set("n", "<leader>h", builtin.help_tags, { desc = "Help Tags" })

	require("config.telescope.multigrep").setup()

	vim.keymap.set("n", "<leader>n", function()
		builtin.live_grep({
			search_dirs = { "node_modules" },
			prompt_title = "Live Grep in node_modules",
		})
	end, { desc = "Live Grep in node_modules" })
end

return M
