local M = {}

function M.setup()
	vim.g.opencode_opts = {}
	vim.opt.autoread = true

	local opencode_group = vim.api.nvim_create_augroup("OpencodeReload", { clear = true })
	local reloaded_files = {}

	vim.api.nvim_create_autocmd("FileChangedShellPost", {
		group = opencode_group,
		callback = function(args)
			table.insert(reloaded_files, args.file)
		end,
	})

	vim.api.nvim_create_autocmd("User", {
		group = opencode_group,
		pattern = "OpencodeEvent:session.idle",
		callback = function()
			vim.tbl_clear(reloaded_files)
			vim.cmd("silent! checktime")
			if #reloaded_files > 0 then
				vim.notify(
					string.format("OpenCode finished. Refreshed %d changed buffer(s).", #reloaded_files),
					vim.log.levels.INFO
				)
			end
		end,
	})

	vim.keymap.set({ "n", "x" }, "<leader>oe", function()
		local explain = require("opencode.config").opts.prompts.explain
		require("opencode").prompt(explain.prompt, explain)
	end, { desc = "Explain this" })

	vim.keymap.set({ "n", "x" }, "<leader>oa", function()
		require("opencode").ask("@this: ", { submit = true })
	end, { desc = "Ask about this" })
	vim.keymap.set({ "n", "x" }, "<leader>os", function()
		require("opencode").select()
	end, { desc = "Select prompt" })
	vim.keymap.set({ "n", "x" }, "<leader>o+", function()
		require("opencode").prompt("@this")
	end, { desc = "Add this" })
	vim.keymap.set("n", "<leader>ot", function()
		require("opencode").toggle()
	end, { desc = "Toggle embedded" })
	vim.keymap.set("n", "<leader>oc", function()
		require("opencode").command()
	end, { desc = "Select command" })
	vim.keymap.set("n", "<leader>on", function()
		require("opencode").command("session_new")
	end, { desc = "New session" })
	vim.keymap.set("n", "<leader>oi", function()
		require("opencode").command("session_interrupt")
	end, { desc = "Interrupt session" })
	vim.keymap.set("n", "<leader>oA", function()
		require("opencode").command("agent_cycle")
	end, { desc = "Cycle selected agent" })
	vim.keymap.set("n", "<S-C-u>", function()
		require("opencode").command("messages_half_page_up")
	end, { desc = "Messages half page up" })
	vim.keymap.set("n", "<S-C-d>", function()
		require("opencode").command("messages_half_page_down")
	end, { desc = "Messages half page down" })
end

return M
