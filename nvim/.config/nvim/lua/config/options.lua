-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"

-- absolute line numbers combined
vim.opt.number = true
-- Cursorline
vim.opt.cursorline = false

-- Show whitespace characters
-- vim.opt.list = true
-- vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

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
