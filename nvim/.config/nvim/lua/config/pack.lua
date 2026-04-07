local pinned_versions = {
	["LuaSnip"] = "a62e1083a3cfe8b6b206e7d3d33a51091df25357",
	["avante.nvim"] = "8c84af0f09e5d9058362ac58401a8e7b047d826e",
	["catppuccin"] = "426dbebe06b5c69fd846ceb17b42e12f890aedf1",
	["cmp-buffer"] = "b74fab3656eea9de20a9b8116afa3cfc4ec09657",
	["cmp-nvim-lsp"] = "cbc7b02bb99fae35cb42f514762b89b5126651ef",
	["cmp-path"] = "c642487086dbd9a93160e1679a1327be111cbc25",
	["cmp_luasnip"] = "98d9cb5c2c38532bd9bdb481067b20fea8f32e90",
	["conform.nvim"] = "086a40dc7ed8242c03be9f47fbcee68699cc2395",
	["copilot.lua"] = "07aa57148ac28986bab9f55e87ee3d929e2726b1",
	["diffview.nvim"] = "4516612fe98ff56ae0415a259ff6361a89419b0a",
	["dressing.nvim"] = "2d7c2db2507fa3c4956142ee607431ddb2828639",
	["emmet-vim"] = "92ef2f74f4093edc99db5e9e4cf7e40116a85bd6",
	["friendly-snippets"] = "6cd7280adead7f586db6fccbd15d2cac7e2188b9",
	["fzf"] = "18315000185a6e6461b9b4aa4a4cb6cd164e0e35",
	["fzf-lua"] = "9f0432fdd7825ab163520045831a40b6df82ea28",
	["git-conflict.nvim"] = "4bbfdd92d547d2862a75b4e80afaf30e73f7bbb4",
	["gitsigns.nvim"] = "0d797daee85366bc242580e352a4f62d67557b84",
	["img-clip.nvim"] = "b6ddfb97b5600d99afe3452d707444afda658aca",
	["indent-blankline.nvim"] = "d28a3f70721c79e3c5f6693057ae929f3d9c0a03",
	["lualine.nvim"] = "8811f3f3f4dc09d740c67e9ce399e7a541e2e5b2",
	["mason-lspconfig.nvim"] = "25f609e7fca78af7cede4f9fa3af8a94b1c4950b",
	["mason-tool-installer.nvim"] = "443f1ef8b5e6bf47045cb2217b6f748a223cf7dc",
	["mason.nvim"] = "b03fb0f20bc1d43daf558cda981a2be22e73ac42",
	["mini.comment"] = "8e5ff3ed3cc0e8f216617aae01020c00c20f7a87",
	["mini.files"] = "ced297546b8fdb8e215d416d4753a735514a2fe0",
	["mini.icons"] = "7fdae2443a0e2910015ca39ad74b50524ee682d3",
	["mini.pick"] = "fd7e7efadddcec3f3d7f3b363a99aa44e7286c65",
	["neo-tree.nvim"] = "84c75e7a7e443586f60508d12fc50f90d9aee14e",
	["neogit"] = "5a7fca171e3ad07380745d573d791e95268b8f3f",
	["none-ls-extras.nvim"] = "14fa31ce8c0268a3b2c9cc14979ecf771982d433",
	["none-ls.nvim"] = "7f9301e416533b5d74e2fb3b1ce5059eeaed748b",
	["nui.nvim"] = "de740991c12411b663994b2860f1a4fd0937c130",
	["nvim-autopairs"] = "59bce2eef357189c3305e25bc6dd2d138c1683f5",
	["nvim-bqf"] = "c282a62bec6c0621a1ef5132aa3f4c9fc4dcc2c7",
	["nvim-cmp"] = "a1d504892f2bc56c2e79b65c6faded2fd21f3eca",
	["nvim-colorizer.lua"] = "a065833f35a3a7cc3ef137ac88b5381da2ba302e",
	["nvim-lint"] = "4b03656c09c1561f89b6aa0665c15d292ba9499d",
	["nvim-lspconfig"] = "bedca8b426b2fee0ccac596d167d71bbe971253f",
	["nvim-surround"] = "1098d7b3c34adcfa7feb3289ee434529abd4afd1",
	["nvim-treesitter"] = "cf12346a3414fa1b06af75c79faebe7f76df080a",
	["nvim-treesitter-context"] = "b0c45cefe2c8f7b55fc46f34e563bc428ef99636",
	["nvim-treesitter-textobjects"] = "5ca4aaa6efdcc59be46b95a3e876300cfead05ef",
	["nvim-ts-autotag"] = "8e1c0a389f20bf7f5b0dd0e00306c1247bda2595",
	["nvim-web-devicons"] = "95b7a002d5dba1a42eb58f5fac5c565a485eefd0",
	["oil.nvim"] = "0fcc83805ad11cf714a949c98c605ed717e0b83e",
	["opencode.nvim"] = "fa0a495fa2c229115404cb3c1970578f9c6d2f76",
	["plenary.nvim"] = "b9fd5226c2f76c951fc8ed5923d85e4de065e509",
	["rainbow-delimiters.nvim"] = "aab6caaffd79b8def22ec4320a5344f7c42f58d2",
	["render-markdown.nvim"] = "4ae2f2e8e8c66d070f33cfb57cb6f867e3baf5d9",
	["snacks.nvim"] = "ad9ede6a9cddf16cedbd31b8932d6dcdee9b716e",
	["sqlite.lua"] = "50092d60feb242602d7578398c6eb53b4a8ffe7b",
	["telescope-ui-select.nvim"] = "6e51d7da30bd139a6950adf2a47fda6df9fa06d2",
	["telescope.nvim"] = "a0bbec21143c7bc5f8bb02e0005fa0b982edc026",
	["trouble.nvim"] = "bd67efe408d4816e25e8491cc5ad4088e708a69a",
	["vim-illuminate"] = "0d1e93684da00ab7c057410fecfc24f434698898",
	["vim-tmux-navigator"] = "e41c431a0c7b7388ae7ba341f01a0d217eb3a432",
	["which-key.nvim"] = "3aab2147e74890957785941f0c1ad87d0a44c15a",
}

local function gh(repo, opts)
	opts = opts or {}
	local name = opts.name or repo:match("/([^/]+)$")
	local spec = {
		src = "https://github.com/" .. repo,
	}

	if opts.name then
		spec.name = opts.name
	end

	if pinned_versions[name] then
		spec.version = pinned_versions[name]
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
		{ shell = vim.fn.has("win32") == 1 and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" or "make" },
	},
	["fzf"] = {
		{ load = true, func = function()
			vim.fn["fzf#install"]()
		end },
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
	gh("nvim-treesitter/nvim-treesitter"),
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

vim.pack.add(pack_specs, { confirm = false, load = true })

for _, module_name in ipairs(setup_modules) do
	local module = require(module_name)
	if type(module.setup) == "function" then
		module.setup()
	end
end
