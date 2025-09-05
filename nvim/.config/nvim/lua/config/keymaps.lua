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

vim.api.nvim_set_keymap("n", "<M-Tab>", ":b#<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<M-Tab>", ":b#<CR>", { noremap = true, silent = true })

-- Center screen when going half page with C-D and C-U
vim.keymap.set("n", "<C-d>", "<C-d>zz", { noremap = true, silent = true })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { noremap = true, silent = true })

-- Recommend for avante.nvim: views can only be fully collapsed with the global statusline
vim.opt.laststatus = 3
vim.opt.ignorecase = true

vim.keymap.set("n", "]e", vim.diagnostic.goto_next, { desc = "Next error" })
vim.keymap.set("n", "[e", vim.diagnostic.goto_prev, { desc = "Previous error" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.goto_next, { desc = "Next error" })

vim.keymap.set("n", "]t", ":tabnext<CR>", { desc = "Next tab", noremap = true, silent = true })
vim.keymap.set("n", "[t", ":tabprevious<CR>", { desc = "Previous tab", noremap = true, silent = true })
vim.keymap.set("n", "<leader>t", ":tabnext<CR>", { desc = "Next tab", noremap = true, silent = true })
vim.keymap.set("n", "<leader>tx", ":tabclose<CR>", { desc = "Close tab", noremap = true, silent = true })

vim.keymap.set("n", "]b", ":bnext<CR>", { desc = "Next buffer", noremap = true, silent = true })
vim.keymap.set("n", "[b", ":bprevious<CR>", { desc = "Previous buffer", noremap = true, silent = true })
vim.keymap.set("n", "<leader>b", ":bnext<CR>", { desc = "Next buffer", noremap = true, silent = true })
-- It is a bit annoying but we cannot use <leader>bx here, because it <leader>b is used to show active buffers (bx makes the execution of b wait for another key)
vim.keymap.set("n", "<leader><leader>bx", ":bwipeout<CR>", { desc = "Wipeout Buffer" }) -- Wipe buffer completely

-- Close all buffers
vim.keymap.set("n", "<leader><leader>ba", ":bufdo bwipeout<CR>", { desc = "Close all buffers" })

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

vim.keymap.set("n", "<leader>e", function()
	require("mini.files").open(vim.fn.expand("%:p:h"))
end, { desc = "Open mini.files at current file's directory" })

vim.keymap.set("n", "<leader>E", function()
	require("mini.files").open()
end, { desc = "Open Mini Files" })

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

-- Add keybindings to navigat between nvim windows easier
vim.keymap.set("n", "<C-k>", "<C-w>k", { noremap = true, silent = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { noremap = true, silent = true })
vim.keymap.set("n", "<C-h>", "<C-w>h", { noremap = true, silent = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { noremap = true, silent = true })

-- Yank / delete to system clipboard by default
vim.keymap.set("n", "y", '"+y', { noremap = true })
vim.keymap.set("v", "y", '"+y', { noremap = true })
vim.keymap.set("n", "yy", '"+yy', { noremap = true })
vim.keymap.set("n", "Y", '"+Y', { noremap = true })

vim.keymap.set("v", "d", '"+d', { noremap = true })
vim.keymap.set("n", "d", '"+d', { noremap = true })
vim.keymap.set("n", "dd", '"+dd', { noremap = true })

-- --- ADD THESE LINES FOR IN-LINE PASTE ---
-- "Put" from system clipboard without creating a new line
-- The `g` prefix tells Neovim to put the text after the cursor.
vim.keymap.set("n", "<leader>p", '"+gp', { noremap = true })
vim.keymap.set("n", "<leader>P", '"+gP', { noremap = true })

-- --- OR, REMAP 'p' AND 'P' DIRECTLY ---
-- This might feel more intuitive if you always want this behavior.
-- However, it will remove the default Neovim 'p' and 'P' behavior.
-- vim.keymap.set("n", "p", '"+gp', { noremap = true })
-- vim.keymap.set("n", "P", '"+gP', { noremap = true })

-- undotree toggle
vim.keymap.set("n", "<leader><F5>", vim.cmd.UndotreeToggle)

-- Git related keymaps
vim.keymap.set("n", "<leader>hg", ":DiffviewFileHistory %<CR>", {
  desc = "Git file history (current file)",
  silent = true,
})

vim.keymap.set("n", "<leader>hG", ":DiffviewFileHistory<CR>", {
  desc = "Git history (project)",
  silent = true,
})
-- Map gA to work like g<C-a>
-- The problem is when using neovim in tmux as Ctrl a is the chosen leader prefix there...
-- vim.api.nvim_set_keymap('x', 'gA', 'g<C-a>', {noremap = true})
