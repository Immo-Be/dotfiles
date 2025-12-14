return {
	{
		"yetone/avante.nvim",
		build = function()
			if vim.fn.has("win32") == 1 then
				return "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
			else
				return "make"
			end
		end,
		event = "VeryLazy",
		version = false,
		opts = {
			-- add any opts here
			-- this file can contain specific instructions for your project
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
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"echasnovski/mini.pick",
			"nvim-telescope/telescope.nvim",
			"hrsh7th/nvim-cmp",
			"ibhagwan/fzf-lua",
			"stevearc/dressing.nvim",
			"folke/snacks.nvim",
			"nvim-tree/nvim-web-devicons",
			"zbirenbaum/copilot.lua",
			{
				"HakonHarnes/img-clip.nvim",
				event = "VeryLazy",
				opts = {
					default = {
						embed_image_as_base64 = false,
						prompt_for_file_name = false,
						drag_and_drop = { insert_mode = true },
						use_absolute_path = true,
					},
				},
			},
			{
				"MeanderingProgrammer/render-markdown.nvim",
				opts = { file_types = { "markdown", "Avante" } },
				ft = { "markdown", "Avante" },
			},
		},
	},
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
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
		end,
	},
	{
		"NeogitOrg/neogit",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local neogit = require("neogit")
			neogit.setup({})

			-- Inline AI commit generator
			local function generate_commit_message()
				local diff = vim.fn.system("git diff --cached")

				if diff == "" then
					vim.notify("No staged changes", vim.log.levels.WARN)
					return
				end

				local prompt = "Generate a concise, conventional commit message for the following git diff:\n" .. diff

				require("avante.api").ask({
					prompt = prompt,
					provider = "copilot",
					on_finish = function(response)
						if not response or response == "" then
							vim.notify("AI did not return a commit message", vim.log.levels.ERROR)
							return
						end

						vim.cmd("Neogit commit")
						vim.defer_fn(function()
							vim.api.nvim_put({ response }, "l", true, true)
						end, 200)
					end,
				})
			end

			-- Expose as a user command instead of keymap
			vim.api.nvim_create_user_command(
				"AICommit",
				generate_commit_message,
				{ desc = "Generate AI commit message with Avante" }
			)
		end,
	},
}
