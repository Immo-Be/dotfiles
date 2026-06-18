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

-- Set highlight overrides BEFORE octo.setup() so octo doesn't clobber them
-- (octo only defines groups that don't already exist).
-- All hex values are from the Catppuccin Frappe palette.
local function setup_highlights()
	-- PR/issue title: lavender + bold, prominent like GitHub's h1
	vim.api.nvim_set_hl(0, "OctoIssueTitle", { fg = "#babbf1", bold = true })
	-- Sidebar metadata labels (Reviewers, Assignees, Labels…): muted subtext
	vim.api.nvim_set_hl(0, "OctoDetailsLabel", { fg = "#a5adce", bold = true })
	-- Timestamps: dimmer than regular comment text
	vim.api.nvim_set_hl(0, "OctoDate", { fg = "#737994", italic = true })
	-- Timeline event lines (e.g. "user merged commit …"): keep subtle
	vim.api.nvim_set_hl(0, "OctoTimelineItemHeading", { fg = "#737994" })
	-- Separator/symbol glyphs between metadata items
	vim.api.nvim_set_hl(0, "OctoSymbol", { fg = "#626880" })
	-- Editable regions: faint surface tint so input areas read as "writable"
	vim.api.nvim_set_hl(0, "OctoEditable", { bg = "#414559" })
	vim.api.nvim_set_hl(0, "OctoOverviewAccent", { fg = "#a6d189", bold = true })
	vim.api.nvim_set_hl(0, "OctoOverviewMuted", { fg = "#838ba7" })
	vim.api.nvim_set_hl(0, "OctoOverviewDivider", { fg = "#51576d" })
	vim.api.nvim_set_hl(0, "OctoBranchHead", { fg = "#f2d5cf", bold = true })
	vim.api.nvim_set_hl(0, "OctoBranchBase", { fg = "#8caaee", bold = true })
	vim.api.nvim_set_hl(0, "OctoGoodBubble", { fg = "#232634", bg = "#a6d189", bold = true })
	vim.api.nvim_set_hl(0, "OctoWarnBubble", { fg = "#232634", bg = "#e5c890", bold = true })
	vim.api.nvim_set_hl(0, "OctoBadBubble", { fg = "#232634", bg = "#e78284", bold = true })
	vim.api.nvim_set_hl(0, "OctoInfoBubble", { fg = "#232634", bg = "#8caaee", bold = true })
	vim.api.nvim_set_hl(0, "OctoMetricBubble", { fg = "#c6d0f5", bg = "#414559" })
end

local function is_present(value)
	return value ~= nil and value ~= vim.NIL and value ~= ""
end

local function add_labels(chunks, labels, bubbles)
	if labels and labels.nodes and #labels.nodes > 0 then
		for _, label in ipairs(labels.nodes) do
			if label ~= vim.NIL then
				vim.list_extend(chunks, bubbles.make_label_bubble(label.name, label.color, { right_margin_width = 3 }))
			end
		end
	else
		table.insert(chunks, { "No labels", "OctoMissingDetails" })
	end
end

local function add_chip(chunks, bubbles, text, highlight)
	vim.list_extend(chunks, bubbles.make_bubble(text, highlight, { right_margin_width = 3, padding_width = 1 }))
end

local function state_bubble_highlight(state)
	if not is_present(state) then
		return "OctoMetricBubble"
	end

	if state == "SUCCESS" or state == "APPROVED" or state == "CLEAN" or state == "MERGEABLE" then
		return "OctoGoodBubble"
	elseif state == "PENDING" or state == "EXPECTED" or state == "REVIEW_REQUIRED" or state == "UNKNOWN" then
		return "OctoWarnBubble"
	elseif state == "FAILURE" or state == "ERROR" or state == "CHANGES_REQUESTED" or state == "DIRTY" or state == "BLOCKED" then
		return "OctoBadBubble"
	end

	return "OctoInfoBubble"
end

local function user_names(users)
	local names = {}
	if users and users.nodes then
		for _, user in ipairs(users.nodes) do
			if user ~= vim.NIL then
				table.insert(names, user.login or user.name)
			end
		end
	end

	return #names > 0 and table.concat(names, ", ") or "None"
end

local function subscription_label(subscription_state)
	if subscription_state == "IGNORED" then
		return "Never"
	elseif subscription_state == "SUBSCRIBED" then
		return "All activity"
	elseif subscription_state == "UNSUBSCRIBED" then
		return "Only participating and @mentioned"
	end
end

local function add_metadata_line(lines, label, value)
	if is_present(value) then
		table.insert(lines, string.format("%-13s %s", label .. ":", value))
	end
end

local function more_metadata_lines(issue, is_pr, utils)
	local lines = {
		"<details>",
		"<summary>More metadata</summary>",
		"",
	}
	local repo = select(2, utils.parse_url(issue.url))

	add_metadata_line(lines, "Repo", repo)

	if is_present(issue.lastEditedAt) and issue.lastEditedAt ~= issue.createdAt then
		add_metadata_line(lines, "Edited", utils.format_date(issue.lastEditedAt))
	end

	if issue.state == "CLOSED" then
		add_metadata_line(lines, "Closed", utils.format_date(issue.closedAt))
	end

	add_metadata_line(lines, "Assignees", user_names(issue.assignees))

	local milestone = issue.milestone
	if milestone ~= nil and milestone ~= vim.NIL then
		local milestone_state = utils.state_message_map[milestone.state] or milestone.state
		add_metadata_line(lines, "Milestone", milestone.title .. " (" .. milestone_state .. ")")
	else
		add_metadata_line(lines, "Milestone", "None")
	end

	if is_pr then
		if issue.closingIssuesReferences and issue.closingIssuesReferences.totalCount > 0 then
			local linked = {}
			for _, closing_issue in ipairs(issue.closingIssuesReferences.nodes) do
				if closing_issue ~= vim.NIL then
					table.insert(linked, "#" .. tostring(closing_issue.number) .. " " .. closing_issue.title)
				end
			end
			add_metadata_line(lines, "Development", table.concat(linked, ", "))
		else
			add_metadata_line(lines, "Development", "None yet")
		end

		if issue.autoMergeRequest and issue.autoMergeRequest ~= vim.NIL then
			add_metadata_line(
				lines,
				"Auto-merge",
				string.format(
					"Enabled by %s (%s)",
					issue.autoMergeRequest.enabledBy.login,
					utils.auto_merge_method_map[issue.autoMergeRequest.mergeMethod]
				)
			)
		end
	end

	add_metadata_line(lines, "Subscribed", subscription_label(issue.viewerSubscription))

	table.insert(lines, "")
	table.insert(lines, "</details>")
	table.insert(lines, "")

	return lines
end

local function make_reviewers(issue, utils, logins)
	local reviewers = {}

	local function collect_reviewer(name, state)
		if not is_present(name) or not is_present(state) then
			return
		end

		reviewers[name] = reviewers[name] or {}
		if not vim.tbl_contains(reviewers[name], state) then
			table.insert(reviewers[name], state)
		end
	end

	if issue.timelineItems and issue.timelineItems.nodes then
		for _, item in ipairs(issue.timelineItems.nodes) do
			if item ~= vim.NIL and item.__typename == "PullRequestReview" and item.author then
				collect_reviewer(item.author.login, item.state)
			end
		end
	end

	if issue.reviewRequests and issue.reviewRequests.nodes then
		for _, request in ipairs(issue.reviewRequests.nodes) do
			local requested = request ~= vim.NIL and request.requestedReviewer
			if requested and requested ~= vim.NIL then
				collect_reviewer(requested.login or requested.name, "REVIEW_REQUIRED")
			end
		end
	end

	local chunks = {}
	local names = vim.tbl_keys(reviewers)
	table.sort(names)

	if #names == 0 then
		table.insert(chunks, { "None", "OctoMissingDetails" })
		return chunks
	end

	for _, name in ipairs(names) do
		local strongest_review = utils.calculate_strongest_review_state(reviewers[name])
		local formatted = logins.format_author({ login = name }).login
		table.insert(chunks, { formatted, "OctoUser" })
		table.insert(chunks, { utils.state_icon_map[strongest_review], utils.state_hl_map[strongest_review] })
		table.insert(chunks, { " " })
	end

	return chunks
end

local function setup_compact_octo_details()
	local writers = require("octo.ui.writers")
	local constants = require("octo.constants")
	local utils = require("octo.utils")
	local bubbles = require("octo.ui.bubbles")
	local logins = require("octo.logins")
	local folds = require("octo.folds")

	writers.write_details = function(bufnr, issue, update, include_status)
		vim.api.nvim_buf_clear_namespace(bufnr, constants.OCTO_DETAILS_VT_NS, 0, -1)

		local is_pr = issue.commits ~= nil
		local details = {}
		local author = issue.author and logins.format_author(issue.author) or { login = "unknown" }

		if include_status then
			local status = utils.get_displayed_state(not is_pr, issue.state, issue.stateReason, issue.isDraft)
			table.insert(details, {
				{ "▌ ", "OctoOverviewAccent" },
				{ status:lower(), utils.state_hl_map[status] or "OctoDetailsValue" },
			})
		end

		table.insert(details, {
			{ "────────────────────────────────────────────────────────────", "OctoOverviewDivider" },
		})
		table.insert(details, {})

		if is_pr then
			table.insert(details, {
				{ "branch  ", "OctoDetailsLabel" },
				{ issue.headRefName or "", "OctoBranchHead" },
				{ "    →    ", "OctoSymbol" },
				{ issue.baseRefName or "", "OctoBranchBase" },
			})
			table.insert(details, {})
		end

		if is_pr then
			local health = {}

			if issue.reviewDecision and issue.reviewDecision ~= vim.NIL then
				local review = utils.state_message_map[issue.reviewDecision] or issue.reviewDecision
				add_chip(health, bubbles, "review " .. review:lower(), state_bubble_highlight(issue.reviewDecision))
			end

			if issue.statusCheckRollup and issue.statusCheckRollup ~= vim.NIL then
				local state = issue.statusCheckRollup.state
				local state_info = utils.state_map[state]
				if state_info then
					add_chip(health, bubbles, "checks " .. state:lower(), state_bubble_highlight(state))
				end
			end

			if not issue.merged and issue.mergeable then
				if issue.mergeable == "MERGEABLE" then
					local merge_state = utils.merge_state_message_map[issue.mergeStateStatus] or issue.mergeStateStatus
					add_chip(health, bubbles, "merge " .. merge_state:lower(), state_bubble_highlight(issue.mergeStateStatus))
				else
					local mergeable = utils.mergeable_message_map[issue.mergeable] or issue.mergeable
					add_chip(health, bubbles, "merge " .. mergeable:lower(), state_bubble_highlight(issue.mergeable))
				end
			end

			if #health > 0 then
				table.insert(details, health)
				table.insert(details, {})
			end

			local changes = {}
			add_chip(changes, bubbles, tostring(issue.commits.totalCount) .. " commits", "OctoMetricBubble")
			add_chip(changes, bubbles, tostring(issue.changedFiles) .. " files", "OctoMetricBubble")
			table.insert(changes, { string.format("+%d ", issue.additions), "OctoDiffstatAdditions" })
			table.insert(changes, { string.format("-%d ", issue.deletions), "OctoDiffstatDeletions" })

			local diffstat = utils.diffstat({ additions = issue.additions, deletions = issue.deletions })
			if diffstat.additions > 0 then
				table.insert(changes, { string.rep("■", diffstat.additions), "OctoDiffstatAdditions" })
			end
			if diffstat.deletions > 0 then
				table.insert(changes, { string.rep("■", diffstat.deletions), "OctoDiffstatDeletions" })
			end
			if diffstat.neutral > 0 then
				table.insert(changes, { string.rep("■", diffstat.neutral), "OctoDiffstatNeutral" })
			end
			table.insert(details, changes)
		end

		table.insert(details, {})

		local overview = {
			{ "opened by ", "OctoOverviewMuted" },
			{ author.login, issue.viewerDidAuthor and "OctoUserViewer" or "OctoUser" },
			{ "   ·   ", "OctoSymbol" },
			{ utils.format_date(issue.createdAt), "OctoDate" },
		}
		if is_present(issue.updatedAt) then
			vim.list_extend(overview, {
				{ "   ·   updated ", "OctoOverviewMuted" },
				{ utils.format_date(issue.updatedAt), "OctoDate" },
			})
		end
		table.insert(details, overview)

		if is_pr then
			local reviewers = { { "reviewed by  ", "OctoDetailsLabel" } }
			vim.list_extend(reviewers, make_reviewers(issue, utils, logins))
			table.insert(details, reviewers)
		end

		local labels = { { "labels  ", "OctoDetailsLabel" } }
		add_labels(labels, issue.labels, bubbles)
		table.insert(details, labels)

		table.insert(details, {})
		table.insert(details, {
			{ "────────────────────────────────────────────────────────────", "OctoOverviewDivider" },
		})

		local line = 3
		if not update then
			local empty_lines = {}
			for _ = 1, #details + 1 do
				table.insert(empty_lines, "")
			end
			local more_lines = more_metadata_lines(issue, is_pr, utils)
			vim.list_extend(empty_lines, more_lines)

			writers.write_block(bufnr, empty_lines, line)

			local fold_start = line + #details + 1
			local fold_end = fold_start + #more_lines - 1
			pcall(folds.create_details_folds, bufnr, fold_start, fold_end)
		end

		for _, chunks in ipairs(details) do
			writers.write_virtual_text(bufnr, constants.OCTO_DETAILS_VT_NS, line - 1, chunks)
			line = line + 1
		end
	end
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
	setup_highlights()

	require("octo").setup({
		picker = "default",
		enable_builtin = true,
		users = "assignable",
		commands = {
			pr = {
				diffview = open_pr_diffview,
			},
		},

		-- ── UI chrome ────────────────────────────────────────────────────────
		ui = {
			use_signcolumn   = false,
			use_statuscolumn = true, -- editable-region markers in the status column
			use_foldtext     = true, -- custom fold text for collapsed sections
		},

		-- ── Color palette (Catppuccin Frappe–tuned) ───────────────────────────
		-- Only the values that differ meaningfully from the defaults are listed;
		-- the rest inherit from octo's built-in palette.
		colors = {
			-- Softer off-white instead of pure #ffffff – less glaring on a dark theme
			white       = "#c6d0f5", -- frappe: text
			-- The default #2A354C is almost identical to Frappe's base background,
			-- making draft labels, grey bubbles, and muted text nearly invisible.
			-- GitHub uses #6e7681 for their own muted/secondary text.
			grey        = "#6e7681",
			-- GitHub merge purple is noticeably brighter than the default #6f42c1.
			-- Catppuccin mauve sits right in that range and fits the palette.
			purple      = "#ca9ee6", -- frappe: mauve
			-- Harmonise yellow and blue with the rest of the Frappe palette
			yellow      = "#e5c890", -- frappe: yellow  (replaces #d3c846)
			dark_yellow = "#df8e1d", -- frappe: yellow (saturated variant for backgrounds)
			blue        = "#8caaee", -- frappe: blue    (replaces #58A6FF)
		},

		-- ── Timeline ─────────────────────────────────────────────────────────
		use_timeline_icons = true,
		timeline_indent    = 2,

		-- ── Changed-files panel ───────────────────────────────────────────────
		file_panel = {
			size  = 10,
			icons = true, -- requires nvim-web-devicons or mini.icons
		},
	})
	setup_compact_octo_details()
	setup_cmp_completion()

	vim.keymap.set("n", "<leader>Ha", octo("actions"), { desc = "Octo actions", silent = true })
	vim.keymap.set("n", "<leader>Hi", octo("issue list"), { desc = "Octo list issues", silent = true })
	vim.keymap.set("n", "<leader>HI", octo("issue create"), { desc = "Octo create issue", silent = true })
	vim.keymap.set("n", "<leader>Hp", octo("pr list"), { desc = "Octo list PRs", silent = true })
	vim.keymap.set("n", "<leader>HP", octo("pr create"), { desc = "Octo create PR", silent = true })
	vim.keymap.set("n", "<leader>Hc", octo("pr checkout"), { desc = "Octo checkout PR", silent = true })
	vim.keymap.set("n", "<leader>Hd", octo("pr diffview"), { desc = "Octo PR diff in Diffview", silent = true })
	vim.keymap.set("n", "<leader>Hn", octo("notification list"), { desc = "Octo list notifications", silent = true })
	vim.keymap.set("n", "<leader>Hr", octo("review start"), { desc = "Octo start review", silent = true })
	vim.keymap.set("n", "<leader>HR", octo("review resume"), { desc = "Octo resume review", silent = true })
	vim.keymap.set("n", "<leader>Hq", octo("review close"), { desc = "Octo close review", silent = true })
	vim.keymap.set("n", "<leader>Hs", function()
		require("octo.utils").create_base_search_command({ include_current_repo = true })
	end, { desc = "Octo search current repo", silent = true })
end

return M
