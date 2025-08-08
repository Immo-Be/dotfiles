return {
	{
		"yetone/avante.nvim",
		-- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
		-- ⚠️ must add this setting! ! !
		build = function()
			-- conditionally use the correct build system for the current OS
			if vim.fn.has("win32") == 1 then
				return "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
			else
				return "make"
			end
		end,
		event = "VeryLazy",
		version = false, -- Never set this value to "*"! Never!
		---@module 'avante'
		---@type avante.Config
		opts = {
			-- add any opts here
			-- for example
			-- mode = "legacy",
			provider = "copilot",
			providers = {
				copilot = {
					-- disable_tools = true,
					__inherited_from = "copilot",
					request = {
						model = "claude-3.7-sonnet", -- your desired model (or use gpt-4o, etc.)
					},
				},
				copilot_claude_thought = {
					__inherited_from = "copilot",
					request = {
						model = "claude-3.7-sonnet-thought",
					},
				},
				copilot_gpt = {
					__inherited_from = "copilot",
					request = {
						model = "gpt-5",
					},
				},
				copilot_claude = {
					__inherited_from = "copilot",
					request = {
						model = "claude-3.7-sonnet",
					},
				},
			},
			file_selector = {
				provider = "telescope",
				telescope = {
					-- Enable multi-selection support
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
			--- The below dependencies are optional,
			"echasnovski/mini.pick", -- for file_selector provider mini.pick
			"nvim-telescope/telescope.nvim", -- for file_selector provider telescope
			"hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
			"ibhagwan/fzf-lua", -- for file_selector provider fzf
			"stevearc/dressing.nvim", -- for input provider dressing
			"folke/snacks.nvim", -- for input provider snacks
			"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
			"zbirenbaum/copilot.lua", -- for providers='copilot'
			{
				-- support for image pasting
				"HakonHarnes/img-clip.nvim",
				event = "VeryLazy",
				opts = {
					-- recommended settings
					default = {
						embed_image_as_base64 = false,
						prompt_for_file_name = false,
						drag_and_drop = {
							insert_mode = true,
						},
						-- required for Windows users
						use_absolute_path = true,
					},
				},
			},
			{
				-- Make sure to set this up properly if you have lazy=true
				"MeanderingProgrammer/render-markdown.nvim",
				opts = {
					file_types = { "markdown", "Avante" },
				},
				ft = { "markdown", "Avante" },
			},
		},
	},
	-- {
	--   "CopilotC-Nvim/CopilotChat.nvim",
	--   dependencies = {
	--     { "github/copilot.vim" },                    -- or zbirenbaum/copilot.lua
	--     { "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
	--   },
	--   build = "make tiktoken",                       -- Only on MacOS or Linux
	--   opts = {
	--     -- See Configuration section for options
	--   },
	--   -- See Commands section for default commands if you want to lazy load on them
	-- },
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			local copilot = require("copilot")
			copilot.setup({
				panel = {
					enabled = false,
				},
				suggestion = {
					enabled = false,
				},
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
				copilot_node_command = "node", -- Node.js version must be > 18.x
				server_opts_overrides = {},
			})
		end,
	},
	-- {
	--   "olimorris/codecompanion.nvim",
	--   opts = {},
	--   dependencies = {
	--     "nvim-lua/plenary.nvim",
	--     "nvim-treesitter/nvim-treesitter",
	--   },
	-- },
	-- Use render-markdown.nvim to render the markdown in the chat buffer:
	-- {
	--   "MeanderingProgrammer/render-markdown.nvim",
	--   ft = { "markdown", "codecompanion" },
	-- },
	-- Use img-clip.nvim to copy images from your system clipboard into a chat buffer via :PasteImage:
	-- {
	--   "HakonHarnes/img-clip.nvim",
	--   opts = {
	--     filetypes = {
	--       codecompanion = {
	--         prompt_for_file_name = false,
	--         template = "[Image]($FILE_PATH)",
	--         use_absolute_path = true,
	--       },
	--     },
	--   },
	-- },
	-- {
	--   "yetone/avante.nvim",
	--   event = "VeryLazy",
	--   lazy = false,
	--   version = false, -- Set this to "*" to always pull the latest release version, or set it to false to update to the latest code changes.
	--   opts = {
	--     -- add any opts here
	--     -- for example
	--     default_provider = "copilot",
	--     providers = {
	--       copilot = {
	--         -- disable_tools = true,
	--         __inherited_from = "copilot",
	--         request = {
	--           model = "claude-3.7-sonnet", -- your desired model (or use gpt-4o, etc.)
	--         },
	--       },
	--       copilot_claude_thought = {
	--         __inherited_from = "copilot",
	--         request = {
	--           model = "claude-3.7-sonnet-thought",
	--         },
	--       },
	--       copilot_gpt = {
	--         __inherited_from = "copilot",
	--         request = {
	--           model = "gpt-4o",
	--         },
	--       },
	--       copilot_claude = {
	--         __inherited_from = "copilot",
	--         request = {
	--           model = "claude-3.7-sonnet",
	--         },
	--       },
	--     },
	--     file_selector = {
	--       provider = "telescope",
	--       telescope = {
	--         -- Enable multi-selection support
	--         attach_mappings = function(_, map)
	--           map("i", "<CR>", "select_default_with_multi")
	--           map("n", "<CR>", "select_default_with_multi")
	--           return true
	--         end,
	--       },
	--     },
	--   },
	--   -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
	--   build = "make",
	--   -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
	--   dependencies = {
	--     "nvim-treesitter/nvim-treesitter",
	--     "stevearc/dressing.nvim",
	--     "nvim-lua/plenary.nvim",
	--     "MunifTanjim/nui.nvim",
	--     --- The below dependencies are optional,
	--     "echasnovski/mini.pick",         -- for file_selector provider mini.pick
	--     "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
	--     "hrsh7th/nvim-cmp",              -- autocompletion for avante commands and mentions
	--     "ibhagwan/fzf-lua",              -- for file_selector provider fzf
	--     "nvim-tree/nvim-web-devicons",   -- or echasnovski/mini.icons
	--     "zbirenbaum/copilot.lua",        -- for providers='copilot'
	--     {
	--       -- support for image pasting
	--       "HakonHarnes/img-clip.nvim",
	--       event = "VeryLazy",
	--       opts = {
	--         -- recommended settings
	--         default = {
	--           embed_image_as_base64 = false,
	--           prompt_for_file_name = false,
	--           drag_and_drop = {
	--             insert_mode = true,
	--           },
	--           -- required for Windows users
	--           --           use_absolute_path = true,
	--         },
	--       },
	--     },
	--     {
	--       -- Make sure to set this up properly if you have lazy=true
	--       "MeanderingProgrammer/render-markdown.nvim",
	--       opts = {
	--         file_types = { "markdown", "Avante" },
	--       },
	--       ft = { "markdown", "Avante" },
	--     },
	--   },
	-- },
}
