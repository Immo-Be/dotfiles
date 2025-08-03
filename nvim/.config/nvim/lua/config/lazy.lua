-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Resize vim panes
vim.keymap.set("n", "<leader><leader>h", ":vertical resize -2<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader><leader>l", ":vertical resize +2<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader><leader>k", ":resize +10<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader><leader>j", ":resize -10<CR>", { noremap = true, silent = true })

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

-- improve display of diagnostics
vim.diagnostic.config({
	virtual_text = true, -- Disable inline text (too messy)
	signs = true, -- Keep signs in the gutter
	float = {
		border = "rounded", -- Rounded borders for readability
		focusable = false,
		source = "always",
	},
	severity_sort = true, -- Show errors first
})

vim.keymap.set("n", "<leader>se", function()
    vim.diagnostic.open_float(nil, {
      focusable = false,  -- Don't steal focus
      close_events = { "BufLeave", "CursorMoved", "InsertEnter" }, -- Auto-close when moving
      border = "rounded", -- Rounded corners
      source = "always",  -- Show source of the message
      prefix = "● ",  -- Adds a bullet point for style
    })
end, { desc = "Show diagnostics for current line" })

-- Show diagnostics in a floating window automatically
vim.o.updatetime = 2000 -- Reduce delay before showing diagnostics
vim.api.nvim_create_autocmd("CursorHold", {
    pattern = "*",
    callback = function()
      vim.diagnostic.open_float(nil, { focusable = false, border = "rounded" })
    end,
})


local signs = { Error = "❗", Warn = "⚠️", Hint = "💡", Info = "ℹ️" }
for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

vim.keymap.set("n", "<leader>e", function()
	require("mini.files").open(vim.fn.expand("%:p:h"))
end, { desc = "Open mini.files at current file's directory" })

vim.keymap.set("n", "<leader>E", function()
	require("mini.files").open()
end, { desc = "Open Mini Files" })


-- These don't work
vim.keymap.set("n", "<C-Tab>", ":tabnext<CR>", { desc = "Next Tab" }) -- Ctrl + Tab to go to next tab
vim.keymap.set("n", "<C-S-Tab>", ":tabprevious<CR>", { desc = "Previous Tab" }) -- Ctrl + Shift + Tab to go back

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


-- Setup lazy.nvim
require("lazy").setup({
	spec = {
		-- import your plugins
		{ import = "plugins" },
	},
	-- Configure any other settings here. See the documentation for more details.
	-- colorscheme that will be used when installing plugins.
	install = { colorscheme = { "habamax" } },
	-- automatically check for plugin updates
	checker = { enabled = true },
})
