local M = {}

function M.setup()
	require("mason-tool-installer").setup({
		ensure_installed = {
			-- Formatters (used by none-ls and conform.nvim)
			"stylua", -- Lua formatter (none-ls)
			"prettierd", -- Fast prettier (none-ls)
			"shfmt", -- Shell script formatter (conform.nvim)
			"biome", -- JS/TS formatter alternative (none-ls)

			-- Linters (used by none-ls-extras and nvim-lint)
			"eslint_d", -- Fast ESLint (none-ls-extras)
			"shellcheck", -- Shell script linter (nvim-lint)
			"markdownlint", -- Markdown linter (nvim-lint)
			"yamllint", -- YAML linter (none-ls-extras)
		},
		auto_update = false,
		run_on_start = true,
	})
end

return M
