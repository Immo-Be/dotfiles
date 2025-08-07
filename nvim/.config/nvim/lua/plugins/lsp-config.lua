return {

	"neovim/nvim-lspconfig",
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
	},
	config = function()
		-- Mason Setup
		require("mason").setup()
		require("mason-lspconfig").setup({
			ensure_installed = {
				"lua_ls",
				"ts_ls",
				"html",
				"cssls",
				"jsonls",
				"astro",
			},
		})

		local capabilities = require("cmp_nvim_lsp").default_capabilities()

		-- Disable formatting from tsserver
		local on_attach = function(client, bufnr)
			if client.name == "tsserver" then
				client.server_capabilities.documentFormattingProvider = false
			end
		end

		local lspconfig = require("lspconfig")

		-- Astro LSP
		lspconfig.astro.setup({
			capabilities = capabilities,
			on_attach = on_attach,
			filetypes = { "astro" },
		})

		-- TypeScript/JavaScript LSP
		lspconfig.ts_ls.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})

		-- HTML, CSS, JSON
		lspconfig.html.setup({ capabilities = capabilities })
		lspconfig.cssls.setup({ capabilities = capabilities })
		lspconfig.jsonls.setup({ capabilities = capabilities })

		-- Keymaps
		local telescope_builtin = require("telescope.builtin")
		vim.keymap.set(
			"n",
			"gr",
			telescope_builtin.lsp_references,
			{ noremap = true, silent = true, desc = "Telescope LSP References" }
		)

		-- Lua LSP
    -- this is the new way to configure language servers using the builtin vim.lsp.config interface.
    -- i should re-implement the lspconfig setup using this method.
		vim.lsp.config("lua_ls", {
			settings = {
				Lua = {
					diagnostics = {
						globals = { "vim" },
					},
				},
			},
		})

		vim.keymap.set("n", "<C-e>", vim.lsp.buf.hover, {})
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, {})
		vim.keymap.set("n", "gi", vim.lsp.buf.implementation, {})
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
		vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, {})
		vim.keymap.set("n", "<leader>s", vim.lsp.buf.signature_help, {})
	end,
}
