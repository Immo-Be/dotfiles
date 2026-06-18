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
	-- Timeline event lines: make review/thread boundaries easy to scan
	vim.api.nvim_set_hl(0, "OctoTimelineItemHeading", { fg = "#e5c890", bold = true })
	vim.api.nvim_set_hl(0, "OctoTimelineMarker", { fg = "#8caaee", bold = true })
	vim.api.nvim_set_hl(0, "OctoFoldMarker", { fg = "#c6d0f5", bold = true })
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
	vim.api.nvim_set_hl(0, "OctoReviewLine", { bg = "#3b4058" })
	vim.api.nvim_set_hl(0, "OctoThreadLine", { bg = "#333b4f" })
	vim.api.nvim_set_hl(0, "OctoCommentBodyLine", { bg = "#303446" })
	vim.api.nvim_set_hl(0, "OctoReviewBodyLine", { bg = "#34394d" })
	vim.api.nvim_set_hl(0, "OctoReviewBodyAltLine", { bg = "#383d52" })
	vim.api.nvim_set_hl(0, "OctoThreadBodyLine", { bg = "#373c51" })
	vim.api.nvim_set_hl(0, "OctoThreadBodyAltLine", { bg = "#3b4056" })
	vim.api.nvim_set_hl(0, "OctoIssueBodyLine", { bg = "#32374a" })
	vim.api.nvim_set_hl(0, "OctoIssueBodyAltLine", { bg = "#363b50" })
	vim.api.nvim_set_hl(0, "OctoSnippetLine", { bg = "#292c3c" })
	vim.api.nvim_set_hl(0, "OctoSnippetBorder", { fg = "#8caaee", bg = "#292c3c" })
	vim.api.nvim_set_hl(0, "OctoMarkdownLink", { fg = "#8caaee", underline = true })
	vim.api.nvim_set_hl(0, "OctoMarkdownUrl", { fg = "#838ba7", italic = true })
	vim.api.nvim_set_hl(0, "OctoMarkdownInlineCode", { fg = "#ef9f76", bg = "#414559" })
	vim.api.nvim_set_hl(0, "OctoMarkdownCodeLine", { bg = "#292c3c" })
	vim.api.nvim_set_hl(0, "OctoMarkdownCodeBorder", { fg = "#8caaee", bg = "#292c3c" })
	vim.api.nvim_set_hl(0, "OctoMarkdownQuoteLine", { bg = "#33384d" })
	vim.api.nvim_set_hl(0, "OctoMarkdownQuoteMarker", { fg = "#e5c890", bold = true })
	vim.api.nvim_set_hl(0, "OctoMarkdownPriority", { fg = "#232634", bg = "#e5c890", bold = true })
	vim.api.nvim_set_hl(0, "OctoMarkdownHeading", { fg = "#babbf1", bold = true })
	vim.api.nvim_set_hl(0, "OctoMarkdownDivider", { fg = "#51576d" })
	vim.api.nvim_set_hl(0, "OctoMarkdownCallout", { fg = "#232634", bg = "#e5c890", bold = true })
	vim.api.nvim_set_hl(0, "OctoMarkdownSectionA", { bg = "#303446" })
	vim.api.nvim_set_hl(0, "OctoMarkdownSectionB", { bg = "#34384b" })
end

local function is_present(value)
	return value ~= nil and value ~= vim.NIL and value ~= ""
end

local function divider_text()
	local width = math.max(vim.fn.winwidth(0) - 8, 20)
	return string.rep("━", width)
end

local function divider_chunks()
	return { { divider_text(), "OctoOverviewDivider" } }
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
	table.insert(lines, divider_text())
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

		table.insert(details, divider_chunks())
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
		table.insert(details, divider_chunks())

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

