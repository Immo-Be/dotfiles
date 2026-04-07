local M = {}

local avante_opts = {
	provider = "copilot",
	providers = {
		copilot = {
			model = "gpt-4-0125-preview",
		},
		copilot_test = {
			__inherited_from = "copilot",
			request = {
				model = "gpt-iasdf-2025-08-07",
			},
		},
		copilot_5 = {
			__inherited_from = "copilot",
			request = {
				model = "gpt-5-2025-08-07",
			},
		},
		copilot_5_mini = {
			__inherited_from = "copilot",
			request = {
				model = "gpt-5-mini-2025-08-07",
			},
		},
	},
	file_selector = {
		provider = "telescope",
		telescope = {
			attach_mappings = function(_, map)
				map("i", "<CR>", "select_default_with_multi")
				map("n", "<CR>", "select_default_with_multi")
				return true
			end,
		},
	},
}

function M.setup()
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
		file_types = { "markdown", "Avante" },
	})

	require("avante").setup(avante_opts)
	require("copilot").setup({
		panel = { enabled = false },
		suggestion = { enabled = false },
		filetypes = {
			yaml = true,
			markdown = true,
			help = true,
			gitcommit = true,
			gitrebase = true,
			hgcommit = true,
			svn = false,
			cvs = false,
			["."] = false,
		},
		copilot_node_command = "node",
		server_opts_overrides = {},
	})
end

return M
