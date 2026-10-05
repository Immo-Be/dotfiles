local M = {}

function M.setup()
	local vault_path = vim.fs.normalize("/Users/immo/Documents/notes_vault")

	local function is_vault_buffer(bufnr)
		local name = vim.api.nvim_buf_get_name(bufnr)
		if name == "" then
			return false
		end

		return vim.startswith(vim.fs.normalize(name), vault_path)
	end

	require("snacks").setup({
		input = {},
		picker = {},
	})

	require("img-clip").setup({
		default = {
			embed_image_as_base64 = false,
			prompt_for_file_name = false,
			drag_and_drop = { insert_mode = true },
			use_absolute_path = true,
		},
	})

	require("render-markdown").setup({
		file_types = { "markdown" },
		ignore = function(bufnr)
			return is_vault_buffer(bufnr) and vim.bo[bufnr].filetype == "markdown"
		end,
	})
end

return M