local function setup_timeline_visuals()
	if vim.g.octo_timeline_visuals_wrapped then
		return
	end
	vim.g.octo_timeline_visuals_wrapped = true

	local writers = require("octo.ui.writers")
	local config = require("octo.config")
	local constants = require("octo.constants")
	local bubbles = require("octo.ui.bubbles")
	local utils = require("octo.utils")
	local logins = require("octo.logins")
	local ns = vim.api.nvim_create_namespace("octo_timeline_visuals")
	local original_write_comment = writers.write_comment
	local original_write_body_agnostic = writers.write_body_agnostic
	local original_write_thread_snippet = writers.write_thread_snippet
	local thread_headers = {}
	local comment_headers = {}
	local markdown_ns = vim.api.nvim_create_namespace("octo_markdown_visuals")

	local function mark_line(bufnr, line, group)
		if line and line > 0 then
			vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
				line_hl_group = group,
				priority = 20,
			})
		end
	end

	local function mark_range(bufnr, first, last, group)
		if not first or not last then
			return
		end

		for line = first, last do
			mark_line(bufnr, line, group)
		end
	end

	local function timeline_marker()
		return "│"
	end

	local function fold_marker(line)
		if vim.fn.foldlevel(line) == 0 then
			return " "
		end

		return vim.fn.foldclosed(line) == -1 and "▾" or "▸"
	end

	local function chunk_width(chunks)
		local width = 0
		for _, chunk in ipairs(chunks) do
			width = width + vim.fn.strdisplaywidth(chunk[1])
		end
		return width
	end

	local function set_line_overlay(bufnr, line, chunks, group, source_text)
		if line and line > 0 then
			if source_text then
				local padding = vim.fn.strdisplaywidth(source_text) - chunk_width(chunks)
				if padding > 0 then
					table.insert(chunks, { string.rep(" ", padding), "Normal" })
				end
			end

			vim.api.nvim_buf_set_extmark(bufnr, markdown_ns, line - 1, 0, {
				virt_text = chunks,
				virt_text_pos = "overlay",
				hl_mode = "combine",
				line_hl_group = group,
				priority = 70,
			})
		end
	end

	local function set_heading_overlay(bufnr, line, chunks, source_text, group)
		if line and line > 0 then
			local width = math.max(vim.fn.winwidth(0) - 8, 20)
			if source_text then
				local padding = vim.fn.strdisplaywidth(source_text) - chunk_width(chunks)
				if padding > 0 then
					table.insert(chunks, { string.rep(" ", padding), "Normal" })
				end
			end

			vim.api.nvim_buf_set_extmark(bufnr, markdown_ns, line - 1, 0, {
				virt_lines = { { { string.rep("━", width), "OctoMarkdownDivider" } } },
				virt_lines_above = true,
				virt_text = chunks,
				virt_text_pos = "overlay",
				hl_mode = "combine",
				line_hl_group = group,
				priority = 75,
			})
		end
	end

	local function set_section_divider(bufnr, line, group)
		if line and line > 0 then
			local width = math.max(vim.fn.winwidth(0) - 8, 20)
			local text = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or ""
			vim.api.nvim_buf_set_extmark(bufnr, markdown_ns, line - 1, 0, {
				virt_lines = {
					{ { "", "Normal" } },
					{ { string.rep("─", width), "OctoMarkdownDivider" } },
				},
				virt_text = { { string.rep(" ", vim.fn.strdisplaywidth(text)), "Normal" } },
				virt_text_pos = "overlay",
				line_hl_group = group,
				priority = 76,
			})
		end
	end

	local function section_highlight(section, groups)
		groups = groups or { "OctoMarkdownSectionA", "OctoMarkdownSectionB" }
		return section % 2 == 0 and groups[1] or groups[2]
	end

	local function mark_section_line(bufnr, line, group)
		if line and line > 0 then
			vim.api.nvim_buf_set_extmark(bufnr, markdown_ns, line - 1, 0, {
				line_hl_group = group,
				priority = 60,
			})
		end
	end

	local function mark_inline_code(bufnr, line, text)
		local from = 1
		while true do
			local start_col, end_col = text:find("`[^`]+`", from)
			if not start_col then
				break
			end

			vim.api.nvim_buf_set_extmark(bufnr, markdown_ns, line - 1, start_col - 1, {
				end_col = end_col,
				hl_group = "OctoMarkdownInlineCode",
				priority = 90,
			})
			from = end_col + 1
		end
	end

	local function priority_highlight(priority)
		if priority == "high" or priority == "critical" then
			return "OctoBadBubble"
		elseif priority == "medium" then
			return "OctoMarkdownPriority"
		elseif priority == "low" then
			return "OctoInfoBubble"
		end

		return "OctoMetricBubble"
	end

	local function markdown_link_chunks(text, include_url)
		local chunks = {}
		local from = 1
		local changed = false

		while from <= #text do
			local start_col, end_col, label, url = text:find("%[([^%]]+)%]%(([^%)]+)%)", from)
			if not start_col then
				table.insert(chunks, { text:sub(from), "Normal" })
				break
			end

			if start_col > from then
				table.insert(chunks, { text:sub(from, start_col - 1), "Normal" })
			end
			table.insert(chunks, { label, "OctoMarkdownLink" })
			if include_url then
				table.insert(chunks, { " (" .. url:gsub("^https?://", "") .. ")", "OctoMarkdownUrl" })
			else
				table.insert(chunks, { " ↗", "OctoMarkdownUrl" })
			end
			from = end_col + 1
			changed = true
		end

		return changed and chunks or nil
	end

	local function markdown_image_chunks(text)
		local chunks = {}
		local from = 1
		local changed = false

		while from <= #text do
			local start_col, end_col, label = text:find("!%[([^%]]+)%]%([^%)]+%)", from)
			if not start_col then
				table.insert(chunks, { text:sub(from), "Normal" })
				break
			end

			if start_col > from then
				table.insert(chunks, { text:sub(from, start_col - 1), "Normal" })
			end

			table.insert(chunks, { " " .. label .. " ", priority_highlight(label:lower()) })
			from = end_col + 1
			changed = true
		end

		return changed and chunks or nil
	end

	local function inline_markdown_chunks(text, include_url)
		return markdown_image_chunks(text) or markdown_link_chunks(text, include_url) or { { text, "Normal" } }
	end

	local function apply_markdown_visuals(bufnr, first, last, section_groups)
		if not first or not last or last < first then
			return
		end

		vim.api.nvim_buf_clear_namespace(bufnr, markdown_ns, first - 1, last)

		local in_code = false
		local section = 0
		for line = first, last do
			local text = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or ""
			local fence_lang = text:match("^%s*```%s*(%S*)")
			local heading = text:match("^%s*#+%s+(.+)$")
			local section_group = section_highlight(section, section_groups)
			local rule_chars = text:gsub("%s", "")
			local is_horizontal_rule = rule_chars:match("^[-*_]+$") and #rule_chars >= 3

			if fence_lang then
				in_code = not in_code
				local label = fence_lang ~= "" and fence_lang or "code"
				local border = in_code and "╭─ " or "╰─ "
				set_line_overlay(bufnr, line, {
					{ border, "OctoMarkdownCodeBorder" },
					{ label, "OctoTimelineItemHeading" },
				}, "OctoMarkdownCodeLine")
			elseif in_code then
				mark_line(bufnr, line, "OctoMarkdownCodeLine")
			elseif is_horizontal_rule then
				set_section_divider(bufnr, line, section_group)
				section = section + 1
			elseif heading then
				mark_section_line(bufnr, line, section_group)
				set_heading_overlay(bufnr, line, {
					{ " " .. heading .. " ", "OctoMarkdownHeading" },
				}, text, section_group)
			else
				mark_section_line(bufnr, line, section_group)
				local image_chunks = markdown_image_chunks(text)
				if image_chunks then
					set_line_overlay(bufnr, line, image_chunks, section_group, text)
				elseif text:match("^%s*>") then
					local quote = text:gsub("^%s*>%s?", "")
					local callout = quote:match("^%[!(%u+)%]%s*$")
					local quote_chunks = { { "▌ ", "OctoMarkdownQuoteMarker" } }
					if callout then
						table.insert(quote_chunks, { " " .. callout:lower() .. " ", "OctoMarkdownCallout" })
					else
						vim.list_extend(quote_chunks, inline_markdown_chunks(quote, false))
					end
					set_line_overlay(bufnr, line, quote_chunks, section_group, text)
					mark_inline_code(bufnr, line, text)
				else
					local link_chunks = markdown_link_chunks(text, false)
					if link_chunks then
						set_line_overlay(bufnr, line, link_chunks, section_group, text)
					end
					mark_inline_code(bufnr, line, text)
				end
			end
		end
	end

	local function render_comment_header(bufnr, line, opts)
		if not vim.api.nvim_buf_is_valid(bufnr) then
			return
		end

		local comment = opts.comment
		local kind = opts.kind
		local author = comment.author and logins.format_author(comment.author) or { login = "unknown" }
		local heading = "COMMENT"
		local line_group = "OctoReviewLine"

		if kind == "PullRequestReview" then
			heading = "REVIEW"
		elseif kind == "PullRequestReviewComment" then
			heading = "THREAD COMMENT"
			line_group = "OctoThreadLine"
		elseif kind == "PullRequestComment" then
			heading = "COMMENT"
			line_group = "OctoThreadLine"
		elseif kind == "IssueComment" or kind == "DiscussionComment" then
			heading = utils.is_blank(comment.replyTo) and "COMMENT" or "REPLY"
		end

		local header_vt = {
			{ fold_marker(line) .. " ", "OctoFoldMarker" },
			{ timeline_marker() .. " ", "OctoTimelineMarker" },
			{ heading .. "  ", "OctoTimelineItemHeading" },
			{ author.login, comment.viewerDidAuthor and "OctoUserViewer" or "OctoUser" },
			{ "  ", "OctoSymbol" },
		}

		if kind == "PullRequestReview" then
			local state = comment.state
			local state_label = utils.state_msg_map[state] or state
			if state_label then
				vim.list_extend(header_vt, bubbles.make_bubble(state_label:lower(), state_bubble_highlight(state), { right_margin_width = 1 }))
			end
		elseif kind == "PullRequestReviewComment" and comment.state and comment.state ~= "SUBMITTED" then
			vim.list_extend(header_vt, bubbles.make_bubble(comment.state:lower(), state_bubble_highlight(comment.state), { right_margin_width = 1 }))
		end

		table.insert(header_vt, { utils.format_date(comment.createdAt), "OctoDate" })
		if is_present(comment.lastEditedAt) and comment.lastEditedAt ~= comment.createdAt then
			table.insert(header_vt, { "  edited " .. utils.format_date(comment.lastEditedAt), "OctoDate" })
		end

		vim.api.nvim_buf_clear_namespace(bufnr, ns, line - 1, line)
		vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
			virt_text = header_vt,
			virt_text_pos = "overlay",
			hl_mode = "combine",
			line_hl_group = line_group,
			priority = 80,
		})
	end

	local function render_thread_header(bufnr, line, opts)
		if not vim.api.nvim_buf_is_valid(bufnr) then
			return
		end

		local conf = config.values
		local indent = string.rep(" ", conf.timeline_indent)
		local header_vt = {
			{ indent, "Normal" },
			{ fold_marker(line) .. " ", "OctoFoldMarker" },
			{ timeline_marker() .. " ", "OctoTimelineMarker" },
			{ "THREAD  ", "OctoTimelineItemHeading" },
			{ opts.path .. " ", "OctoDetailsLabel" },
			{ tostring(opts.start_line) .. ":" .. tostring(opts.end_line), "OctoDetailsValue" },
			{ "  commit ", "OctoOverviewMuted" },
			{ opts.commit, "OctoDetailsLabel" },
			{ "  ", "OctoSymbol" },
		}

		if opts.isOutdated then
			vim.list_extend(header_vt, bubbles.make_bubble("outdated", "OctoWarnBubble", { right_margin_width = 1 }))
		end

		if opts.isResolved then
			table.insert(header_vt, { "✓", "OctoGreen" })
			if opts.resolvedBy then
				vim.list_extend(header_vt, {
					{ " resolved by ", "OctoOverviewMuted" },
					{ opts.resolvedBy.login, "OctoUser" },
				})
			end
		end

		vim.api.nvim_buf_clear_namespace(bufnr, constants.OCTO_THREAD_HEADER_VT_NS, line - 1, line)
		vim.api.nvim_buf_set_extmark(bufnr, constants.OCTO_THREAD_HEADER_VT_NS, line - 1, 0, {
			virt_text = header_vt,
			virt_text_pos = "overlay",
			hl_mode = "combine",
			line_hl_group = "OctoThreadLine",
		})
	end

	local function update_thread_headers(bufnr)
		for line, opts in pairs(thread_headers[bufnr] or {}) do
			render_thread_header(bufnr, line, opts)
		end
		for line, opts in pairs(comment_headers[bufnr] or {}) do
			render_comment_header(bufnr, line, opts)
		end
	end

	local function ensure_thread_header_updates(bufnr)
		if vim.b[bufnr].octo_thread_header_updates then
			return
		end
		vim.b[bufnr].octo_thread_header_updates = true

		vim.api.nvim_create_autocmd({ "BufWinEnter", "CursorMoved" }, {
			buffer = bufnr,
			callback = function()
				update_thread_headers(bufnr)
			end,
		})

		local pending = false
		local key_ns = vim.api.nvim_create_namespace("octo_thread_header_keys_" .. bufnr)
		vim.on_key(function()
			if vim.api.nvim_get_current_buf() ~= bufnr or pending then
				return
			end
			pending = true
			vim.schedule(function()
				pending = false
				if vim.api.nvim_buf_is_valid(bufnr) then
					update_thread_headers(bufnr)
				end
			end)
		end, key_ns)
	end

	writers.write_body_agnostic = function(bufnr, body, line, viewer_can_update, last_edited_at, includes_created_edit)
		local start_line = line or vim.api.nvim_buf_line_count(bufnr) + 1
		original_write_body_agnostic(bufnr, body, line, viewer_can_update, last_edited_at, includes_created_edit)

		body = utils.trim(body)
		if vim.startswith(body, constants.NO_BODY_MSG) or utils.is_blank(body) then
			body = " "
		end

		local description = body:gsub("\r\n", "\n")
		local lines = vim.split(description, "\n", { plain = true })
		vim.list_extend(lines, { "" })
		apply_markdown_visuals(bufnr, start_line, start_line + #lines - 1)
	end

	writers.write_comment = function(bufnr, comment, kind, line)
		local start_line, end_line = original_write_comment(bufnr, comment, kind, line)
		if not start_line then
			return start_line, end_line
		end

		if kind == "PullRequestReview" then
			comment_headers[bufnr] = comment_headers[bufnr] or {}
			comment_headers[bufnr][start_line] = { comment = comment, kind = kind }
			render_comment_header(bufnr, start_line, comment_headers[bufnr][start_line])
			mark_line(bufnr, start_line, "OctoReviewLine")
			mark_range(bufnr, start_line + 1, end_line, "OctoReviewBodyLine")
			apply_markdown_visuals(bufnr, start_line + 1, end_line, { "OctoReviewBodyLine", "OctoReviewBodyAltLine" })
		elseif kind == "PullRequestReviewComment" or kind == "PullRequestComment" then
			comment_headers[bufnr] = comment_headers[bufnr] or {}
			comment_headers[bufnr][start_line] = { comment = comment, kind = kind }
			render_comment_header(bufnr, start_line, comment_headers[bufnr][start_line])
			mark_line(bufnr, start_line, "OctoThreadLine")
			mark_range(bufnr, start_line + 1, end_line, "OctoThreadBodyLine")
			apply_markdown_visuals(bufnr, start_line + 1, end_line, { "OctoThreadBodyLine", "OctoThreadBodyAltLine" })
		elseif kind == "IssueComment" or kind == "DiscussionComment" then
			comment_headers[bufnr] = comment_headers[bufnr] or {}
			comment_headers[bufnr][start_line] = { comment = comment, kind = kind }
			render_comment_header(bufnr, start_line, comment_headers[bufnr][start_line])
			mark_line(bufnr, start_line, "OctoReviewLine")
			mark_range(bufnr, start_line + 1, end_line, "OctoIssueBodyLine")
			apply_markdown_visuals(bufnr, start_line + 1, end_line, { "OctoIssueBodyLine", "OctoIssueBodyAltLine" })
		end

		ensure_thread_header_updates(bufnr)
		vim.schedule(function()
			update_thread_headers(bufnr)
		end)

		return start_line, end_line
	end

	writers.write_review_thread_header = function(bufnr, opts, line)
		local header_line = (line or vim.api.nvim_buf_line_count(bufnr) - 1) + 2
		thread_headers[bufnr] = thread_headers[bufnr] or {}
		thread_headers[bufnr][header_line] = opts

		writers.write_block(bufnr, { "" })
		render_thread_header(bufnr, header_line, opts)
		mark_line(bufnr, header_line, "OctoThreadLine")
		ensure_thread_header_updates(bufnr)

		vim.schedule(function()
			update_thread_headers(bufnr)
		end)
	end

	writers.write_thread_snippet = function(bufnr, diffhunk, diffhunk_lang, start_line, comment_start, comment_end, comment_side)
		local snippet_start, snippet_end =
			original_write_thread_snippet(bufnr, diffhunk, diffhunk_lang, start_line, comment_start, comment_end, comment_side)

		if snippet_start and snippet_end and snippet_end >= snippet_start then
			mark_range(bufnr, snippet_start, snippet_end, "OctoSnippetLine")
			mark_line(bufnr, snippet_start, "OctoSnippetBorder")
			mark_line(bufnr, snippet_end, "OctoSnippetBorder")
		end

		return snippet_start, snippet_end
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
		timeline_marker    = "│",

		-- ── Changed-files panel ───────────────────────────────────────────────
		file_panel = {
			size  = 10,
			icons = true, -- requires nvim-web-devicons or mini.icons
		},
	})
	setup_compact_octo_details()
	setup_timeline_visuals()
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
