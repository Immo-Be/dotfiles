return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	config = function()
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

		-- Add conform formatting to the existing format command
		-- This integrates with your <leader><leader>f keybinding
		vim.api.nvim_create_user_command("ConformFormat", function()
			conform.format({ timeout_ms = 3000, lsp_fallback = false })
		end, { desc = "Format with conform.nvim" })

		-- Optional: Add a specific keybinding for shell/markdown formatting
		vim.keymap.set("n", "<leader><leader>fs", function()
			conform.format({ timeout_ms = 3000 })
		end, { desc = "Format with conform (shell/markdown)" })
	end,
}
