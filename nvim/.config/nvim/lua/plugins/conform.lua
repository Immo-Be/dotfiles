local M = {}

function M.setup()
	local conform = require("conform")

	conform.setup({
		formatters_by_ft = {
			sh = { "shfmt" },
			bash = { "shfmt" },
		},
		formatters = {
			shfmt = {
				prepend_args = { "-i", "2" }, -- 2 space indentation
			},
		},
	})

	vim.api.nvim_create_user_command("ConformFormat", function()
		conform.format({ timeout_ms = 3000, lsp_fallback = false })
	end, { desc = "Format with conform.nvim" })

	vim.keymap.set("n", "<leader><leader>fs", function()
		conform.format({ timeout_ms = 3000 })
	end, { desc = "Format with conform (shell/markdown)" })
end

return M
