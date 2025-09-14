-- lua/plugins/none-ls.lua (example path)
return {
	"nvimtools/none-ls.nvim",
	dependencies = { "nvimtools/none-ls-extras.nvim" },
	config = function()
		local null_ls = require("null-ls")

		-- Make prettierd prefer the project's local prettier + plugins
		local prettierd = null_ls.builtins.formatting.prettierd.with({
			-- Use the project's node_modules if present
			prefer_local = "node_modules/.bin",
			-- Limit/extend the filetypes none-ls will offer prettierd for
			filetypes = {
				"html",
				"gotmpl",
				"gohtml",
				"tmpl",
				"markdown",
				"css",
				"scss",
				"json",
				"javascript",
				"typescript",
				"yaml",
			},
			-- Ensure prettierd loads local plugins only (like prettier-plugin-go-template)
			env = { PRETTIERD_LOCAL_PRETTIER_ONLY = "1" },
		})

		null_ls.setup({
			sources = {
				null_ls.builtins.formatting.stylua,
				prettierd,
			},
			-- Optional: tighter root detection so prettierd runs from project root
			root_dir = require("null-ls.utils").root_pattern(
				".git",
				"package.json",
				".prettierrc",
				".prettierrc.json",
				".prettierrc.js",
				"prettier.config.js"
			),
		})

		-- Manual format with none-ls only
		vim.keymap.set("n", "<leader><leader>f", function()
			vim.lsp.buf.format({
				filter = function(client)
					return client.name == "null-ls"
				end,
				timeout_ms = 3000,
			})
		end, { desc = "Format with null-ls" })

		-- Format on save for relevant Hugo/templating and web files
		-- local fmt_group = vim.api.nvim_create_augroup("FormatOnSaveNoneLS", { clear = true })
		-- vim.api.nvim_create_autocmd("BufWritePre", {
		-- 	group = fmt_group,
		-- 	pattern = {
		-- 		"*.html",
		-- 		"*.gohtml",
		-- 		"*.gotmpl",
		-- 		"*.tmpl",
		-- 		"*.md",
		-- 		"*.css",
		-- 		"*.scss",
		-- 		"*.json",
		-- 		"*.yml",
		-- 		"*.yaml",
		-- 		"*.js",
		-- 		"*.ts",
		-- 		"*.lua",
		-- 	},
		-- 	callback = function()
		-- 		vim.lsp.buf.format({
		-- 			filter = function(client)
		-- 				return client.name == "null-ls"
		-- 			end,
		-- 			timeout_ms = 3000,
		-- 		})
		-- 	end,
		-- })
	end,
}
