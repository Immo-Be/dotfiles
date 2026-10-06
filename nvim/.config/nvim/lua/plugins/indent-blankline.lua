local M = {}

local opts = {
	indent = {
		char = "▏", -- Very subtle thin line
		tab_char = "▏",
	},
	scope = {
		enabled = true, -- Highlight current scope
		show_start = true,
		show_end = false,
		highlight = { "IblScope" }, -- Use dimmer highlight
	},
	exclude = {
		filetypes = {
			"help",
			"alpha",
			"dashboard",
			"neo-tree",
			"Trouble",
			"trouble",
			"lazy",
			"mason",
			"notify",
			"toggleterm",
			"lazyterm",
		},
	},
}

function M.setup()
	local ibl = require("ibl")
	ibl.setup(opts)
	vim.api.nvim_create_autocmd("FileType", {
		callback = function(args)
			if require("config.bigfile").is_large(args.buf) then
				ibl.setup_buffer(args.buf, { enabled = false })
			end
		end,
	})

	vim.api.nvim_create_user_command("IndentGuidesToggle", function()
		vim.cmd("IBLToggle")
	end, { desc = "Toggle indent guides on/off" })
end

return M
