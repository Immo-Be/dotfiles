-- Indentation
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.tabstop = 2 -- Number of spaces tabs count for
vim.opt.softtabstop = 2 -- Number of spaces for <Tab> in insert mode
vim.opt.shiftwidth = 2 -- Number of spaces for each step of (auto)indent

-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"

-- absolute line numbers combined
vim.opt.number = true
-- Cursorline
vim.opt.cursorline = false

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Preview substitutions
vim.opt.inccommand = "split"

-- Text wrapping
vim.opt.wrap = true
vim.opt.breakindent = true

-- Window splitting
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Save undo history
vim.opt.undofile = true

-- Enable spell checking
vim.opt.spell = true
-- vim.opt.spelllang = { "en_us", "de_de" }
