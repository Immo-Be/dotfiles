local M = {}

local opts = {
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
}

function M.setup()
	require("bqf").setup(opts)
end

return M
