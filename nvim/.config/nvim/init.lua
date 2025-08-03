vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")

-- views can only be fully collapsed with the global statusline
-- https://github.com/yetone/avante.nvim
vim.opt.laststatus = 3

-- Set leader key (optional if not already set)
vim.g.mapleader = " "

vim.keymap.set("n", "K", "5k", { noremap = true }) -- Move up 5 lines
vim.keymap.set("n", "J", "5j", { noremap = true }) -- Down up 5 lines

-- vim.opt.timeoutlen = 1000
-- vim.opt.ttimeoutlen = 0

vim.keymap.set("n", "<Leader>j", "J", { noremap = true }) -- Join lines

-- Command mode keybindings
vim.keymap.set("c", "<Leader>w", ":wa<CR>", { noremap = true, silent = true }) -- Save all files

-- Insert mode keybindings (non-recursive)
vim.keymap.set("i", "jk", "<Esc>", { noremap = true }) -- Escape insert mode by pressing 'jk'

-- Normal mode: Add selection to next find match (requires 'vim-visual-multi' or similar plugin)
vim.keymap.set(
	"n",
	"<Leader>*",
	':lua require("vim-visual-multi").add_selection_to_next_find_match()<CR>',
	{ noremap = true, silent = true }
)

-- Add keybindings to navigat between nvim windows easier
vim.keymap.set("n", "<C-k>", "<C-w>k", { noremap = true, silent = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { noremap = true, silent = true })
vim.keymap.set("n", "<C-h>", "<C-w>h", { noremap = true, silent = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { noremap = true, silent = true })

-- Yank to system clipboard by default
vim.keymap.set("n", "y", '"+y', { noremap = true })
vim.keymap.set("v", "y", '"+y', { noremap = true })
vim.keymap.set("n", "yy", '"+yy', { noremap = true })
vim.keymap.set("n", "Y", '"+Y', { noremap = true })

-- Delete to system clipboard by default
vim.keymap.set("n", "d", '"+d', { noremap = true })
vim.keymap.set("v", "d", '"+d', { noremap = true })

-- Paste from system clipboard
vim.keymap.set("n", "p", '"+p', { noremap = true })
vim.keymap.set("n", "P", '"+P', { noremap = true })

-- Map gA to work like g<C-a>
-- The problem is when using neovim in tmux as Ctrl a is the chosen leader prefix there...
-- vim.api.nvim_set_keymap('x', 'gA', 'g<C-a>', {noremap = true})

vim.opt.number = true -- Enable absolute line numbers

require("config.lazy")
