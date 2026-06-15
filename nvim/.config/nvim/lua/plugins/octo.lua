local M = {}

local function octo(command)
	return function()
		vim.cmd("Octo " .. command)
	end
end

local function git_stdout(args)
	local result = vim.system(vim.list_extend({ "git" }, args), { text = true }):wait()
	if result.code ~= 0 then
		return nil
	end

	return vim.trim(result.stdout or "")
end

local function git_ref_exists(ref)
	local result = vim.system({ "git", "rev-parse", "--verify", "--quiet", ref .. "^{commit}" }):wait()
	return result.code == 0
end

local function normalize_github_remote(url)
	local normalized = url:gsub("%.git$", "")
	normalized = normalized:gsub("^git@[^:]+:", "")
	normalized = normalized:gsub("^https://[^/]+/", "")
	normalized = normalized:gsub("^ssh://git@[^/]+/", "")
	return normalized
end

local function find_remote(repo)
	local remotes = vim.split(git_stdout({ "remote", "-v" }) or "", "\n", { trimempty = true })
	for _, line in ipairs(remotes) do
		local name, url = line:match("^(%S+)%s+(%S+)")
		if name and url and normalize_github_remote(url) == repo then
			return name
		end
	end

	return "origin"
end

local function resolve_branch_ref(remote, branch, oid)
	if branch and branch ~= vim.NIL then
		local remote_ref = "refs/remotes/" .. remote .. "/" .. branch
		if git_ref_exists(remote_ref) then
			return remote .. "/" .. branch
		end

		local local_ref = "refs/heads/" .. branch
		if git_ref_exists(local_ref) then
			return branch
		end
	end

	if oid and oid ~= vim.NIL and git_ref_exists(oid) then
		return oid
	end
end

local function setup_cmp_completion()
	local ok, cmp = pcall(require, "cmp")
	if not ok or vim.g.octo_cmp_source_registered then
		return
	end

	local source = {}

	function source:is_available()
		return vim.bo.filetype == "octo" and type(_G.octo_omnifunc) == "function"
	end

	function source:get_trigger_characters()
		return { "@", "#" }
	end

	function source:get_keyword_pattern()
		return [[\%(@[[:alnum:]_-]*\|#\d*\)]]
	end

	function source:complete(params, callback)
		local before_cursor = params.context.cursor_before_line
		local base = before_cursor:match("(@[%w_-]*)$") or before_cursor:match("(#%d*)$")
		if not base then
			callback({})
			return
		end

		local ok_items, items = pcall(_G.octo_omnifunc, 0, base)
		if not ok_items or type(items) ~= "table" then
			callback({})
			return
		end

		local completion_items = {}
		for _, item in ipairs(items) do
			table.insert(completion_items, {
				label = item.word,
				insertText = item.word,
				detail = item.menu,
				documentation = item.abbr,
			})
		end

		callback(completion_items)
	end

	cmp.register_source("octo", source)

	local sources = vim.tbl_filter(function(source_config)
		return source_config.name ~= "octo"
	end, cmp.get_config().sources or {})

	cmp.setup({
		sources = cmp.config.sources({
			{ name = "octo", priority = 1100, keyword_length = 0 },
		}, sources),
	})

	vim.g.octo_cmp_source_registered = true
end

local function open_pr_diffview()
	local utils = require("octo.utils")
	local buffer = utils.get_current_buffer()
	if not buffer or not buffer:isPullRequest() then
		vim.notify("Open an Octo PR buffer first", vim.log.levels.WARN)
		return
	end

	local pr = buffer:pullRequest()
	local base_repo = pr.baseRepository and pr.baseRepository.nameWithOwner or buffer.repo
	local head_repo = pr.headRepository and pr.headRepository ~= vim.NIL and pr.headRepository.nameWithOwner or base_repo
	local base_remote = find_remote(base_repo)
	local head_remote = find_remote(head_repo)
	local base = resolve_branch_ref(base_remote, pr.baseRefName, pr.baseRefOid)
	local head = resolve_branch_ref(head_remote, pr.headRefName, pr.headRefOid)

	if not base or not head then
		vim.notify("Could not resolve PR base/head refs locally. Fetch the PR branch and try again.", vim.log.levels.ERROR)
		return
	end

	vim.cmd("DiffviewOpen " .. vim.fn.fnameescape(base) .. "..." .. vim.fn.fnameescape(head))
end

function M.setup()
	require("octo").setup({
		picker = "default",
		enable_builtin = true,
		users = "assignable",
		commands = {
			pr = {
				diff = open_pr_diffview,
			},
		},
	})
	setup_cmp_completion()

	vim.keymap.set("n", "<leader>Ha", octo("actions"), { desc = "Octo actions", silent = true })
	vim.keymap.set("n", "<leader>Hi", octo("issue list"), { desc = "Octo list issues", silent = true })
	vim.keymap.set("n", "<leader>HI", octo("issue create"), { desc = "Octo create issue", silent = true })
	vim.keymap.set("n", "<leader>Hp", octo("pr list"), { desc = "Octo list PRs", silent = true })
	vim.keymap.set("n", "<leader>HP", octo("pr create"), { desc = "Octo create PR", silent = true })
	vim.keymap.set("n", "<leader>Hc", octo("pr checkout"), { desc = "Octo checkout PR", silent = true })
	vim.keymap.set("n", "<leader>Hd", open_pr_diffview, { desc = "Octo PR diff in Diffview", silent = true })
	vim.keymap.set("n", "<leader>Hn", octo("notification list"), { desc = "Octo list notifications", silent = true })
	vim.keymap.set("n", "<leader>Hr", octo("review start"), { desc = "Octo start review", silent = true })
	vim.keymap.set("n", "<leader>HR", octo("review resume"), { desc = "Octo resume review", silent = true })
	vim.keymap.set("n", "<leader>Hq", octo("review close"), { desc = "Octo close review", silent = true })
	vim.keymap.set("n", "<leader>Hs", function()
		require("octo.utils").create_base_search_command({ include_current_repo = true })
	end, { desc = "Octo search current repo", silent = true })
end

return M
