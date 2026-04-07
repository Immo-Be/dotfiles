local M = {}

local function lsp_name()
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	if #clients == 0 then
		return ""
	end

	local names = {}
	for _, client in ipairs(clients) do
		if client.name ~= "null-ls" then
			table.insert(names, client.name)
		end
	end

	if #names == 0 then
		return ""
	end

	return table.concat(names, ",")
end

local function scrollbar()
	local current_line = vim.api.nvim_win_get_cursor(0)[1]
	local total_lines = vim.api.nvim_buf_line_count(0)
	local bars = { "__", "▁▁", "▂▂", "▃▃", "▄▄", "▅▅", "▆▆", "▇▇", "██" }

	if total_lines == 0 then
		return bars[1]
	end

	local index = math.ceil((current_line / total_lines) * #bars)
	return bars[math.max(1, math.min(index, #bars))]
end

function M.setup()
	require("lualine").setup({
		options = {
			icons_enabled = true,
			theme = "catppuccin-frappe",
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
end

return M
