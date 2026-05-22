local M = {}

function M.setup()
	local mini_files = require("mini.files")
	mini_files.setup({
		mappings = {
			close = "q",
			go_in = "",
			go_in_plus = "L",
			go_out = "h",
			go_out_plus = "H",
			reset = "<BS>",
			reveal_cwd = "@",
			show_help = "g?",
			synchronize = "=",
			trim_left = "<",
			trim_right = ">",
		},
	})

	vim.api.nvim_create_autocmd("User", {
		pattern = "MiniFilesBufferCreate",
		callback = function(args)
			local buf_id = args.data.buf_id
			local function open_entry(open_in_split)
				local fs_entry = mini_files.get_fs_entry()
				if not fs_entry then
					return
				end

				if fs_entry.fs_type == "file" then
					if open_in_split then
						local cur_target = mini_files.get_explorer_state().target_window
						local new_target = vim.api.nvim_win_call(cur_target, function()
							vim.cmd("belowright vertical split")
							return vim.api.nvim_get_current_win()
						end)

						mini_files.set_target_window(new_target)
						mini_files.go_in({ close_on_file = true })
					else
						mini_files.go_in({ close_on_file = true })
					end
				else
					mini_files.go_in()
				end
			end

			vim.keymap.set("n", "l", function()
				open_entry()
			end, { buffer = buf_id })
			vim.keymap.set("n", "s", function()
				open_entry(true)
			end, { buffer = buf_id, desc = "Open in vertical split" })
		end,
	})
end

return M
