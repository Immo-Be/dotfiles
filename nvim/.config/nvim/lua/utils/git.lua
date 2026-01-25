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

return M
