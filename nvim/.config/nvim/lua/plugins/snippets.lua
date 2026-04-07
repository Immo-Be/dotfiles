local M = {}

function M.setup()
	local cmp = require("cmp")
	local luasnip = require("luasnip")

	require("luasnip.loaders.from_vscode").lazy_load()
	require("luasnip.loaders.from_vscode").lazy_load({ paths = { vim.fn.stdpath("config") .. "/snippets" } })
	require("config.luasnip")

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

		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		vim.bo[buf].modifiable = false

		local opts = {
			relative = "cursor",
			width = 60,
			height = #lines,
			row = 1,
			col = 0,
			style = "minimal",
			border = "rounded",
		}

		vim.api.nvim_open_win(buf, true, opts)
		vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })
		vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":close<CR>", { noremap = true, silent = true })
	end, { desc = "List available LuaSnip snippets for current filetype" })

	local has_words_before = function()
		if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then
			return false
		end
		local line, col = unpack(vim.api.nvim_win_get_cursor(0))
		return col ~= 0 and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match("^%s*$") == nil
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
		formatting = {
			format = function(entry, vim_item)
				local source_names = {
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
end

return M
