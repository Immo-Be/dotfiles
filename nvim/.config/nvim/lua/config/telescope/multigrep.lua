local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local M = {}

-- Custom action: Open file in new vertical split on the right
local open_in_left_split = function(prompt_bufnr)
	local entry = action_state.get_selected_entry()
	actions.close(prompt_bufnr)
	
	-- Create a vertical split on the right
	vim.cmd("rightbelow vsplit")
	
	-- Open the selected file at the correct line (for grep results) in the new right split
	if entry.path or entry.filename then
		local file = entry.path or entry.filename
		local lnum = entry.lnum or 1
		local col = entry.col or 1
		vim.cmd("edit +" .. lnum .. " " .. vim.fn.fnameescape(file))
		vim.api.nvim_win_set_cursor(0, { lnum, col - 1 })
	end
end

-- Custom action: Open file in new horizontal split below
local open_in_horizontal_split = function(prompt_bufnr)
	local entry = action_state.get_selected_entry()
	actions.close(prompt_bufnr)
	
	-- Create a horizontal split below
	vim.cmd("rightbelow split")
	
	-- Open the selected file at the correct line (for grep results) in the new bottom split
	if entry.path or entry.filename then
		local file = entry.path or entry.filename
		local lnum = entry.lnum or 1
		local col = entry.col or 1
		vim.cmd("edit +" .. lnum .. " " .. vim.fn.fnameescape(file))
		vim.api.nvim_win_set_cursor(0, { lnum, col - 1 })
	end
end

-- Custom action: Open file in vertical split (replaces current window)
local open_in_vsplit_current = function(prompt_bufnr)
	local entry = action_state.get_selected_entry()
	actions.close(prompt_bufnr)
	
	-- Split current window vertically
	vim.cmd("vsplit")
	
	-- Open the selected file at the correct line (for grep results) in the new split
	if entry.path or entry.filename then
		local file = entry.path or entry.filename
		local lnum = entry.lnum or 1
		local col = entry.col or 1
		vim.cmd("edit +" .. lnum .. " " .. vim.fn.fnameescape(file))
		vim.api.nvim_win_set_cursor(0, { lnum, col - 1 })
	end
end

local live_multigrep = function(opts)
	opts = opts or {}
	opts.cwd = opts.cwd or vim.uv.cwd()

	local finder = finders.new_async_job({
		command_generator = function(prompt)
			if not prompt or prompt == "" then
				return nil
			end

			local pieces = vim.split(prompt, "  ")
			local args = { "rg" }
			if pieces[1] then
				table.insert(args, "-e")
				table.insert(args, pieces[1])
			end

			if pieces[2] then
				table.insert(args, "-g")
				table.insert(args, pieces[2])
			end

			---@diagnostic disable-next-line: deprecated
			return vim.tbl_flatten({
				args,
				{ "--color=never", "--no-heading", "--with-filename", "--line-number", "--column", "--smart-case" },
			})
		end,
		entry_maker = make_entry.gen_from_vimgrep(opts),
		cwd = opts.cwd,
	})

	pickers
		.new(opts, {
			debounce = 100,
			prompt_title = "Multi Grep",
			finder = finder,
			default_text = opts.default_text or "",
			previewer = conf.grep_previewer(opts),
			sorter = require("telescope.sorters").empty(),
			attach_mappings = function(_, map)
				map("i", "<Up>", actions.cycle_history_prev)
				map("i", "<Down>", actions.cycle_history_next)
				-- Only map 'l', 'h', 'v' in normal mode, not insert mode (allow typing normally)
				map("n", "l", open_in_left_split)
				map("n", "h", open_in_horizontal_split)
				map("n", "v", open_in_vsplit_current)
				return true
			end,
		})
		:find()
end

M.setup = function()
	vim.keymap.set("n", "<leader>g", function()
		live_multigrep({ default_text = vim.fn.expand("<cword>") })
	end)
end

return M