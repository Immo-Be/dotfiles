local M = {}

function M.setup()
	local bigfile = require("config.bigfile")

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
		automatic_enable = false,
	})

	local capabilities = require("cmp_nvim_lsp").default_capabilities()

	local function configure_and_enable(name, config)
		vim.lsp.config(name, config)

		-- vim.lsp.enable() resolves roots asynchronously. Guard that step so a
		-- large buffer is never serialized and sent in textDocument/didOpen.
		local resolved = vim.lsp.config[name]
		local original_root_dir = resolved.root_dir
		local root_markers = resolved.root_markers
		local workspace_required = resolved.workspace_required

		vim.lsp.config(name, {
			root_dir = function(bufnr, on_dir)
				if bigfile.is_large(bufnr) then
					return
				end

				if type(original_root_dir) == "function" then
					original_root_dir(bufnr, on_dir)
					return
				end

				local root_dir = original_root_dir
				if not root_dir and root_markers then
					root_dir = vim.fs.root(bufnr, root_markers)
				end

				if root_dir or not workspace_required then
					on_dir(root_dir)
				end
			end,
		})

		vim.lsp.enable(name)
	end

	local function on_attach(client, bufnr)
		local ts_names = { tsserver = true, ts_ls = true, vtsls = true }
		if ts_names[client.name] then
			client.server_capabilities.documentFormattingProvider = false
			client.server_capabilities.documentRangeFormattingProvider = false
		end
	end

	configure_and_enable("astro", {
		capabilities = capabilities,
		on_attach = on_attach,
		filetypes = { "astro" },
	})

	configure_and_enable("bashls", {
		capabilities = capabilities,
		on_attach = on_attach,
		filetypes = { "sh", "bash", "zsh" },
	})

	configure_and_enable("vtsls", {
		capabilities = capabilities,
		on_attach = on_attach,
		filetypes = {
			"typescript",
			"typescriptreact",
			"typescript.tsx",
			"javascript",
			"javascriptreact",
			"javascript.jsx",
		},
		settings = {
			vtsls = {
				autoUseWorkspaceTsdk = true,
			},
			typescript = {
				tsserver = {
					experimental = {
						enableProjectDiagnostics = true,
					},
				},
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

	configure_and_enable("lua_ls", {
		capabilities = capabilities,
		on_attach = on_attach,
		settings = {
			Lua = {
				diagnostics = { globals = { "vim" } },
			},
		},
	})

	configure_and_enable("html", {
		capabilities = capabilities,
		on_attach = on_attach,
	})

	configure_and_enable("cssls", {
		capabilities = capabilities,
		on_attach = on_attach,
	})

	configure_and_enable("jsonls", {
		capabilities = capabilities,
		on_attach = on_attach,
	})

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
				vim.fn.setqflist(
					{},
					" ",
					{ title = "LSP Definitions", items = vim.lsp.util.locations_to_items(result, position_encoding) }
				)
				vim.cmd("copen")
				vim.keymap.set("n", "<CR>", function()
					local index = vim.fn.line(".")
					vim.cmd("cclose")
					vim.cmd(index .. "cc")
				end, {
					buffer = vim.api.nvim_get_current_buf(),
					silent = true,
					desc = "Open definition and close quickfix",
				})
			else
				local location = vim.islist(result) and result[1] or result
				vim.lsp.util.jump_to_location(location, position_encoding)
			end
		end)
	end

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
end

return M
