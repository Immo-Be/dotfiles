local M = {}

function M.setup()
	local oil = require("oil")

	oil.setup({
		keymaps = {
			Y = function()
				local entry = oil.get_cursor_entry()
				if not entry then
					return
				end

				local path = entry.path
				if not path then
					local dir = oil.get_current_dir(0) or vim.fn.getcwd()
					path = vim.fs.normalize(vim.fs.joinpath(dir, entry.name))
				end

				vim.fn.setreg("+", path)
				vim.fn.setreg("*", path)
				vim.notify("Copied path: " .. path)
			end,
		},
	})
	vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
end

return M
