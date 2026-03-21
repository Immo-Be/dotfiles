-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.keymap.set("n", "K", "5k", { noremap = true }) -- Move up 5 lines
vim.keymap.set("n", "J", "5j", { noremap = true }) -- Down up 5 lines

-- Telescope bidings for LSP: Go to definition, references, document symbols, workspace symbols
vim.keymap.set("n", "<leader>ds", ":Telescope lsp_document_symbols<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>ws", ":Telescope lsp_workspace_symbols<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>%", ":vsplit<CR>", { noremap = true, silent = true }) -- Vertical split
vim.keymap.set("n", '<leader>"', ":split<CR>", { noremap = true, silent = true }) -- Horizontal split

vim.keymap.set("n", "<M-Tab>", ":b#<CR>", { noremap = true, silent = true })

-- Center screen when going half page with C-D and C-U
vim.keymap.set("n", "<C-d>", "<C-d>zz", { noremap = true, silent = true })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { noremap = true, silent = true })

-- Recommend for avante.nvim: views can only be fully collapsed with the global statusline
vim.opt.laststatus = 3

-- Enhanced diagnostic navigation with centering and auto-float
vim.keymap.set("n", "]e", function()
	vim.diagnostic.goto_next()
	vim.cmd("normal! zz") -- Center screen
	-- Show diagnostic float after a short delay
	vim.defer_fn(function()
		vim.diagnostic.open_float(nil, {
			focusable = false,
			close_events = { "BufLeave", "CursorMoved", "InsertEnter" },
			border = "rounded",
			source = "always",
			prefix = "● ",
		})
	end, 100)
end, { desc = "Next error (centered with float)" })

vim.keymap.set("n", "[e", function()
	vim.diagnostic.goto_prev()
	vim.cmd("normal! zz") -- Center screen
	-- Show diagnostic float after a short delay
	vim.defer_fn(function()
		vim.diagnostic.open_float(nil, {
			focusable = false,
			close_events = { "BufLeave", "CursorMoved", "InsertEnter" },
			border = "rounded",
			source = "always",
			prefix = "● ",
		})
	end, 100)
end, { desc = "Previous error (centered with float)" })

vim.keymap.set("n", "]t", ":tabnext<CR>", { desc = "Next tab", noremap = true, silent = true })
vim.keymap.set("n", "[t", ":tabprevious<CR>", { desc = "Previous tab", noremap = true, silent = true })
vim.keymap.set("n", "<leader>t", ":tabnext<CR>", { desc = "Next tab", noremap = true, silent = true })
vim.keymap.set("n", "<leader>tx", ":tabclose<CR>", { desc = "Close tab", noremap = true, silent = true })

