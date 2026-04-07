local function gh(repo, opts)
	opts = opts or {}
	local spec = {
		src = "https://github.com/" .. repo,
	}

	if opts.name then
		spec.name = opts.name
	end

	if opts.version then
		spec.version = opts.version
	end

	return spec
end

local function run_shell(command, cwd)
	local shell = vim.fn.has("win32") == 1 and { "cmd", "/C", command } or { "sh", "-c", command }
	local result = vim.system(shell, { cwd = cwd, text = true }):wait()
	if result.code ~= 0 then
		local output = result.stderr ~= "" and result.stderr or result.stdout
		vim.notify(string.format("Hook failed: %s\n%s", command, output), vim.log.levels.ERROR)
	end
end

local build_hooks = {
	["avante.nvim"] = {
		{
			shell = vim.fn.has("win32") == 1
					and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
				or "make",
		},
	},
	["fzf"] = {
		{
			load = true,
			func = function()
				vim.fn["fzf#install"]()
			end,
		},
	},
	["nvim-treesitter"] = {
		{ load = true, command = "TSUpdate" },
	},
}

local function setup_build_hooks()
	vim.api.nvim_create_autocmd("PackChanged", {
		callback = function(ev)
			if ev.data.kind == "delete" then
				return
			end

			local hooks = build_hooks[ev.data.spec.name]
			if not hooks then
				return
			end

			for _, hook in ipairs(hooks) do
				if hook.load and not ev.data.active then
					vim.cmd.packadd(ev.data.spec.name)
				end

				if hook.command then
					vim.cmd(hook.command)
				elseif hook.shell then
					run_shell(hook.shell, ev.data.path)
				elseif hook.func then
					local result = hook.func(ev)
					if type(result) == "string" and result ~= "" then
						run_shell(result, ev.data.path)
					end
				end
			end
		end,
	})
end

local pack_specs = {
	gh("catppuccin/nvim", { name = "catppuccin" }),
	gh("echasnovski/mini.files"),
	gh("echasnovski/mini.comment"),
	gh("echasnovski/mini.icons"),
	gh("stevearc/oil.nvim"),
	gh("nvim-neo-tree/neo-tree.nvim"),
	gh("nvim-lua/plenary.nvim"),
	gh("nvim-tree/nvim-web-devicons"),
	gh("MunifTanjim/nui.nvim"),
	gh("nvim-telescope/telescope.nvim"),
	gh("nvim-telescope/telescope-ui-select.nvim"),
	gh("hrsh7th/cmp-nvim-lsp"),
	gh("L3MON4D3/LuaSnip"),
	gh("saadparwaiz1/cmp_luasnip"),
	gh("rafamadriz/friendly-snippets"),
	gh("hrsh7th/cmp-path"),
	gh("hrsh7th/cmp-buffer"),
	gh("hrsh7th/nvim-cmp"),
	gh("windwp/nvim-autopairs"),
	gh("christoomey/vim-tmux-navigator"),
	gh("nvim-treesitter/nvim-treesitter", { version = "4916d6592ede8c07973490d9322f187e07dfefac" }),
	gh("windwp/nvim-ts-autotag"),
	gh("HiPhish/rainbow-delimiters.nvim"),
	gh("nvim-treesitter/nvim-treesitter-textobjects"),
	gh("nvim-treesitter/nvim-treesitter-context"),
	gh("neovim/nvim-lspconfig"),
	gh("williamboman/mason.nvim"),
	gh("williamboman/mason-lspconfig.nvim"),
	gh("WhoIsSethDaniel/mason-tool-installer.nvim"),
	gh("nvimtools/none-ls.nvim"),
	gh("nvimtools/none-ls-extras.nvim"),
	gh("stevearc/conform.nvim"),
	gh("mfussenegger/nvim-lint"),
	gh("yetone/avante.nvim"),
	gh("zbirenbaum/copilot.lua"),
	gh("echasnovski/mini.pick"),
	gh("ibhagwan/fzf-lua"),
	gh("stevearc/dressing.nvim"),
	gh("folke/snacks.nvim"),
	gh("HakonHarnes/img-clip.nvim"),
	gh("MeanderingProgrammer/render-markdown.nvim"),
	gh("akinsho/git-conflict.nvim"),
	gh("sindrets/diffview.nvim"),
	gh("NeogitOrg/neogit"),
	gh("lewis6991/gitsigns.nvim"),
	gh("NickvanDyke/opencode.nvim"),
	gh("nvim-lualine/lualine.nvim"),
	gh("folke/which-key.nvim"),
	gh("norcalli/nvim-colorizer.lua"),
	gh("RRethy/vim-illuminate"),
	gh("lukas-reineke/indent-blankline.nvim"),
	gh("kylechui/nvim-surround"),
	gh("kevinhwang91/nvim-bqf"),
	gh("junegunn/fzf"),
	gh("mattn/emmet-vim"),
	gh("folke/trouble.nvim"),
	gh("kkharji/sqlite.lua"),
}

local setup_modules = {
	"plugins.catppuccin",
	"plugins.mini-library",
	"plugins.oil",
	"plugins.neo-tree",
	"plugins.telescope",
	"plugins.snippets",
	"plugins.autopairs",
	"plugins.nvim-tmux-navigator",
	"plugins.treesitter",
	"plugins.lsp-config",
	"plugins.mason-tool-installer",
	"plugins.none-ls",
	"plugins.conform",
	"plugins.nvim-lint",
	"plugins.copilot",
	"plugins.git-integrations",
	"plugins.opencode",
	"plugins.lualine",
	"plugins.which-key",
	"plugins.nvim-colorizer",
	"plugins.vim-illuminate",
	"plugins.indent-blankline",
	"plugins.vim-surround",
	"plugins.bqf",
	"plugins.emmet-vim",
	"plugins.trouble",
	"plugins.sqlite",
}

require("plugins.nvim-tmux-navigator").init()
setup_build_hooks()

vim.api.nvim_create_user_command("PackUpdateAll", function()
	vim.pack.update()
end, { desc = "Update all vim.pack plugins" })

vim.api.nvim_create_user_command("PackUpdateLockfile", function()
	vim.pack.update(nil, { offline = true, target = "lockfile" })
end, { desc = "Sync plugins to nvim-pack-lock.json" })

vim.pack.add(pack_specs, { confirm = false, load = true })

for _, module_name in ipairs(setup_modules) do
	local module = require(module_name)
	if type(module.setup) == "function" then
		module.setup()
	end
end
