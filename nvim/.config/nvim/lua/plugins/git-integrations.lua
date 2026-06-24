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
			local function line_in_hunk(line, hunk)
				local start = hunk.added.start
				local finish = start + math.max(hunk.added.count, 1) - 1
				return line >= start and line <= finish
			end

			local function nearest_hunk_line(line, hunks)
				for _, hunk in ipairs(hunks) do
					if line_in_hunk(line, hunk) then
						return line
					end
				end

				for _, hunk in ipairs(hunks) do
					if hunk.added.start >= line then
						return hunk.added.start
					end
				end

				return hunks[1] and hunks[1].added.start
			end

			local function head_commit_count()
				local result = vim.fn.system({ "git", "rev-list", "--count", "HEAD" })
				if vim.v.shell_error ~= 0 then
					return 0
				end

				return tonumber(vim.trim(result)) or 0
			end

			local function preview_nearest_hunk_inline(hunks)
				local target_line = nearest_hunk_line(vim.api.nvim_win_get_cursor(0)[1], hunks)
				if not target_line then
					return false
				end

				local line_count = vim.api.nvim_buf_line_count(0)
				target_line = math.max(1, math.min(target_line, line_count))
				vim.api.nvim_win_set_cursor(0, { target_line, 0 })

				gitsigns.preview_hunk_inline(function()
					gitsigns.reset_base()
				end)

				return true
			end

			local function preview_previous_commit_hunk(depth, max_depth)
				if depth > max_depth then
					vim.notify("No changes for this file in previous commits", vim.log.levels.INFO)
					gitsigns.reset_base()
					return
				end

				local base = "HEAD~" .. depth
				gitsigns.change_base(base, false, function()
					local previous_hunks = gitsigns.get_hunks() or {}
					if #previous_hunks > 0 and preview_nearest_hunk_inline(previous_hunks) then
						return
					end

					preview_previous_commit_hunk(depth + 1, max_depth)
				end)
			end

			map("n", "<leader>hp", function()
				local hunks = gitsigns.get_hunks() or {}
				if #hunks > 0 then
					gitsigns.preview_hunk()
					return
				end

				local commit_count = head_commit_count()
				if commit_count < 2 then
					vim.notify("No previous commits to compare", vim.log.levels.INFO)
					return
				end

				preview_previous_commit_hunk(1, commit_count - 1)
			end, { desc = "Preview hunk or last commit inline" })
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
