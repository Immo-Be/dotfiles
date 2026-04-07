local M = {}

function M.setup()
	require("git-conflict").setup()

	require("diffview").setup({
				view = {
					merge_tool = {
						layout = "diff1_plain",
					},
				},
})

	vim.keymap.set("n", "<leader>dh", ":DiffviewFileHistory %<CR>", { desc = "File History (current file)" })
	vim.keymap.set("v", "<leader>dh", function()
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
			vim.keymap.set("n", "<leader>hs", ":Gitsigns stage_hunk<CR>", opts)
			vim.keymap.set("n", "<leader>hu", ":Gitsigns undo_stage_hunk<CR>", opts)
		end,
	})

	require("neogit").setup({
		integrations = { diffview = true },
		disable_commit_confirmation = false,
		commit_popup = { kind = "split" },
	})

	vim.api.nvim_create_user_command("AICommit", function()
		require("utils.git").generate_ai_commit_message(function(message)
			vim.cmd("Neogit commit")
			vim.defer_fn(function()
				vim.api.nvim_put({ message }, "l", true, true)
			end, 200)
		end)
	end, { desc = "Generate AI commit message with Avante" })

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
					map("n", "<leader>hP", gitsigns.preview_hunk) -- Changed from hp to hP (git push uses hp)
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
end

return M
