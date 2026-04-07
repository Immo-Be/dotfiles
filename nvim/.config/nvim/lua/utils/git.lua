local M = {}

-- Generate AI commit message using Avante
function M.generate_ai_commit_message(callback)
	local diff = vim.fn.system("git diff --cached")

	if diff == "" then
		vim.notify("No staged changes to commit.", vim.log.levels.WARN)
		return
	end

	local prompt = "Generate a concise, conventional commit message for the following git diff:\n" .. diff
	vim.notify("Generating AI commit message...", vim.log.levels.INFO)

	require("avante.api").ask({
		prompt = prompt,
		provider = "copilot",
		on_finish = function(response)
			if not response or response == "" then
				vim.notify("AI did not return a commit message.", vim.log.levels.ERROR)
				return
			end

			-- Clean quotes from the response
			local message = response:gsub('^"', ""):gsub('"$', "")

			if callback then
				callback(message)
			end
		end,
	})
end

-- Commit with AI-generated message
function M.commit_with_ai()
	M.generate_ai_commit_message(function(message)
		vim.fn.jobstart({ "git", "commit", "-m", message }, {
			on_exit = function(_, exit_code)
				if exit_code == 0 then
					vim.notify("Commit successful: " .. message, vim.log.levels.INFO)
					require("gitsigns").refresh()
				else
					vim.notify("Commit failed", vim.log.levels.ERROR)
				end
			end,
		})
	end)
end

-- Push with confirmation dialog
function M.push_with_confirmation()
	-- Step 1: Check if in a git repository
	local in_git = vim.fn.system("git rev-parse --is-inside-work-tree 2>/dev/null"):match("true")
	if not in_git then
		vim.notify("Not in a git repository", vim.log.levels.ERROR)
		return
	end

	-- Step 2: Get current branch name
	local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null"):gsub("%s+", "")
	if branch == "HEAD" then
		vim.notify("Cannot push from detached HEAD state", vim.log.levels.ERROR)
		return
	end

	-- Step 3: Get upstream branch
	local upstream = vim.fn.system("git rev-parse --abbrev-ref @{upstream} 2>/dev/null"):gsub("%s+", "")
	if upstream == "" or upstream:match("fatal:") or upstream:match("error:") then
		vim.notify(
			string.format(
				"Branch '%s' has no upstream branch. Use 'git push -u origin %s' to set upstream.",
				branch,
				branch
			),
			vim.log.levels.ERROR
		)
		return
	end

	-- Step 4: Count unpushed commits
	local commit_count =
		vim.fn.system(string.format("git rev-list --count %s..HEAD 2>/dev/null", upstream)):gsub("%s+", "")

	-- Check if already up to date
	if commit_count == "0" then
		vim.notify(string.format("Already up to date with %s", upstream), vim.log.levels.INFO)
		return
	end

	-- Step 5: Build confirmation message
	local commit_word = commit_count == "1" and "commit" or "commits"
	local message = string.format(
		"Ready to push:\n\nBranch:  %s\nRemote:  %s\nCommits: %s unpushed %s",
		branch,
		upstream,
		commit_count,
		commit_word
	)

	-- Step 6: Show confirmation dialog
	vim.ui.select({ "Push to remote", "Cancel" }, {
		prompt = message,
		format_item = function(item)
			return item
		end,
	}, function(choice)
		if not choice or choice == "Cancel" then
			vim.notify("Push cancelled", vim.log.levels.WARN)
			return
		end

		-- Step 7: Execute git push
		vim.notify("Pushing to " .. upstream .. "...", vim.log.levels.INFO)
		vim.fn.jobstart("git push", {
			on_exit = function(_, exit_code)
				if exit_code == 0 then
					vim.notify(
						string.format("Successfully pushed %s %s to %s", commit_count, commit_word, upstream),
						vim.log.levels.INFO
					)
					-- Step 8: Refresh gitsigns
					require("gitsigns").refresh()
				else
					vim.notify("Push failed. Check :messages for details", vim.log.levels.ERROR)
				end
			end,
			on_stderr = function(_, data)
				if data and #data > 0 then
					for _, line in ipairs(data) do
						if line and line ~= "" then
							vim.notify("Git: " .. line, vim.log.levels.WARN)
						end
					end
				end
			end,
		})
	end)
end

return M
