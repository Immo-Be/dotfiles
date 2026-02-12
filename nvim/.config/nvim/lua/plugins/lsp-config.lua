return {
	"neovim/nvim-lspconfig",
	desc = "Quickstart configs for Neovim LSP",
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
				"bashls", -- Add bashls for shell script support
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
		vim.lsp.enable("astro")

		-- Bash LSP
		vim.lsp.config("bashls", {
			capabilities = capabilities,
			on_attach = on_attach,
			filetypes = { "sh", "bash", "zsh" },
		})
		vim.lsp.enable("bashls")

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
		vim.lsp.enable("vtsls")

		-- Lua LSP
		vim.lsp.config("lua_ls", {
			capabilities = capabilities,
			on_attach = on_attach,
			settings = {
				Lua = {
					diagnostics = { globals = { "vim" } },
				},
			},
		})
		vim.lsp.enable("lua_ls")

		-- HTML, CSS, JSON
		vim.lsp.config("html", {
			capabilities = capabilities,
			on_attach = on_attach,
		})
		vim.lsp.enable("html")

		vim.lsp.config("cssls", {
			capabilities = capabilities,
			on_attach = on_attach,
		})
		vim.lsp.enable("cssls")

		vim.lsp.config("jsonls", {
			capabilities = capabilities,
			on_attach = on_attach,
		})
		vim.lsp.enable("jsonls")

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

		-- Go to definition in vertical split on the right
		local function definition_in_vsplit()
			local params = vim.lsp.util.make_position_params()
			vim.lsp.buf_request(0, "textDocument/definition", params, function(err, result, ctx, config)
				if err or not result or vim.tbl_isempty(result) then
					vim.notify("No definition found", vim.log.levels.WARN)
					return
				end

				local client = vim.lsp.get_client_by_id(ctx.client_id)
				local position_encoding = (client and client.offset_encoding) or "utf-16"

				if vim.islist(result) and #result > 1 then
					-- Multiple definitions - open quickfix list
					vim.cmd("rightbelow vsplit")
					vim.fn.setqflist({}, " ", { title = "LSP Definitions", items = vim.lsp.util.locations_to_items(result, position_encoding) })
					vim.cmd("copen")
				else
					-- Single definition - manually open file in new split
					local location = vim.islist(result) and result[1] or result
					local uri = location.uri or location.targetUri
					local range = location.range or location.targetRange
					
					-- Open split first
					vim.cmd("rightbelow vsplit")
					
					-- Open the file
					vim.cmd("edit " .. vim.uri_to_fname(uri))
					
					-- Jump to the position
					local line = range.start.line + 1
					local col = range.start.character + 1
					vim.api.nvim_win_set_cursor(0, { line, col - 1 })
					
					-- Center the screen
					vim.cmd("normal! zz")
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
		vim.keymap.set("n", "<leader>dv", definition_in_vsplit, { noremap = true, silent = true, desc = "Go to definition in vertical split" })
		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, {})
		vim.keymap.set("n", "gi", vim.lsp.buf.implementation, {})
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
		vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, {})
		vim.keymap.set("n", "<leader>s", vim.lsp.buf.signature_help, {})
end,
}
