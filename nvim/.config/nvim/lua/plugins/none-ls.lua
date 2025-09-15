return {
	"nvimtools/none-ls.nvim",
	dependencies = { "nvimtools/none-ls-extras.nvim" },
	config = function()
		local null_ls = require("null-ls")

		-- Make prettierd prefer the project's local prettier + plugins
		local prettierd = null_ls.builtins.formatting.prettierd.with({
			prefer_local = "node_modules/.bin",
			filetypes = {
				-- markup / templates
				"html",
				"gotmpl",
				"gohtml",
				"tmpl",
				"markdown",
				"markdown.mdx",
				"yaml",
				-- css
				"css",
				"scss",
				-- json
				"json",
				-- js/ts + react
				"javascript",
				"javascriptreact",
				"javascript.jsx",
				"typescript",
				"typescriptreact",
				"typescript.tsx",
				-- astro (Prettier supports it via plugin if present)
				"astro",
			},
			env = { PRETTIERD_LOCAL_PRETTIER_ONLY = "1" },
		})

		null_ls.setup({
			sources = {
				null_ls.builtins.formatting.stylua,
				prettierd,
			},
			-- Keep your root detection; Prettier will pick up local config/plugins
			root_dir = require("null-ls.utils").root_pattern(
				".git",
				"package.json",
				".prettierrc",
				".prettierrc.json",
				".prettierrc.js",
				"prettier.config.js",
				"prettier.config.cjs",
				"prettier.config.mjs",
				"prettier.config.ts"
			),
		})

		-- Manual format with none-ls only (unchanged)
		vim.keymap.set("n", "<leader><leader>f", function()
			vim.lsp.buf.format({
				filter = function(client)
					return client.name == "null-ls"
				end,
				timeout_ms = 3000,
			})
		end, { desc = "Format with null-ls" })

		-- If you re-enable format-on-save later, include TSX/JSX/etc. in the pattern list.
		-- local fmt_group = vim.api.nvim_create_augroup("FormatOnSaveNoneLS", { clear = true })
		-- vim.api.nvim_create_autocmd("BufWritePre", {
		--   group = fmt_group,
		--   pattern = {
		--     "*.html","*.gohtml","*.gotmpl","*.tmpl","*.md","*.mdx","*.css","*.scss",
		--     "*.json","*.yml","*.yaml","*.js","*.jsx","*.ts","*.tsx","*.astro","*.lua",
		--   },
		--   callback = function()
		--     vim.lsp.buf.format({
		--       filter = function(client) return client.name == "null-ls" end,
		--       timeout_ms = 3000,
		--     })
		--   end,
		-- })
	end,
}
