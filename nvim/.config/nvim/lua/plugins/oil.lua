return {
	"stevearc/oil.nvim",
	config = function()
		require("oil").setup()
		-- oil.nvim
		vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
	end,
	opts = {}, -- Changed from `---@type oil.SetupOpts` to avoid undefined type diagnostic
	-- Optional dependencies
	dependencies = { { "echasnovski/mini.icons", opts = {} } },
	-- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
	-- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
	lazy = false,
}

