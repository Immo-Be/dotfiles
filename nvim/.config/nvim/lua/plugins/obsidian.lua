local M = {}

function M.setup()
	local obsidian = require("obsidian")
	local vault_path = vim.fs.normalize("/Users/immo/Documents/notes_vault")

	local function is_vault_buffer(bufnr)
		local name = vim.api.nvim_buf_get_name(bufnr)
		if name == "" then
			return false
		end

		return vim.startswith(vim.fs.normalize(name), vault_path)
	end

	obsidian.setup({
		legacy_commands = false,
		workspaces = {
			{
				name = "personal",
				path = "/Users/immo/Documents/notes_vault",
			},
		},
		picker = {
			name = "telescope.nvim",
		},
		completion = {
			nvim_cmp = true,
			blink = false,
			min_chars = 2,
			match_case = true,
			create_new = true,
		},
		open_notes_in = "current",
		new_notes_location = "current_dir",
		ui = {
			enable = true,
		},
		footer = {
			enabled = true,
		},
		attachments = {
			folder = "attachments",
		},
	})

	vim.keymap.set("n", "<leader>on", ":Obsidian new<CR>", { desc = "Obsidian new note", silent = true })
	vim.keymap.set("n", "<leader>os", ":Obsidian search<CR>", { desc = "Obsidian search notes", silent = true })
	vim.keymap.set("n", "<leader>oq", ":Obsidian quick_switch<CR>", { desc = "Obsidian quick switch", silent = true })
	vim.keymap.set("n", "<leader>ot", ":Obsidian today<CR>", { desc = "Obsidian today", silent = true })
	vim.keymap.set({ "n", "v" }, "<leader>ol", ":Obsidian backlinks<CR>", { desc = "Obsidian backlinks", silent = true })

	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
		pattern = "*.md",
		callback = function(args)
			if not is_vault_buffer(args.buf) then
				return
			end

			vim.keymap.set("n", "<CR>", ":Obsidian follow_link<CR>", {
				buffer = args.buf,
				noremap = true,
				silent = true,
				desc = "Obsidian follow link",
			})
			vim.keymap.set("n", "[o", ":Obsidian backlinks<CR>", {
				buffer = args.buf,
				noremap = true,
				silent = true,
				desc = "Obsidian backlinks",
			})
			vim.keymap.set("n", "]o", ":Obsidian follow_link<CR>", {
				buffer = args.buf,
				noremap = true,
				silent = true,
				desc = "Obsidian follow link",
			})
			vim.keymap.set("n", "<localleader>n", ":Obsidian new<CR>", {
				buffer = args.buf,
				noremap = true,
				silent = true,
				desc = "Obsidian new note",
			})
			vim.keymap.set("n", "<localleader>s", ":Obsidian search<CR>", {
				buffer = args.buf,
				noremap = true,
				silent = true,
				desc = "Obsidian search notes",
			})
			vim.keymap.set("n", "<localleader>q", ":Obsidian quick_switch<CR>", {
				buffer = args.buf,
				noremap = true,
				silent = true,
				desc = "Obsidian quick switch",
			})
			vim.keymap.set("n", "<localleader>t", ":Obsidian today<CR>", {
				buffer = args.buf,
				noremap = true,
				silent = true,
				desc = "Obsidian today",
			})
			vim.keymap.set("n", "<localleader>r", ":Obsidian rename<CR>", {
				buffer = args.buf,
				noremap = true,
				silent = true,
				desc = "Obsidian rename note",
			})
			vim.keymap.set({ "x" }, "<localleader>l", ":Obsidian link<CR>", {
				buffer = args.buf,
				noremap = true,
				silent = true,
				desc = "Obsidian link selection",
			})
			vim.keymap.set({ "x" }, "<localleader>L", ":Obsidian link_new<CR>", {
				buffer = args.buf,
				noremap = true,
				silent = true,
				desc = "Obsidian link new note",
			})
			vim.keymap.set("n", "<localleader>b", ":Obsidian backlinks<CR>", {
				buffer = args.buf,
				noremap = true,
				silent = true,
				desc = "Obsidian backlinks",
			})
		end,
	})
end

return M
