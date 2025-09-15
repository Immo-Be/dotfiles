return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
	},
	config = function()
		-- Mason
		require("mason").setup()
		require("mason-lspconfig").setup({
			ensure_installed = {
				"lua_ls",
				"vtsls", -- ✅ replaces ts_ls/tsserver
				"html",
				"cssls",
				"jsonls",
				"astro",
			},
		})

		local capabilities = require("cmp_nvim_lsp").default_capabilities()

		-- Disable LSP formatting for TS-family servers (use null-ls/biome/prettierd etc.)
		local function on_attach(client, bufnr)
			local ts_names = { tsserver = true, ts_ls = true, vtsls = true }
			if ts_names[client.name] then
				client.server_capabilities.documentFormattingProvider = false
				client.server_capabilities.documentRangeFormattingProvider = false
			end
		end

		local lspconfig = require("lspconfig")

		-- Astro
		lspconfig.astro.setup({
			capabilities = capabilities,
			on_attach = on_attach,
			filetypes = { "astro" },
		})

		-- ✅ TypeScript/JavaScript via vtsls (great TSX/JSX support)
		lspconfig.vtsls.setup({
			capabilities = capabilities,
			on_attach = on_attach,
			-- Be explicit; helpful if filetype detection was customized.
			filetypes = {
				"typescript",
				"typescriptreact",
				"typescript.tsx",
				"javascript",
				"javascriptreact",
				"javascript.jsx",
			},
			-- optional niceties
			settings = {
				typescript = {
					inlayHints = {
						includeInlayParameterNameHints = "all",
						includeInlayVariableTypeHints = true,
						includeInlayFunctionLikeReturnTypeHints = true,
						includeInlayPropertyDeclarationTypeHints = true,
					},
				},
				javascript = {
					inlayHints = {
						includeInlayParameterNameHints = "all",
						includeInlayVariableTypeHints = true,
						includeInlayFunctionLikeReturnTypeHints = true,
						includeInlayPropertyDeclarationTypeHints = true,
					},
				},
			},
		})

		-- If you really want to stick with the old server, uncomment this block instead:
		-- lspconfig.ts_ls.setup({
		--   capabilities = capabilities,
		--   on_attach = on_attach,
		--   filetypes = {
		--     "typescript", "typescriptreact", "typescript.tsx",
		--     "javascript", "javascriptreact", "javascript.jsx",
		--   },
		-- })

		-- HTML, CSS, JSON
		lspconfig.html.setup({ capabilities = capabilities })
		lspconfig.cssls.setup({ capabilities = capabilities })
		lspconfig.jsonls.setup({ capabilities = capabilities })

		-- Telescope + LSP keymaps
		local telescope_builtin = require("telescope.builtin")
		vim.keymap.set(
			"n",
			"gr",
			telescope_builtin.lsp_references,
			{ noremap = true, silent = true, desc = "Telescope LSP References" }
		)
		vim.keymap.set("n", "<C-e>", vim.lsp.buf.hover, {})
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, {})
		vim.keymap.set("n", "gi", vim.lsp.buf.implementation, {})
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
		vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, {})
		vim.keymap.set("n", "<leader>s", vim.lsp.buf.signature_help, {})

		-- Lua LSP via new API (you can migrate others later if you like)
		vim.lsp.config("lua_ls", {
			settings = {
				Lua = {
					diagnostics = { globals = { "vim" } },
				},
			},
		})
	end,
}
