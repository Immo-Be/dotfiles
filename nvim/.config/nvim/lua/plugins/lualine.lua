return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },

	config = function()
		require("lualine").setup({
			options = {
				icons_enabled = true,
				theme = "catppuccin",
				section_separators = "",
				component_separators = "",
				globalstatus = true, -- single statusline
			},
			sections = {
				lualine_a = { "lsp_status" },
				-- lualine_a = {
				-- 	"buffers",
				-- },
				lualine_b = { "branch", "diff", "diagnostics" },
				lualine_c = { { "filename", path = 1 }, lsp_name },
				lualine_x = { "encoding", "fileformat", "filetype" },
				lualine_y = { "progress" },
				lualine_z = { "location", scrollbar },
			},
		})
	end,
}