vim.keymap.set("n", "]b", ":bnext<CR>", { desc = "Next buffer", noremap = true, silent = true })
vim.keymap.set("n", "[b", ":bprevious<CR>", { desc = "Previous buffer", noremap = true, silent = true })
-- Removed <leader>b conflict - using Telescope's builtin.buffers instead (defined in telescope.lua)
-- Use ]b and [b for quick buffer navigation, or <leader>b for interactive buffer picker
vim.keymap.set("n", "<leader>bx", ":bwipeout<CR>", { desc = "Wipeout Buffer" }) -- Wipe buffer completely

-- Close all buffers
vim.keymap.set("n", "<leader>ba", ":bufdo bwipeout<CR>", { desc = "Close all buffers" })

-- remap=true so we can reuse the existing "[r" motion
-- jumps to the last return() in the buffer
-- Potentially useful for jsx files
vim.keymap.set("n", "<leader>r", "G[r", { remap = true, desc = "Jump to last return() in buffer" })

vim.keymap.set("n", "<leader>se", function()
	vim.diagnostic.open_float(nil, {
		focusable = false, -- Don't steal focus
		close_events = { "BufLeave", "CursorMoved", "InsertEnter" }, -- Auto-close when moving
		border = "rounded", -- Rounded corners
		source = "always", -- Show source of the message
		prefix = "● ", -- Adds a bullet point for style
	})
end, { desc = "Show diagnostics for current line" })

-- Mini.files explorer (e for explorer)
vim.keymap.set("n", "<leader>e", function()
	require("mini.files").open(vim.fn.expand("%:p:h"))
end, { desc = "Open mini.files at current file's directory" })

vim.keymap.set("n", "<leader>E", function()
	require("mini.files").open()
end, { desc = "Open Mini Files at cwd" })

-- This remaps the Ctrl + S to Ctrl + A
-- We do this because we use Ctrl + S as the leader key for tmux
vim.keymap.set("n", "+", "<C-a>", { desc = "Increment numbers" })
vim.keymap.set("n", "-", "<C-x>", { desc = "Decrement numbers" })
vim.keymap.set("v", "+", "<C-a>gv", { desc = "Increment numbers" })
vim.keymap.set("v", "-", "<C-x>gv", { desc = "Decrement numbers" })

vim.keymap.set("n", "g+", "g<C-a>", { desc = "Increment numbers" })
vim.keymap.set("n", "g-", "g<C-x>", { desc = "Decrement numbers" })
vim.keymap.set("v", "g+", "g<C-a>gv", { desc = "Increment numbers" })
vim.keymap.set("v", "g-", "g<C-x>gv", { desc = "Decrement numbers" })

vim.keymap.set("n", "<Leader>j", "J", { noremap = true }) -- Join lines

-- Command mode keybindings
vim.keymap.set("c", "<Leader>w", ":wa<CR>", { noremap = true, silent = true }) -- Save all files

-- Insert mode keybindings (non-recursive)
vim.keymap.set("i", "jk", "<Esc>", { noremap = true }) -- Escape insert mode by pressing 'jk'

-- Add keybindings to navigate between nvim windows easier
vim.keymap.set("n", "<C-k>", "<C-w>k", { noremap = true, silent = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { noremap = true, silent = true })
vim.keymap.set("n", "<C-h>", "<C-w>h", { noremap = true, silent = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { noremap = true, silent = true })

-- Quick window resizing
vim.keymap.set("n", "<leader>+", ":vertical resize +5<CR>", { desc = "Increase window width", silent = true })
vim.keymap.set("n", "<leader>-", ":vertical resize -5<CR>", { desc = "Decrease window width", silent = true })
vim.keymap.set("n", "<leader>=", "<C-w>=", { desc = "Equalize window sizes", silent = true })

-- Yank / delete to system clipboard by default
vim.keymap.set("n", "y", '"+y', { noremap = true })
vim.keymap.set("v", "y", '"+y', { noremap = true })
vim.keymap.set("n", "yy", '"+yy', { noremap = true })
-- Make Y behave like y$, yanking from the cursor to the end of the line
vim.keymap.set("n", "Y", "y$", { noremap = true })

-- Delete (cut) to system clipboard for larger operations
-- This makes delete work like "cut" for larger operations (dd, dw, dap, etc.)
-- Small deletes (x, single character) keep default behavior
vim.keymap.set("n", "dd", '"+dd', { noremap = true })
vim.keymap.set("n", "d", '"+d', { noremap = true })
vim.keymap.set("v", "d", '"+d', { noremap = true })

-- Paste from system clipboard
-- Normal mode: paste from system clipboard
vim.keymap.set("n", "p", '"+p', { noremap = true })
vim.keymap.set("n", "P", '"+P', { noremap = true })

-- Visual mode: paste from system clipboard without yanking replaced text
-- This prevents the replaced text from overwriting your clipboard
vim.keymap.set("v", "p", '"+p', { noremap = true })
vim.keymap.set("v", "P", '"+P', { noremap = true })

-- Note: You can still access Neovim's unnamed register with ""p if needed

-- undotree toggle
vim.keymap.set("n", "<leader><F5>", vim.cmd.UndotreeToggle)

-- Git related keymaps
vim.keymap.set("n", "<leader>hm", function()
	vim.ui.input({ prompt = "Commit message: " }, function(message)
		if message and #message > 0 then
			vim.fn.jobstart({ "git", "commit", "-m", message }, {
				on_exit = function(_, exit_code)
					if exit_code == 0 then
						vim.notify("Commit successful", vim.log.levels.INFO)
						require("gitsigns").refresh()
					else
						vim.notify("Commit failed", vim.log.levels.ERROR)
					end
				end,
			})
		else
			vim.notify("Commit cancelled", vim.log.levels.WARN)
		end
	end)
end, { desc = "Git commit with message (staged changes)" })

vim.keymap.set("n", "<leader>ha", function()
	require("utils.git").commit_with_ai()
end, { desc = "Git commit with AI-generated message" })

vim.keymap.set("n", "<leader>hp", function()
	require("utils.git").push_with_confirmation()
end, { desc = "Git push (with confirmation)" })

-- Keybinding to view Git file history for the current file
vim.keymap.set("n", "<leader>hg", ":DiffviewFileHistory %<CR>", {
	desc = "Git file history (current file)",
	silent = true,
})
-- Trace the line evolution of the visual selection
vim.keymap.set("v", "<leader>hg", ":'<,'>DiffviewFileHistory<CR>", {
	desc = "Git line history (selection)",
	silent = true,
})

-- Keybinding to view Git history for the entire project
vim.keymap.set("n", "<leader>hG", ":DiffviewFileHistory<CR>", {
	desc = "Git history (project)",
	silent = true,
})
-- Map gA to work like g<C-a>
-- The problem is when using neovim in tmux as Ctrl a is the chosen leader prefix there...
-- vim.api.nvim_set_keymap('x', 'gA', 'g<C-a>', {noremap = true})

-- Console.log keybinding (Turbo Console Log style)
vim.keymap.set("n", "<leader>cg", function()
	local line_num = vim.fn.line(".")
	local file_name = vim.fn.expand("%:t")
	local word = vim.fn.expand("<cword>")

	local log_line = string.format('console.log("🚀 ~ %s:%s → %s:", %s);', file_name, line_num, word, word)

	vim.api.nvim_put({ log_line }, "l", true, true)
end, { desc = "Insert console.log for word under cursor" })

vim.keymap.set("v", "<leader>cg", function()
	local line_num = vim.fn.line(".")
	local file_name = vim.fn.expand("%:t")

	-- Get the visual selection
	vim.cmd('noau normal! "vy"')
	local selected_text = vim.fn.getreg("v"):gsub("\n", " ")

	-- Exit visual mode
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)

	local log_line =
		string.format('console.log("🚀 ~ %s:%s → %s:", %s);', file_name, line_num, selected_text, selected_text)

	vim.api.nvim_put({ log_line }, "l", true, true)
end, { desc = "Insert console.log for visual selection" })
