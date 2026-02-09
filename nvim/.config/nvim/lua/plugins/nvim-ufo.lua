return {
	"kevinhwang91/nvim-ufo",
	dependencies = {
		"kevinhwang91/promise-async",
	},
	event = "BufReadPost", -- Load after buffer is read
	config = function()
		-- Disable fold column (no indicators on left side)
		vim.o.foldcolumn = "0"
		vim.o.foldlevel = 99 -- Start with all folds open by default
		vim.o.foldlevelstart = 99 -- Open all folds when opening a file
		vim.o.foldenable = true

		-- Use treesitter for fold text (shows what's inside the fold)
		local handler = function(virtText, lnum, endLnum, width, truncate)
			local newVirtText = {}
			local suffix = (" 󰁂 %d lines "):format(endLnum - lnum)
			local sufWidth = vim.fn.strdisplaywidth(suffix)
			local targetWidth = width - sufWidth
			local curWidth = 0

			for _, chunk in ipairs(virtText) do
				local chunkText = chunk[1]
				local chunkWidth = vim.fn.strdisplaywidth(chunkText)
				if targetWidth > curWidth + chunkWidth then
					table.insert(newVirtText, chunk)
				else
					chunkText = truncate(chunkText, targetWidth - curWidth)
					local hlGroup = chunk[2]
					table.insert(newVirtText, { chunkText, hlGroup })
					chunkWidth = vim.fn.strdisplaywidth(chunkText)
					if curWidth + chunkWidth < targetWidth then
						suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
					end
					break
				end
				curWidth = curWidth + chunkWidth
			end

			table.insert(newVirtText, { suffix, "MoreMsg" })
			return newVirtText
		end

		require("ufo").setup({
			-- Use treesitter as primary for React/JSX files, LSP as fallback
			-- This gives better granularity for nested functions in components
			provider_selector = function(bufnr, filetype, buftype)
				local ftMap = {
					typescriptreact = { "treesitter", "indent" },
					javascriptreact = { "treesitter", "indent" },
					typescript = { "lsp", "treesitter" },
					javascript = { "lsp", "treesitter" },
				}
				return ftMap[filetype] or { "lsp", "treesitter" }
			end,
			fold_virt_text_handler = handler,
			-- Enable close_fold_kinds for more granular folding
			close_fold_kinds_for_ft = {
				default = {},
				typescriptreact = { "imports", "comment" },
				javascriptreact = { "imports", "comment" },
			},
			-- Preview fold contents with hover
			preview = {
				win_config = {
					border = "rounded",
					winhighlight = "Normal:Normal",
					winblend = 0,
				},
				mappings = {
					scrollU = "<C-u>",
					scrollD = "<C-d>",
					jumpTop = "[",
					jumpBot = "]",
				},
			},
		})

		-- Auto-fold large files (>300 lines) to fold level 1
		vim.api.nvim_create_autocmd("BufReadPost", {
			group = vim.api.nvim_create_augroup("auto_fold_large_files", { clear = true }),
			callback = function()
				local line_count = vim.api.nvim_buf_line_count(0)
				if line_count > 300 then
					-- Close folds to level 1 for large files
					vim.opt_local.foldlevel = 1
					vim.opt_local.foldlevelstart = 1
				end
			end,
		})

		-- Keybindings for fold management
		vim.keymap.set("n", "zR", require("ufo").openAllFolds, { desc = "Open all folds" })
		vim.keymap.set("n", "zM", require("ufo").closeAllFolds, { desc = "Close all folds" })
		vim.keymap.set("n", "zK", function()
			local winid = require("ufo").peekFoldedLinesUnderCursor()
			if not winid then
				vim.lsp.buf.hover()
			end
		end, { desc = "Peek fold or show hover" })

		-- Use zm/zr for incremental folding (more/less folding)
		-- This helps navigate nested folds in React components
		vim.keymap.set("n", "zr", "zr", { desc = "Reduce fold level (open one level)" })
		vim.keymap.set("n", "zm", "zm", { desc = "More folding (close one level)" })

		-- Standard vim fold commands:
		-- zc - close fold under cursor (closes innermost fold)
		-- zo - open fold under cursor  
		-- za - toggle fold under cursor
		-- zO - open all nested folds under cursor
		-- zC - close all nested folds under cursor
		-- [z - move to start of current fold
		-- ]z - move to end of current fold
	end,
}
