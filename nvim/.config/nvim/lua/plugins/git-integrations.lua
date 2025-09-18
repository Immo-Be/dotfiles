return {
	{ "akinsho/git-conflict.nvim", version = "*", config = true },
	{
		"sindrets/diffview.nvim",
		config = function()
			require("diffview").setup({
				view = {
					merge_tool = {
						layout = "diff1_plain", -- 👈 this sets the single window view
					},
				},
			})
			-- Add key mappings for diffview file history

			-- You can jump between conflict markers with `]x` and `[x`. This works
			-- from the file panel as well. Further, in addition to the normal
			-- |copy-diffs| mappings you can use `2do` to obtain the hunk from the
			-- OURS side of the diff, `3do` to obtain the hunk from the THEIRS side
			-- of the diff, and - in a 4-way diff - `1do` to obtain the hunk from the
			-- BASE. See |diffview-conflict-versions| to tell what windows correspond
			-- with what version of the file.
			--
			-- Additionally there are mappings for operating directly on the conflict
			-- markers:
			--   • `<leader>co`: Choose the OURS version of the conflict.
			--   • `<leader>ct`: Choose the THEIRS version of the conflict.
			--   • `<leader>cb`: Choose the BASE version of the conflict.
			--   • `<leader>ca`: Choose all versions of the conflict (effectively
			--     just deletes the markers, leaving all the content).
			--   • `dx`: Choose none of the versions of the conflict (delete the
			--     conflict region).
			--
			-- For more info on these actions, see
			-- |diffview-actions-conflict_choose|.
			--

			-- NOTE: The horizontal 3-way diff is only the default layout for the
			-- merge-tool, but there are multiple variations on the 3-way diff layout
			-- as well as a 4-way diff, and a single window layout available. The
			-- default mapping `g<C-x>` allows you to cycle through the available
			-- layouts. To configure a different default layout, see
			-- |diffview-config-view.x.layout|.
			--
			vim.keymap.set("n", "<leader>dh", ":DiffviewFileHistory %<CR>", { desc = "File History (current file)" })

			vim.keymap.set("v", "<leader>dh", function()
				-- Get the current visual selection and pass it to DiffviewFileHistory
				local start_line = vim.fn.line("'<")
				local end_line = vim.fn.line("'>")
				if start_line > 0 and end_line > 0 then
					vim.cmd(string.format("%d,%dDiffviewFileHistory", start_line, end_line))
				else
					vim.notify("Visual selection required", vim.log.levels.ERROR)
				end
			end, { desc = "File History (selection)" })
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "DiffviewFilePanel",
				callback = function()
					local opts = { buffer = true, silent = true }
					vim.keymap.set("n", "<leader>hs", ":Gitsigns stage_hunk<CR>", opts) -- Stage hunk
					vim.keymap.set("n", "<leader>hu", ":Gitsigns undo_stage_hunk<CR>", opts) -- Unstage hunk
				end,
			})
		end,
	},
	{
		"NeogitOrg/neogit",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"sindrets/diffview.nvim",
			"nvim-telescope/telescope.nvim",
		},
		config = function()
			require("neogit").setup({
				integrations = { diffview = true },
				disable_commit_confirmation = false,
				commit_popup = { kind = "split" },
			})
		end,
	},
	{
		"lewis6991/gitsigns.nvim",
		dependencies = "nvim-lua/plenary.nvim",
		config = function()
			require("gitsigns").setup({
				current_line_blame = true,
				on_attach = function(bufnr)
					local gitsigns = require("gitsigns")

					local function map(mode, l, r, opts)
						opts = opts or {}
						opts.buffer = bufnr
						vim.keymap.set(mode, l, r, opts)
					end

					-- Navigation
					map("n", "]c", function()
						if vim.wo.diff then
							vim.cmd.normal({ "]c", bang = true })
						else
							gitsigns.nav_hunk("next")
						end
					end)

					map("n", "[c", function()
						if vim.wo.diff then
							vim.cmd.normal({ "[c", bang = true })
						else
							gitsigns.nav_hunk("prev")
						end
					end)

					-- Actions
					map("n", "<leader>hs", gitsigns.stage_hunk)
					map("n", "<leader>hr", gitsigns.reset_hunk)

					map("v", "<leader>hs", function()
						gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
					end)

					map("v", "<leader>hr", function()
						gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
					end)

					map("n", "<leader>hS", gitsigns.stage_buffer)
					map("n", "<leader>hR", gitsigns.reset_buffer)
					map("n", "<leader>hp", gitsigns.preview_hunk)
					map("n", "<leader>hi", gitsigns.preview_hunk_inline)

					map("n", "<leader>hb", function()
						gitsigns.blame_line({ full = true })
					end)

					map("n", "<leader>hd", gitsigns.diffthis)

					map("n", "<leader>hD", function()
						gitsigns.diffthis("~")
					end)

					map("n", "<leader>hQ", function()
						gitsigns.setqflist("all")
					end)
					map("n", "<leader>hq", gitsigns.setqflist)

					-- Toggles
					map("n", "<leader>tb", gitsigns.toggle_current_line_blame)
					map("n", "<leader>td", gitsigns.toggle_deleted)
					map("n", "<leader>tw", gitsigns.toggle_word_diff)

					-- Text object
					map({ "o", "x" }, "ih", gitsigns.select_hunk)
				end,
			})
		end,
	},
}
