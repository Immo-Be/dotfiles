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

		-- Astro
		vim.lsp.config("astro", {
			capabilities = capabilities,
			on_attach = on_attach,
			filetypes = { "astro" },
		})

		-- ✅ TypeScript/JavaScript via vtsls (great TSX/JSX support)
		vim.lsp.config("vtsls", {
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
		vim.lsp.config("html", { capabilities = capabilities })
		vim.lsp.config("cssls", { capabilities = capabilities })
		vim.lsp.config("jsonls", { capabilities = capabilities })

		-- Custom go-to-definition to jump if there is only one result
		local function smart_definition()
			local params = vim.lsp.util.make_position_params()
			vim.lsp.buf_request(0, "textDocument/definition", params, function(err, result, ctx, config)
				if err or not result or vim.tbl_isempty(result) then
					vim.notify("No definition found", vim.log.levels.WARN)
					return
				end

				local client = vim.lsp.get_client_by_id(ctx.client_id)
				local position_encoding = (client and client.offset_encoding) or "utf-16"

				if vim.islist(result) and #result > 1 then
					vim.fn.setqflist({}, " ", { title = "LSP Definitions", items = vim.lsp.util.locations_to_items(result, position_encoding) })
					vim.cmd("copen")
				else
					local location = vim.islist(result) and result[1] or result
					vim.lsp.util.jump_to_location(location, position_encoding)
				end
			end)
		end

		-- Telescope + LSP keymaps
		local telescope_builtin = require("telescope.builtin")
		vim.keymap.set(
			"n",
			"gr",
			telescope_builtin.lsp_references,
			{ noremap = true, silent = true, desc = "Telescope LSP References" }
		)
		vim.keymap.set("n", "<C-e>", vim.lsp.buf.hover, {})
		vim.keymap.set("n", "gd", smart_definition, { noremap = true, silent = true, desc = "Go to definition" })
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
