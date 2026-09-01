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

-- Reload buffers when their files are changed by external tools (for example,
-- an AI agent). Modified buffers are left untouched and trigger a warning.
vim.opt.autoread = true

local external_changes_group = vim.api.nvim_create_augroup("ExternalFileChanges", { clear = true })
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
	group = external_changes_group,
	callback = function()
		if vim.fn.getcmdwintype() == "" then
			vim.cmd("silent! checktime")
		end
	end,
})

-- swap files have been a constant annoyance without ever truly helping ?!
-- i hope i won't regret this
-- Disable swap files safely
vim.opt.swapfile = false

-- Enable spell checking
vim.opt.spell = true
vim.opt.spellfile = vim.fn.stdpath("config") .. "/spell/en.utf-8.add"
-- vim.opt.spelllang = { "en_us", "de_de" }
