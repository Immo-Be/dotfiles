-- nvim-bqf: Better quickfix window
-- https://github.com/kevinhwang91/nvim-bqf
return {
	"kevinhwang91/nvim-bqf",
	ft = "qf",
	dependencies = {
		{
			"junegunn/fzf",
			run = function()
				vim.fn["fzf#install"]()
			end,
		},
		{ "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" },
	},
	opts = {
		-- auto_enable = true,
		-- auto_resize_height = true, -- recommended
		-- preview = {
		--     auto_preview = true,
		--     win_height = 15,
		--     border = "rounded",
		-- },
		-- func_map = {
		--     drop = "o",
		--     split = "<C-s>",
		--     tabdrop = "<C-t>",
		-- },
		-- filter = {
		--     fzf = {
		--         action_for = {
		--             ["ctrl-s"] = "split",
		--             ["ctrl-t"] = "tab drop",
		--         },
		--         extra_opts = { "--bind", "ctrl-o:toggle-all", "--prompt", "> " },
		--     },
		-- },
	},
	config = function(_, opts)
		require("bqf").setup(opts)
	end,
}
