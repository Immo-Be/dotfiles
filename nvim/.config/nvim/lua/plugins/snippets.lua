return {
	{
		"hrsh7th/cmp-nvim-lsp",
	},
	{
		"L3MON4D3/LuaSnip",
		dependencies = {
			"saadparwaiz1/cmp_luasnip",
			"rafamadriz/friendly-snippets",
		},
		-- This is related to abecodes/tabout.nvim, see https://github.com/abecodes/tabout.nvim
		keys = function()
			-- Disable default tab keybinding in LuaSnip
			return {}
		end,
	},
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter", -- Load on entering insert mode
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"hrsh7th/cmp-path", -- Make sure path source is installed
			"hrsh7th/cmp-buffer", -- Make sure buffer source is installed
			"zbirenbaum/copilot-cmp", -- Copilot completion source
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			require("luasnip.loaders.from_vscode").lazy_load()
			require("luasnip.loaders.from_vscode").lazy_load({ paths = { vim.fn.stdpath("config") .. "/snippets" } })
			
			-- Load custom Lua snippets
			require("config.luasnip")

			-- Create command to list available snippets
			vim.api.nvim_create_user_command("LuaSnipListAvailable", function()
				local ft = vim.bo.filetype
				local snippets = luasnip.get_snippets(ft)
				local lines = { "Available snippets for filetype: " .. ft, "" }

				if snippets and #snippets > 0 then
					for _, snippet in ipairs(snippets) do
						table.insert(lines, string.format("  %s - %s", snippet.trigger, snippet.name or ""))
					end
				else
					table.insert(lines, "  No snippets available for this filetype")
				end

				-- Display in a floating window
				local buf = vim.api.nvim_create_buf(false, true)
				vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
				vim.bo[buf].modifiable = false

				local width = 60
				local height = #lines
				local opts = {
					relative = "cursor",
					width = width,
					height = height,
					row = 1,
					col = 0,
					style = "minimal",
					border = "rounded",
				}

				local win = vim.api.nvim_open_win(buf, true, opts)
				vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })
				vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":close<CR>", { noremap = true, silent = true })
			end, { desc = "List available LuaSnip snippets for current filetype" })

			-- this if from https://github.com/zbirenbaum/copilot-cmp
			-- Without it, using Tab to go through suggestions does not work
			local has_words_before = function()
				if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then
					return false
				end
				local line, col = unpack(vim.api.nvim_win_get_cursor(0))
				return col ~= 0
					and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match("^%s*$") == nil
			end

			cmp.setup({
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					-- Tab completion
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						elseif has_words_before() then
							cmp.complete()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				sources = cmp.config.sources({
					{ name = "copilot", priority = 1100 }, -- Copilot suggestions (highest priority)
					{ name = "nvim_lsp", priority = 1000 },
					{ name = "luasnip", priority = 750 },
					{
						name = "path",
						priority = 500,
						option = {
							get_cwd = function()
								return vim.fn.getcwd()
							end,
						},
					},
				}, {
					{ name = "buffer", priority = 250 },
				}),
				-- Format completion items to show source
				formatting = {
					format = function(entry, vim_item)
						-- Add source name with icon
						local source_names = {
							copilot = "  Copilot",
							nvim_lsp = "  LSP",
							luasnip = "  Snippet",
							buffer = "  Buffer",
							path = "  Path",
						}
						vim_item.menu = source_names[entry.source.name] or entry.source.name
						return vim_item
					end,
				},
			})
		end,
	},
}
