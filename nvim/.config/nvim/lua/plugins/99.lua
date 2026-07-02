local M = {}

function M.setup()
	local _99 = require("99")
	local cwd = vim.uv.cwd()
	local basename = cwd and vim.fs.basename(cwd) or "nvim"

	_99.setup({
		logger = {
			level = _99.DEBUG,
			path = "/tmp/" .. basename .. ".99.debug",
			print_on_error = true,
		},
		tmp_dir = "./tmp",
		completion = {
			source = "cmp",
			files = {},
		},
		md_files = {
			"AGENTS.md",
			"AGENT.md",
		},
	})

	vim.keymap.set("v", "<leader>9v", function()
		_99.visual()
	end, { desc = "99 rewrite selection" })

	vim.keymap.set("n", "<leader>9s", function()
		_99.search()
	end, { desc = "99 search project" })

	vim.keymap.set("n", "<leader>9o", function()
		_99.open()
	end, { desc = "99 open last result" })

	vim.keymap.set("n", "<leader>9l", function()
		_99.view_logs()
	end, { desc = "99 view logs" })

	vim.keymap.set("n", "<leader>9x", function()
		_99.stop_all_requests()
	end, { desc = "99 stop requests" })

	vim.keymap.set("n", "<leader>9c", function()
		_99.clear_previous_requests()
	end, { desc = "99 clear requests" })
end

return M
