local M = {}

local lazy_commands = {
	"Myprs",
	"Allprs",
	"OctoProjectDashboard",
	"OctoProjectDefaultSet",
	"OctoProjectDefaultClear",
	"OctoProjectDefaultShow",
}

local placeholder_commands = vim.list_extend({ "Octo" }, vim.deepcopy(lazy_commands))

local loading = false
local loaded = false

local function ensure_loaded()
	if loaded then
		return true
	end
	if loading then
		return false
	end

	loading = true
	for _, command in ipairs(placeholder_commands) do
		pcall(vim.api.nvim_del_user_command, command)
	end

	local ok, err = xpcall(function()
		vim.cmd.packadd("octo.nvim")
		require("plugins.octo").setup()
	end, debug.traceback)
	loading = false
	loaded = ok

	if not ok then
		vim.notify("Could not load Octo:\n" .. err, vim.log.levels.ERROR)
	end
	return ok
end

local function run_octo(command)
	return function()
		if ensure_loaded() then
			vim.cmd("Octo " .. command)
		end
	end
end

local function run_command(command)
	return function()
		if ensure_loaded() then
			vim.cmd(command)
		end
	end
end

function M.setup()
	vim.api.nvim_create_user_command("Octo", function(opts)
		if not ensure_loaded() then
			return
		end
		local command = { cmd = "Octo", args = opts.fargs }
		if opts.bang then
			command.bang = true
		end
		if opts.range > 0 then
			command.range = { opts.line1, opts.line2 }
		end
		vim.api.nvim_cmd(command, {})
	end, {
		nargs = "*",
		bang = true,
		range = true,
		desc = "Load Octo and run an Octo command",
	})

	vim.keymap.set("n", "<leader>Ha", run_octo("actions"), { desc = "Octo actions", silent = true })
	vim.keymap.set("n", "<leader>Hi", run_octo("issue list"), { desc = "Octo list issues", silent = true })
	vim.keymap.set("n", "<leader>HI", run_octo("issue create"), { desc = "Octo create issue", silent = true })
	vim.keymap.set("n", "<leader>Hp", run_octo("pr list"), { desc = "Octo list PRs", silent = true })
	vim.keymap.set("n", "<leader>HP", run_octo("pr create"), { desc = "Octo create PR", silent = true })
	vim.keymap.set("n", "<leader>Hc", run_octo("pr checkout"), { desc = "Octo checkout PR", silent = true })
	vim.keymap.set("n", "<leader>Hd", run_octo("pr diffview"), { desc = "Octo PR diff in Diffview", silent = true })
	vim.keymap.set("n", "<leader>Hn", run_octo("notification list"), { desc = "Octo list notifications", silent = true })
	vim.keymap.set("n", "<leader>Hb", run_command("OctoProjectDashboard"), { desc = "GitHub project dashboard", silent = true })
	vim.keymap.set("n", "<leader>Hr", run_octo("review start"), { desc = "Octo start review", silent = true })
	vim.keymap.set("n", "<leader>HR", run_octo("review resume"), { desc = "Octo resume review", silent = true })
	vim.keymap.set("n", "<leader>Hq", run_octo("review close"), { desc = "Octo close review", silent = true })
	vim.keymap.set("n", "<leader>Hs", function()
		if ensure_loaded() then
			require("octo.utils").create_base_search_command({ include_current_repo = true })
		end
	end, { desc = "Octo search current repo", silent = true })

	for _, command in ipairs(lazy_commands) do
		vim.api.nvim_create_user_command(command, run_command(command), {
			desc = "Load Octo and run " .. command,
		})
	end
end

return M
