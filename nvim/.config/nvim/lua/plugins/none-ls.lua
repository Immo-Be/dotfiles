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
			-- Remove the restrictive env variable to allow global prettier as fallback
			-- env = { PRETTIERD_LOCAL_PRETTIER_ONLY = "1" },
		})

		null_ls.setup({
			sources = {
				-- Lua formatting
				null_ls.builtins.formatting.stylua,
				
				-- JavaScript/TypeScript formatting
				prettierd,
				
				-- ESLint for JavaScript/TypeScript linting and some fixing
				-- Use the correct none-ls-extras imports
				require("none-ls.diagnostics.eslint_d").with({
					condition = function(utils)
						return utils.root_has_file({
							".eslintrc", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.yaml", 
							".eslintrc.yml", ".eslintrc.json", "eslint.config.js"
						})
					end,
				}),
				require("none-ls.code_actions.eslint_d").with({
					condition = function(utils)
						return utils.root_has_file({
							".eslintrc", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.yaml", 
							".eslintrc.yml", ".eslintrc.json", "eslint.config.js"
						})
					end,
				}),
				
				-- Additional Node.js related formatters
				null_ls.builtins.formatting.biome.with({
					condition = function(utils)
						-- Only use biome if biome.json exists in the project
						return utils.root_has_file("biome.json")
					end,
				}),
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
