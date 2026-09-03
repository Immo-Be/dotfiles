local M = {}

local notification_timer
local notification_poll_running = false
local notification_baseline_ready = false
local notification_versions = {}
local notification_last_error

local function decode_notification_pages(data)
	local ok, pages = pcall(vim.json.decode, data)
	if not ok or type(pages) ~= "table" then
		return nil
	end
	local notifications = {}
	for _, page in ipairs(pages) do
		if vim.islist(page) then
			vim.list_extend(notifications, page)
		end
	end
	return notifications
end

local function notification_message(notification)
	local repo = vim.tbl_get(notification, "repository", "full_name") or "GitHub"
	local subject = notification.subject or {}
	local reason_labels = {
		assign = "assigned",
		author = "activity",
		comment = "new comment",
		invitation = "invitation",
		manual = "subscribed",
		mention = "mentioned",
		review_requested = "review requested",
		security_alert = "security alert",
		state_change = "state changed",
		subscribed = "new activity",
		team_mention = "team mentioned",
	}
	local reason = reason_labels[notification.reason] or notification.reason or "updated"
	return string.format("%s · %s\n%s · %s", repo, subject.title or "Untitled", subject.type or "Notification", reason)
end

local function poll_github_notifications(notify_when_unchanged)
	if notification_poll_running then
		return
	end
	notification_poll_running = true
	local gh = require("octo.gh")
	gh.api.get({
		"notifications?per_page=100",
		paginate = true,
		slurp = true,
		opts = {
			cb = function(output, stderr)
				notification_poll_running = false
				if stderr and not vim.trim(stderr):match("^$") then
					if stderr ~= notification_last_error then
						notification_last_error = stderr
						vim.notify("GitHub notification polling failed: " .. vim.trim(stderr), vim.log.levels.WARN)
					end
					return
				end

				local notifications = decode_notification_pages(output or "")
				if not notifications then
					return
				end
				notification_last_error = nil
				local changed = {}
				local current_versions = {}
				for _, notification in ipairs(notifications) do
					local id = tostring(notification.id)
					local version = notification.updated_at or ""
					current_versions[id] = version
					if notification_baseline_ready and notification_versions[id] ~= version then
						table.insert(changed, notification)
					end
				end
				notification_versions = current_versions

				if not notification_baseline_ready then
					notification_baseline_ready = true
					if notify_when_unchanged then
						vim.notify(string.format("Watching %d unread GitHub notifications", #notifications), vim.log.levels.INFO)
					end
					return
				end

				for _, notification in ipairs(changed) do
					vim.notify(notification_message(notification), vim.log.levels.INFO, { title = "GitHub notification" })
				end
				if notify_when_unchanged and #changed == 0 then
					vim.notify("No new GitHub notifications", vim.log.levels.INFO)
				end
			end,
		},
	})
end

local function start_github_notification_polling()
	if notification_timer then
		vim.notify("GitHub notification polling is already running", vim.log.levels.INFO)
		return
	end
	notification_timer = vim.uv.new_timer()
	if not notification_timer then
		vim.notify("Could not create GitHub notification timer", vim.log.levels.ERROR)
		return
	end
	notification_timer:start(0, 60000, vim.schedule_wrap(function()
		poll_github_notifications(false)
	end))
end

local function stop_github_notification_polling(notify)
	if notification_timer then
		notification_timer:stop()
		notification_timer:close()
		notification_timer = nil
	end
	if notify then
		vim.notify("GitHub notification polling stopped", vim.log.levels.INFO)
	end
end

local function octo(command)
	return function()
		vim.cmd("Octo " .. command)
	end
end

local function open_my_prs()
	vim.cmd("Octo search is:pr is:open author:@me archived:false")
end

local function open_all_prs()
	vim.cmd("Octo search is:pr is:open involves:@me archived:false")
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

local function setup_issue_completion_metadata()
	local OctoBuffer = require("octo.model.octo-buffer").OctoBuffer
	local gh = require("octo.gh")

	function OctoBuffer:async_fetch_issues()
		gh.api.get({
			"repos/{repo}/issues",
			format = { repo = self.repo },
			jq = 'map({title, number, is_pull_request: has("pull_request")})',
			opts = {
				cb = gh.create_callback({
					success = function(data)
						_G.octo_repo_issues[self.repo] = vim.json.decode(data)
					end,
					failure = function() end,
				}),
			},
		})
	end
end

local function setup_cmp_completion()
	local ok, cmp = pcall(require, "cmp")
	if not ok or vim.g.octo_cmp_source_registered then
		return
	end

	local source = {}
	local function compare_issue_number(entry1, entry2)
		if entry1.source.name ~= "octo" or entry2.source.name ~= "octo" then
			return nil
		end
		if not entry1.context.cursor_before_line:match("#$") then
			return nil
		end

		local issue1 = entry1.completion_item.data and entry1.completion_item.data.octo_issue_number
		local issue2 = entry2.completion_item.data and entry2.completion_item.data.octo_issue_number
		if issue1 and issue2 then
			return tonumber(issue1:sub(2)) > tonumber(issue2:sub(2))
		end
	end

	function source:is_available()
		return vim.bo.filetype == "octo" and type(_G.octo_omnifunc) == "function"
	end

	function source:get_trigger_characters()
		return { "@", "#" }
	end

	function source:get_keyword_pattern()
		return [[\%(@[[:alnum:]_-]*\|#[[:alnum:]_-]*\)]]
	end

	function source:complete(params, callback)
		local before_cursor = params.context.cursor_before_line
		local base = before_cursor:match("(@[%w_-]*)$") or before_cursor:match("(#[-%w_]*)$")
		if not base then
			callback({})
			return
		end

		local items
		if vim.startswith(base, "#") then
			local buffer = require("octo.utils").get_current_buffer()
			local issues_by_repo = _G.octo_repo_issues or {}
			local issues = buffer and issues_by_repo[buffer.repo] or {}
			items = vim.tbl_map(function(issue)
				return {
					word = "#" .. tostring(issue.number),
					menu = issue.title,
					is_pull_request = issue.is_pull_request,
				}
			end, issues)
			table.sort(items, function(a, b)
				return tonumber(a.word:sub(2)) > tonumber(b.word:sub(2))
			end)
		else
			local ok_items
			ok_items, items = pcall(_G.octo_omnifunc, 0, base)
			if not ok_items or type(items) ~= "table" then
				callback({})
				return
			end
		end

		local completion_items = {}
		for _, item in ipairs(items) do
			local is_issue = vim.startswith(item.word or "", "#")
			local title = item.menu or item.abbr or ""
			table.insert(completion_items, {
				label = is_issue and vim.trim(item.word .. " " .. title) or item.word,
				insertText = item.word,
				filterText = is_issue and vim.trim(item.word .. " " .. title) or item.word,
				sortText = is_issue and string.format("%010d", 9999999999 - tonumber(item.word:sub(2))) or nil,
				detail = is_issue and (item.is_pull_request and "GitHub pull request" or "GitHub issue") or item.menu,
				documentation = title,
				data = is_issue and {
					octo_issue_number = item.word,
					octo_issue_title = title,
					octo_is_pull_request = item.is_pull_request,
				} or nil,
			})
		end

		callback(completion_items)
	end

	cmp.register_source("octo", source)

	local sources = vim.tbl_filter(function(source_config)
		return source_config.name ~= "octo"
	end, cmp.get_config().sources or {})
	local existing_format = vim.tbl_get(cmp.get_config(), "formatting", "format")
	local existing_sorting = cmp.get_config().sorting or {}
	local comparators = { compare_issue_number }
	vim.list_extend(comparators, existing_sorting.comparators or {})

	cmp.setup({
		sources = cmp.config.sources({
			{ name = "octo", priority = 1100, keyword_length = 0 },
		}, sources),
		formatting = {
			format = function(entry, vim_item)
				if existing_format then
					vim_item = existing_format(entry, vim_item)
				end

				local data = entry.completion_item.data
				if entry.source.name == "octo" and data and data.octo_issue_title then
					vim_item.abbr = data.octo_issue_number
					vim_item.kind = data.octo_is_pull_request and "PR" or "Issue"
					vim_item.kind_hl_group = data.octo_is_pull_request and "OctoCmpPullRequestKind"
						or "OctoCmpIssueKind"
					vim_item.menu = "  " .. data.octo_issue_title .. "  "
					vim_item.menu_hl_group = "OctoCmpIssueTitle"
				end

				return vim_item
			end,
		},
		sorting = {
			priority_weight = existing_sorting.priority_weight,
			comparators = comparators,
		},
	})

	vim.g.octo_cmp_source_registered = true
end

local function complete_octo_issue_reference()
	vim.schedule(function()
		local ok, cmp = pcall(require, "cmp")
		if ok and vim.bo.filetype == "octo" then
			cmp.complete({
				config = {
					sources = {
						{ name = "octo" },
					},
				},
			})
		end
	end)

	return "#"
end

-- Set highlight overrides BEFORE octo.setup() so octo doesn't clobber them
-- (octo only defines groups that don't already exist).
-- All hex values are from the Catppuccin Frappe palette.
local function setup_highlights()
	-- PR/issue title: lavender + bold, prominent like GitHub's h1
	vim.api.nvim_set_hl(0, "OctoIssueTitle", { fg = "#babbf1", bold = true })
	vim.api.nvim_set_hl(0, "OctoCmpIssueKind", { fg = "#232634", bg = "#8caaee", bold = true })
	vim.api.nvim_set_hl(0, "OctoCmpPullRequestKind", { fg = "#232634", bg = "#ca9ee6", bold = true })
	vim.api.nvim_set_hl(0, "OctoCmpIssueTitle", { fg = "#c6d0f5", bg = "#414559" })
	vim.api.nvim_set_hl(0, "OctoDiffviewCommentedLine", { bg = "#36415a" })
	vim.api.nvim_set_hl(0, "OctoDiffviewCommentedNumber", { fg = "#99d1db", bold = true })
	vim.api.nvim_set_hl(0, "OctoDiffviewContextHeader", { fg = "#c6d0f5", bg = "#414559", bold = true })
	vim.api.nvim_set_hl(0, "OctoDiffviewContextLine", { fg = "#838ba7", bg = "#303446" })
	vim.api.nvim_set_hl(0, "OctoDiffviewContextLeft", { fg = "#e78284", bg = "#49313c", bold = true })
	vim.api.nvim_set_hl(0, "OctoDiffviewContextRight", { fg = "#a6d189", bg = "#30473f", bold = true })
	-- Sidebar metadata labels (Reviewers, Assignees, Labels…): muted subtext
	vim.api.nvim_set_hl(0, "OctoDetailsLabel", { fg = "#a5adce", bold = true })
	-- Timestamps: dimmer than regular comment text
	vim.api.nvim_set_hl(0, "OctoDate", { fg = "#737994", italic = true })
	-- Separator/symbol glyphs between metadata items
	vim.api.nvim_set_hl(0, "OctoSymbol", { fg = "#626880" })
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
	-- REVIEWS: Strong purple-tinted card backgrounds (GitHub-style bordered cards)
	vim.api.nvim_set_hl(0, "OctoReviewLine", { bg = "#474968", fg = "#babbf1", bold = true })
	vim.api.nvim_set_hl(0, "OctoReviewBodyLine", { bg = "#363750" })
	vim.api.nvim_set_hl(0, "OctoReviewBodyAltLine", { bg = "#3a3b54" })
	vim.api.nvim_set_hl(0, "OctoReviewBorder", { fg = "#8caaee", bold = true })
	vim.api.nvim_set_hl(0, "OctoReviewDivider", { fg = "#51576d" })

	-- THREADS: Strong blue-tinted backgrounds with high contrast
	vim.api.nvim_set_hl(0, "OctoThreadLine", { bg = "#243b53", fg = "#c6d0f5", bold = true })
	vim.api.nvim_set_hl(0, "OctoThreadBodyLine", { bg = "#26384a" })
	vim.api.nvim_set_hl(0, "OctoThreadBodyAltLine", { bg = "#2b3f52" })
	vim.api.nvim_set_hl(0, "OctoThreadBorder", { fg = "#99d1db", bg = "#1f2d3d", bold = true })
	vim.api.nvim_set_hl(0, "OctoThreadRail", { fg = "#99d1db", bg = "#26384a", bold = true })
	vim.api.nvim_set_hl(0, "OctoThreadRailDim", { fg = "#6e8da0", bg = "#26384a" })
	vim.api.nvim_set_hl(0, "OctoThreadCap", { fg = "#232634", bg = "#99d1db", bold = true })
	vim.api.nvim_set_hl(0, "OctoThreadMutedCap", { fg = "#99d1db", bg = "#1f2d3d" })

	-- COMMENTS: Neutral backgrounds
	vim.api.nvim_set_hl(0, "OctoCommentBodyLine", { bg = "#303446" })
	vim.api.nvim_set_hl(0, "OctoIssueBodyLine", { bg = "#2e3440" })
	vim.api.nvim_set_hl(0, "OctoIssueBodyAltLine", { bg = "#323844" })

	-- Section separators (bold dividers between reviews/threads)
	vim.api.nvim_set_hl(0, "OctoSectionDivider", { fg = "#626880", bold = true })
	-- CODE SNIPPETS: Very dark background with strong borders
	vim.api.nvim_set_hl(0, "OctoSnippetLine", { bg = "#1e1e2e" })
	vim.api.nvim_set_hl(0, "OctoSnippetBorder", { fg = "#8caaee", bg = "#1e1e2e", bold = true })
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
	local thread_end_caps = {}
	local comment_headers = {}
	local markdown_ns = vim.api.nvim_create_namespace("octo_markdown_visuals")

	local function valid_buffer_line(bufnr, line)
		return vim.api.nvim_buf_is_valid(bufnr) and line and line > 0 and line <= vim.api.nvim_buf_line_count(bufnr)
	end

	local function mark_line(bufnr, line, group)
		if valid_buffer_line(bufnr, line) then
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

	local function visual_width()
		return math.max(vim.fn.winwidth(0) - 14, 24)
	end

	local function truncate_text(text, max_width)
		text = tostring(text or "")
		if vim.fn.strdisplaywidth(text) <= max_width then
			return text
		end

		if max_width <= 1 then
			return "…"
		end

		local ret = ""
		for _, char in ipairs(vim.fn.split(text, "\\zs")) do
			if vim.fn.strdisplaywidth(ret .. char .. "…") > max_width then
				break
			end
			ret = ret .. char
		end

		return ret .. "…"
	end

	local function thread_rail_prefix(strong)
		return {
			{ "  ", "Normal" },
			{ strong and "┃ " or "│ ", strong and "OctoThreadRail" or "OctoThreadRailDim" },
		}
	end

	local function mark_thread_range(bufnr, first, last, group)
		if not first or not last or last < first then
			return
		end

		for line = first, last do
			if valid_buffer_line(bufnr, line) then
				vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
					virt_text = thread_rail_prefix(false),
					virt_text_pos = "inline",
					line_hl_group = group,
					priority = 35,
				})
			end
		end
	end

	local function set_thread_cap(bufnr, line, label, above)
		if not valid_buffer_line(bufnr, line) then
			return
		end

		local width = visual_width()
		local title = " " .. label .. " "
		local prefix = "  ╭"
		local remaining = math.max(width - vim.fn.strdisplaywidth(prefix) - vim.fn.strdisplaywidth(title), 8)
		local cap = {
			{ prefix, "OctoThreadBorder" },
			{ title, "OctoThreadCap" },
			{ string.rep("─", remaining), "OctoThreadBorder" },
		}

		vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
			virt_lines = { cap },
			virt_lines_above = above,
			priority = 28,
		})
	end

	local function set_thread_end_cap(bufnr, line)
		if not valid_buffer_line(bufnr, line) then
			return
		end

		return vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
			virt_lines = {
				{ { "  ╰" .. string.rep("─", visual_width() - 3), "OctoThreadBorder" } },
				{ { "", "Normal" } },
			},
			priority = 28,
		})
	end

	local function replace_thread_end_cap(bufnr, line)
		if thread_end_caps[bufnr] then
			pcall(vim.api.nvim_buf_del_extmark, bufnr, ns, thread_end_caps[bufnr])
		end
		thread_end_caps[bufnr] = set_thread_end_cap(bufnr, line)
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
		if valid_buffer_line(bufnr, line) then
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
		if valid_buffer_line(bufnr, line) then
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
		if valid_buffer_line(bufnr, line) then
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
		if valid_buffer_line(bufnr, line) then
			vim.api.nvim_buf_set_extmark(bufnr, markdown_ns, line - 1, 0, {
				line_hl_group = group,
				priority = 60,
			})
		end
	end

	local function add_section_spacing(bufnr, line, kind)
		-- Add dramatic visual separation between major sections (Reviews vs Threads vs Comments)
		-- This creates GitHub-style "cards" for each review/thread
		if not valid_buffer_line(bufnr, line) then
			return
		end

		local spacing_width = visual_width()
		local divider_char = "━"
		local spacing_hl = "OctoSectionDivider"

		if kind == "PullRequestReview" then
			spacing_hl = "OctoReviewBorder"
			-- Add a full-width top border for review cards
			vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
				virt_lines_above = true,
				virt_lines = {
					{ { "", "Normal" } }, -- Empty line for spacing
					{ { "┏" .. string.rep(divider_char, spacing_width - 1), spacing_hl } }, -- Top border
				},
				priority = 15,
			})
		elseif kind == "PullRequestReviewComment" or kind == "PullRequestComment" then
			spacing_hl = "OctoThreadBorder"
			-- Add indented border for thread sections
			vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
				virt_lines_above = true,
				virt_lines = {
					{ { "", "Normal" } },
					{
						{ "  ├", spacing_hl },
						{ " comment ", "OctoThreadMutedCap" },
						{ string.rep("─", math.max(spacing_width - 12, 10)), spacing_hl },
					},
				},
				priority = 15,
			})
		else
			-- Standard section separator
			vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
				virt_lines_above = true,
				virt_lines = {
					{ { "", "Normal" } }, -- Empty line for spacing
				},
				priority = 15,
			})
		end
	end

	local function mark_inline_code(bufnr, line, text)
		if not valid_buffer_line(bufnr, line) then
			return
		end

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
		if not vim.api.nvim_buf_is_valid(bufnr) or not first or not last or last < first then
			return
		end

		local line_count = vim.api.nvim_buf_line_count(bufnr)
		first = math.max(1, first)
		last = math.min(last, line_count)
		if last < first then
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
		if not valid_buffer_line(bufnr, line) then
			return
		end

		local comment = opts.comment
		local kind = opts.kind
		local author = comment.author and logins.format_author(comment.author) or { login = "unknown" }
		local heading = "COMMENT"
		local line_group = "OctoReviewLine"
		local marker_hl = "OctoTimelineMarker"
		local prefix = ""

		if kind == "PullRequestReview" then
			heading = "REVIEW"
			marker_hl = "OctoReviewBorder"
			prefix = "┃ "
		elseif kind == "PullRequestReviewComment" then
			heading = "THREAD COMMENT"
			line_group = "OctoThreadLine"
			marker_hl = "OctoThreadBorder"
			prefix = "  ┃ "
		elseif kind == "PullRequestComment" then
			heading = "COMMENT"
			line_group = "OctoThreadLine"
			marker_hl = "OctoThreadBorder"
			prefix = "  ┃ "
		elseif kind == "IssueComment" or kind == "DiscussionComment" then
			heading = utils.is_blank(comment.replyTo) and "COMMENT" or "REPLY"
			prefix = "┃ "
		end

		local header_vt = {
			{ prefix, marker_hl },
			{ fold_marker(line), "OctoFoldMarker" },
			{ " " .. heading .. " ", "OctoTimelineItemHeading" },
			{ " by ", "OctoOverviewMuted" },
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

		table.insert(header_vt, { "  " .. utils.format_date(comment.createdAt), "OctoDate" })
		if is_present(comment.lastEditedAt) and comment.lastEditedAt ~= comment.createdAt then
			table.insert(header_vt, { "  (edited " .. utils.format_date(comment.lastEditedAt) .. ")", "OctoDate" })
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
		if not valid_buffer_line(bufnr, line) then
			return
		end

		local path_suffix = " L" .. tostring(opts.start_line) .. "-" .. tostring(opts.end_line)
		local commit_suffix = "  @ " .. opts.commit:sub(1, 7)
		local badge_reserve = 0
		if opts.isOutdated then
			badge_reserve = badge_reserve + 12
		end
		if opts.isResolved then
			badge_reserve = badge_reserve + (opts.resolvedBy and 22 or 4)
		end
		local fixed_width = vim.fn.strdisplaywidth("  ┃ " .. fold_marker(line) .. " THREAD   ")
			+ vim.fn.strdisplaywidth(path_suffix)
			+ vim.fn.strdisplaywidth(commit_suffix)
			+ badge_reserve
		local path_width = math.max(18, visual_width() - fixed_width)

		local header_vt = {
			{ "  ┃ ", "OctoThreadRail" },
			{ fold_marker(line), "OctoFoldMarker" },
			{ " THREAD ", "OctoThreadCap" },
			{ "  ", "OctoThreadBorder" },
			{ truncate_text(opts.path, path_width), "OctoDetailsLabel" },
			{ path_suffix, "OctoDetailsValue" },
			{ "  @ ", "OctoOverviewMuted" },
			{ opts.commit:sub(1, 7), "OctoDetailsLabel" },
			{ "  ", "OctoSymbol" },
		}

		if opts.isOutdated then
			vim.list_extend(header_vt, bubbles.make_bubble("outdated", "OctoWarnBubble", { right_margin_width = 1 }))
		end

		if opts.isResolved then
			table.insert(header_vt, { " ✓ ", "OctoGreen" })
			if opts.resolvedBy then
				vim.list_extend(header_vt, {
					{ "resolved by ", "OctoOverviewMuted" },
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
		if not vim.api.nvim_buf_is_valid(bufnr) then
			thread_headers[bufnr] = nil
			comment_headers[bufnr] = nil
			return
		end

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

		-- Add spacing before major sections for visual separation
		add_section_spacing(bufnr, start_line, kind)

		if kind == "PullRequestReview" then
			comment_headers[bufnr] = comment_headers[bufnr] or {}
			comment_headers[bufnr][start_line] = { comment = comment, kind = kind }
			render_comment_header(bufnr, start_line, comment_headers[bufnr][start_line])
			mark_line(bufnr, start_line, "OctoReviewLine")
			mark_range(bufnr, start_line + 1, end_line, "OctoReviewBodyLine")
			apply_markdown_visuals(bufnr, start_line + 1, end_line, { "OctoReviewBodyLine", "OctoReviewBodyAltLine" })

			-- Add bottom border for review card
			if valid_buffer_line(bufnr, end_line) then
				local spacing_width = math.max(vim.fn.winwidth(0) - 8, 20)
				vim.api.nvim_buf_set_extmark(bufnr, ns, end_line - 1, 0, {
					virt_lines = {
						{ { "┗" .. string.rep("━", spacing_width - 1), "OctoReviewBorder" } }, -- Bottom border
						{ { "", "Normal" } }, -- Empty line after review
					},
					priority = 15,
				})
			end
		elseif kind == "PullRequestReviewComment" or kind == "PullRequestComment" then
			comment_headers[bufnr] = comment_headers[bufnr] or {}
			comment_headers[bufnr][start_line] = { comment = comment, kind = kind }
			render_comment_header(bufnr, start_line, comment_headers[bufnr][start_line])
			mark_line(bufnr, start_line, "OctoThreadLine")
			mark_thread_range(bufnr, start_line + 1, end_line, "OctoThreadBodyLine")
			apply_markdown_visuals(bufnr, start_line + 1, end_line, { "OctoThreadBodyLine", "OctoThreadBodyAltLine" })

			replace_thread_end_cap(bufnr, end_line)
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
		thread_end_caps[bufnr] = nil

		writers.write_block(bufnr, { "" })
		set_thread_cap(bufnr, header_line, "review thread", true)
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
			mark_thread_range(bufnr, snippet_start, snippet_end, "OctoSnippetLine")
			-- Add dramatic visual borders around code snippets
			if valid_buffer_line(bufnr, snippet_start) then
				local width = visual_width()
				vim.api.nvim_buf_set_extmark(bufnr, ns, snippet_start - 1, 0, {
					virt_lines_above = true,
					virt_lines = {
						{
							{ "  ├", "OctoThreadBorder" },
							{ " code context ", "OctoThreadMutedCap" },
							{ string.rep("─", math.max(width - 17, 5)), "OctoSnippetBorder" },
						},
					},
					priority = 25,
				})
			end
			if valid_buffer_line(bufnr, snippet_end) then
				local width = visual_width()
				vim.api.nvim_buf_set_extmark(bufnr, ns, snippet_end - 1, 0, {
					virt_lines = {
						{
							{ "  ├", "OctoThreadBorder" },
							{ string.rep("─", math.max(width - 2, 15)), "OctoSnippetBorder" },
						},
					},
					priority = 25,
				})
			end
		end

		return snippet_start, snippet_end
	end
end

local function open_diffview_comment_editor(context, initial_lines, on_submit)
	local bufnr = vim.api.nvim_create_buf(false, true)
	local width = math.min(80, math.max(vim.o.columns - 8, 40))
	local height = math.min(12, math.max(vim.o.lines - 8, 6))
	local title = context.editor_title_full
		or string.format(
			" %s · %s · %s:%d-%d ",
			context.editor_title or (context.is_suggestion and "Suggestion" or "Comment"),
			context.side or "THREAD",
			context.path,
			context.start_line,
			context.end_line
		)
	local winid = vim.api.nvim_open_win(bufnr, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2) - 1,
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = "rounded",
		title = title,
		title_pos = "center",
	})

	vim.bo[bufnr].filetype = "markdown"
	vim.bo[bufnr].buftype = "acwrite"
	vim.bo[bufnr].bufhidden = "wipe"
	vim.api.nvim_buf_set_name(bufnr, "octo-review-comment://" .. tostring(bufnr))
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, initial_lines or { "" })
	vim.wo[winid].wrap = true
	vim.wo[winid].linebreak = true

	local function close()
		if vim.api.nvim_win_is_valid(winid) then
			vim.api.nvim_win_close(winid, true)
		end
	end

	vim.keymap.set("n", "q", close, { buffer = bufnr, desc = "Cancel review comment" })
	local function submit()
		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		local body = vim.trim(table.concat(lines, "\n"))
		if body == "" and not context.allow_empty then
			vim.notify("Review comment cannot be empty", vim.log.levels.WARN)
			return
		end
		close()
		on_submit(body)
	end

	vim.api.nvim_create_autocmd("BufWriteCmd", {
		buffer = bufnr,
		callback = submit,
	})
	vim.keymap.set({ "n", "i" }, "<C-s>", submit, { buffer = bufnr, desc = "Post review comment" })

	vim.api.nvim_buf_set_extmark(bufnr, vim.api.nvim_create_namespace("OctoDiffviewCommentHelp"), 0, 0, {
		virt_text = { { "  :w post · q cancel", "Comment" } },
		virt_text_pos = "right_align",
	})
	if context.diff_context and #context.diff_context > 0 then
		local side_group = context.side == "LEFT" and "OctoDiffviewContextLeft" or "OctoDiffviewContextRight"
		local context_lines = {
			{
				{ " " .. context.side .. " ", side_group },
				{ string.format("  %s  lines %d-%d", context.path, context.start_line, context.end_line), "OctoDiffviewContextHeader" },
			},
		}
		for _, item in ipairs(context.diff_context) do
			local marker = item.selected and "▶" or " "
			local group = item.selected and side_group or "OctoDiffviewContextLine"
			local available_width = math.max(width - 12, 10)
			table.insert(context_lines, {
				{ string.format("%s %4d │ ", marker, item.line), group },
				{ vim.fn.strcharpart(item.text, 0, available_width), group },
			})
		end
		vim.api.nvim_buf_set_extmark(bufnr, vim.api.nvim_create_namespace("OctoDiffviewCommentContext"), 0, 0, {
			virt_lines = context_lines,
			virt_lines_above = true,
		})
	end
	if context.is_suggestion then
		vim.api.nvim_win_set_cursor(winid, { 2, 0 })
	end
	vim.cmd("startinsert")
end

local diffview_comments_ns = vim.api.nvim_create_namespace("OctoDiffviewReviewComments")

local function github_line(value)
	-- vim.json.decode represents JSON null as vim.NIL, which is truthy but is
	-- userdata rather than a number. Outdated GitHub comments use null lines.
	if type(value) == "number" then
		return value
	elseif type(value) == "string" then
		return tonumber(value)
	end
end

local function review_comment_virtual_lines(comment)
	local author = comment.user and comment.user.login or "unknown"
	local created = (comment.created_at or ""):gsub("T", " "):gsub("Z$", " UTC")
	local reply = comment.in_reply_to_id and "↳ reply by " or "comment by "
	local state = comment.octo_is_resolved and " · resolved" or ""
	if comment.octo_is_pending then
		state = state .. " · pending"
	end
	local reaction_text = ""
	local reaction_icons = {
		{ "+1", "👍" },
		{ "-1", "👎" },
		{ "laugh", "😄" },
		{ "hooray", "🎉" },
		{ "confused", "😕" },
		{ "heart", "❤️" },
		{ "rocket", "🚀" },
		{ "eyes", "👀" },
	}
	for _, reaction in ipairs(reaction_icons) do
		local name, icon = unpack(reaction)
		local count = comment.reactions and comment.reactions[name] or 0
		if count > 0 then
			reaction_text = reaction_text .. string.format("  %s %d", icon, count)
		end
	end
	local lines = {
		{
			{ "╭─ ", "OctoThreadBorder" },
			{ reply .. author, "OctoUser" },
			{ (created ~= "" and " · " .. created or "") .. state, "OctoDate" },
		},
	}
	local body_lines = vim.split(comment.body or "", "\n", { plain = true })
	if #body_lines == 0 then
		body_lines = { "" }
	end
	for _, line in ipairs(body_lines) do
		table.insert(lines, {
			{ "│  ", "OctoThreadRail" },
			{ line, "OctoThreadBodyLine" },
		})
	end
	if reaction_text ~= "" then
		table.insert(lines, {
			{ "│ ", "OctoThreadRail" },
			{ reaction_text, "OctoOverviewMuted" },
		})
	end
	if comment.html_url then
		table.insert(lines, {
			{ "╰─ ", "OctoThreadBorder" },
			{ comment.html_url, "OctoMarkdownUrl" },
		})
	else
		table.insert(lines, { { "╰─", "OctoThreadBorder" } })
	end
	return lines
end

local function render_diffview_review_comments(view)
	if not view or not view.octo_pr_context or not view.cur_entry or not view.cur_layout then
		return
	end

	local entry = view.cur_entry
	local layout = view.cur_layout
	for _, window in ipairs({ layout.a, layout.b }) do
		local bufnr = window and window.file and window.file.bufnr
		if bufnr and vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
			vim.api.nvim_buf_clear_namespace(bufnr, diffview_comments_ns, 0, -1)
		end
	end

	local comments_by_buffer = {}
	for _, comment in ipairs(view.octo_review_comments or {}) do
		local path_matches = comment.path == entry.path or comment.path == entry.oldpath
		local window = comment.side == "LEFT" and layout.a or comment.side == "RIGHT" and layout.b or nil
		local bufnr = window and window.file and window.file.bufnr
		-- GitHub sets `line` to null when a comment is outdated. Its
		-- `original_line` belongs to an older commit and must not be anchored to
		-- the current Diffview, where it could point at unrelated code.
		local line = github_line(comment.line)
		if path_matches and bufnr and line then
			comments_by_buffer[bufnr] = comments_by_buffer[bufnr] or {}
			comments_by_buffer[bufnr][line] = comments_by_buffer[bufnr][line] or {}
			table.insert(comments_by_buffer[bufnr][line], comment)
		end
	end

	for bufnr, comments_by_line in pairs(comments_by_buffer) do
		if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
			local line_count = vim.api.nvim_buf_line_count(bufnr)
			local highlighted_lines = {}
			for line, comments in pairs(comments_by_line) do
				if line > 0 and line <= line_count then
					local virtual_lines = {}
					table.sort(comments, function(a, b)
						return (a.created_at or "") < (b.created_at or "")
					end)
					for _, comment in ipairs(comments) do
						comment.octo_is_pending = view.octo_pending_review
							and comment.pull_request_review_id == view.octo_pending_review.id
							or false
						local range_start = math.max(github_line(comment.start_line) or line, 1)
						local range_end = math.min(line, line_count)
						for commented_line = range_start, range_end do
							if not highlighted_lines[commented_line] then
								highlighted_lines[commented_line] = true
								vim.api.nvim_buf_set_extmark(bufnr, diffview_comments_ns, commented_line - 1, 0, {
									line_hl_group = "OctoDiffviewCommentedLine",
									number_hl_group = "OctoDiffviewCommentedNumber",
									sign_text = commented_line == range_start and "●" or nil,
									sign_hl_group = "OctoDiffviewCommentedNumber",
									priority = 20,
								})
							end
						end
						vim.list_extend(virtual_lines, review_comment_virtual_lines(comment))
					end
					vim.api.nvim_buf_set_extmark(bufnr, diffview_comments_ns, line - 1, 0, {
						virt_lines = virtual_lines,
						priority = 30,
					})
				end
			end
		end
	end
end

local function add_review_thread_metadata(view, comments, on_complete)
	local context = view.octo_pr_context
	local owner, name = require("octo.utils").split_repo(context.repo)
	local query = [[
query($owner: String!, $name: String!, $number: Int!) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          comments(first: 100) { nodes { databaseId } }
        }
      }
    }
  }
}
]]
	local gh = require("octo.gh")
	gh.api.graphql({
		query = query,
		F = { owner = owner, name = name, number = context.number },
		opts = {
			cb = gh.create_callback({
				success = function(data)
					local ok, response = pcall(vim.json.decode, data)
					local threads = ok
						and vim.tbl_get(response, "data", "repository", "pullRequest", "reviewThreads", "nodes")
						or {}
					local metadata = {}
					for _, thread in ipairs(threads or {}) do
						for _, thread_comment in ipairs(vim.tbl_get(thread, "comments", "nodes") or {}) do
							metadata[thread_comment.databaseId] = {
								thread_id = thread.id,
								is_resolved = thread.isResolved,
							}
						end
					end
					for _, comment in ipairs(comments) do
						local item = metadata[comment.id]
						if item then
							comment.octo_thread_id = item.thread_id
							comment.octo_is_resolved = item.is_resolved
						end
					end
					on_complete()
				end,
				failure = function()
					on_complete()
				end,
			}),
		},
	})
end

local function refresh_diffview_review_comments(view)
	if not view or not view.octo_pr_context then
		return
	end
	local context = view.octo_pr_context
	require("octo.gh").api.get({
		"repos/{repo}/pulls/{pull_number}/comments?per_page=100",
		format = { repo = context.repo, pull_number = context.number },
		paginate = true,
		slurp = true,
		opts = {
			cb = require("octo.gh").create_callback({
				success = function(data)
					local ok, pages = pcall(vim.json.decode, data)
					if not ok then
						vim.notify("Could not decode GitHub review comments", vim.log.levels.ERROR)
						return
					end
					local comments = {}
					for _, page in ipairs(pages or {}) do
						if vim.islist(page) then
							vim.list_extend(comments, page)
						end
					end
					add_review_thread_metadata(view, comments, function()
						view.octo_review_comments = comments
						render_diffview_review_comments(view)
					end)
				end,
			}),
		},
	})
end

local function reply_to_diffview_review_comment(view, comment)
	local line = github_line(comment.line)
	local context = vim.tbl_extend("force", view.octo_pr_context, {
		diffview = view,
		editor_title = "Reply",
		path = comment.path,
		start_line = line,
		end_line = line,
	})
	open_diffview_comment_editor(context, { "" }, function(body)
		local gh = require("octo.gh")
		gh.api.post({
			"repos/{repo}/pulls/{pull_number}/comments/{comment_id}/replies",
			format = {
				repo = context.repo,
				pull_number = context.number,
				comment_id = comment.in_reply_to_id or comment.id,
			},
			f = { body = body },
			opts = {
				cb = gh.create_callback({
					success = function()
						vim.notify("Posted GitHub review reply", vim.log.levels.INFO)
						refresh_diffview_review_comments(view)
					end,
				}),
			},
		})
	end)
end

local function react_to_diffview_review_comment(view, comment)
	local reactions = {
		{ label = "👍  Thumbs up", value = "+1" },
		{ label = "👎  Thumbs down", value = "-1" },
		{ label = "😄  Laugh", value = "laugh" },
		{ label = "🎉  Hooray", value = "hooray" },
		{ label = "😕  Confused", value = "confused" },
		{ label = "❤️  Heart", value = "heart" },
		{ label = "🚀  Rocket", value = "rocket" },
		{ label = "👀  Eyes", value = "eyes" },
	}
	vim.ui.select(reactions, {
		prompt = "Send reaction",
		format_item = function(item)
			return item.label
		end,
	}, function(reaction)
		if not reaction then
			return
		end
		local gh = require("octo.gh")
		gh.api.post({
			"repos/{repo}/pulls/comments/{comment_id}/reactions",
			format = { repo = view.octo_pr_context.repo, comment_id = comment.id },
			f = { content = reaction.value },
			opts = {
				cb = gh.create_callback({
					success = function()
						vim.notify("Added reaction " .. reaction.label:match("^%S+"), vim.log.levels.INFO)
						refresh_diffview_review_comments(view)
					end,
				}),
			},
		})
	end)
end

local function resolve_diffview_review_thread(view, comment)
	if not comment.octo_thread_id then
		vim.notify("Could not find the GitHub review thread for this comment", vim.log.levels.WARN)
		return
	end
	if comment.octo_is_resolved then
		vim.notify("This review thread is already resolved", vim.log.levels.INFO)
		return
	end

	local gh = require("octo.gh")
	local query = require("octo.gh.graphql")("resolve_review_thread_mutation", comment.octo_thread_id)
	gh.api.graphql({
		f = { query = query },
		opts = {
			cb = gh.create_callback({
				success = function()
					vim.notify("Resolved GitHub review thread", vim.log.levels.INFO)
					refresh_diffview_review_comments(view)
				end,
			}),
		},
	})
end

local function suggestion_text(comment)
	local body = (comment.body or ""):gsub("\r\n", "\n")
	return body:match("```suggestion[^\n]*\n(.-)\n```")
end

local function commit_diffview_review_suggestion(view, comment)
	local replacement = suggestion_text(comment)
	local context = view.octo_pr_context
	if replacement == nil then
		vim.notify("This review comment does not contain a GitHub suggestion", vim.log.levels.WARN)
		return
	end
	if not is_present(context.head_repo) or not is_present(context.head_branch) then
		vim.notify("Reopen this PR Diffview so its head-branch context can be refreshed", vim.log.levels.WARN)
		return
	end

	local first_line = github_line(comment.start_line) or github_line(comment.line)
	local last_line = github_line(comment.line)
	if not first_line or not last_line then
		vim.notify("This suggestion is outdated and can no longer be committed", vim.log.levels.WARN)
		return
	end

	local author = comment.user and comment.user.login or "reviewer"
	vim.ui.input({
		prompt = "Suggestion commit message: ",
		default = "Apply suggestion from @" .. author,
	}, function(message)
		message = message and vim.trim(message) or ""
		if message == "" then
			return
		end

		local gh = require("octo.gh")
		gh.api.get({
			"repos/{repo}/contents/{path}",
			format = { repo = context.head_repo, path = comment.path },
			f = { ref = context.head_branch },
			opts = {
				cb = gh.create_callback({
					success = function(data)
						local ok, file = pcall(vim.json.decode, data)
						if not ok or not file.content or not file.sha then
							vim.notify("Could not read the PR head file from GitHub", vim.log.levels.ERROR)
							return
						end

						local blob_result = vim.system(
							{ "git", "rev-parse", context.head_ref .. ":" .. comment.path },
							{ text = true, cwd = context.git_root }
						):wait()
						local local_blob = blob_result.code == 0 and vim.trim(blob_result.stdout or "") or nil
						if not local_blob or local_blob ~= file.sha then
							vim.notify(
								"The PR branch changed since this Diffview opened; reopen it before committing the suggestion",
								vim.log.levels.WARN
							)
							return
						end

						local content = vim.base64.decode((file.content:gsub("%s", "")))
						local lines = vim.split(content, "\n", { plain = true })
						if first_line < 1 or last_line > #lines or first_line > last_line then
							vim.notify("The suggestion range no longer exists on the PR branch", vim.log.levels.WARN)
							return
						end

						local replacement_lines = replacement == "" and {} or vim.split(replacement, "\n", { plain = true })
						local updated = {}
						vim.list_extend(updated, vim.list_slice(lines, 1, first_line - 1))
						vim.list_extend(updated, replacement_lines)
						vim.list_extend(updated, vim.list_slice(lines, last_line + 1))

						gh.api.put({
							"repos/{repo}/contents/{path}",
							format = { repo = context.head_repo, path = comment.path },
							f = {
								message = message,
								content = vim.base64.encode(table.concat(updated, "\n")),
								branch = context.head_branch,
								sha = file.sha,
							},
							opts = {
								cb = gh.create_callback({
									success = function()
										vim.notify(
											"Committed suggestion to "
												.. context.head_repo
												.. ":"
												.. context.head_branch
												.. "; reopen Diffview to see the new commit",
											vim.log.levels.INFO
										)
										if comment.octo_thread_id and not comment.octo_is_resolved then
											resolve_diffview_review_thread(view, comment)
										else
											refresh_diffview_review_comments(view)
										end
									end,
								}),
							},
						})
					end,
				}),
			},
		})
	end)
end

local function diffview_comments_at_cursor(only_mine)
	local view = require("diffview.lib").get_current_view()
	local entry = view and view.cur_entry
	local layout = view and view.cur_layout
	if not view or not view.octo_pr_context or not entry or not layout then
		return nil, {}
	end

	local current_win = vim.api.nvim_get_current_win()
	local side = layout.a and layout.a.id == current_win and "LEFT"
		or layout.b and layout.b.id == current_win and "RIGHT"
		or nil
	local line = vim.api.nvim_win_get_cursor(0)[1]
	local viewer = vim.g.octo_viewer
	viewer = is_present(viewer) and viewer:lower() or nil
	local comments = vim.tbl_filter(function(comment)
		local login = comment.user and comment.user.login
		local belongs_to_viewer = not only_mine or (viewer and login and login:lower() == viewer)
		return belongs_to_viewer
			and github_line(comment.line) == line
			and comment.side == side
			and (comment.path == entry.path or comment.path == entry.oldpath)
	end, view.octo_review_comments or {})

	if only_mine and not viewer then
		vim.notify("Could not determine the authenticated GitHub user", vim.log.levels.WARN)
	elseif #comments == 0 then
		vim.notify(
			only_mine and "You have no GitHub review comment attached to this line"
				or "No GitHub review comment is attached to this line",
			vim.log.levels.INFO
		)
	end
	return view, comments
end

local function choose_diffview_comment(comments, prompt, callback)
	if #comments == 0 then
		return
	elseif #comments == 1 then
		callback(comments[1])
		return
	end
	vim.ui.select(comments, {
		prompt = prompt,
		format_item = function(comment)
			local author = comment.user and comment.user.login or "unknown"
			local summary = (comment.body or ""):match("[^\n]*") or ""
			return string.format("@%s: %s", author, summary)
		end,
	}, function(comment)
		if comment then
			callback(comment)
		end
	end)
end

local function reply_to_diffview_thread_at_cursor()
	local view, comments = diffview_comments_at_cursor(false)
	choose_diffview_comment(comments, "Reply to review comment", function(comment)
		reply_to_diffview_review_comment(view, comment)
	end)
end

local function edit_diffview_review_comment()
	local view, comments = diffview_comments_at_cursor(true)
	choose_diffview_comment(comments, "Edit your review comment", function(comment)
		local line = github_line(comment.line)
		local context = vim.tbl_extend("force", view.octo_pr_context, {
			editor_title = "Edit comment",
			path = comment.path,
			start_line = line,
			end_line = line,
		})
		open_diffview_comment_editor(context, vim.split(comment.body or "", "\n", { plain = true }), function(body)
			local gh = require("octo.gh")
			gh.api.patch({
				"repos/{repo}/pulls/comments/{comment_id}",
				format = { repo = context.repo, comment_id = comment.id },
				f = { body = body },
				opts = {
					cb = gh.create_callback({
						success = function()
							vim.notify("Updated GitHub review comment", vim.log.levels.INFO)
							refresh_diffview_review_comments(view)
						end,
					}),
				},
			})
		end)
	end)
end

local function delete_diffview_review_comment()
	local view, comments = diffview_comments_at_cursor(true)
	choose_diffview_comment(comments, "Delete your review comment", function(comment)
		vim.ui.select({ "Cancel", "Delete comment" }, { prompt = "Permanently delete this GitHub comment?" }, function(choice)
			if choice ~= "Delete comment" then
				return
			end
			local gh = require("octo.gh")
			gh.api.delete({
				"repos/{repo}/pulls/comments/{comment_id}",
				format = { repo = view.octo_pr_context.repo, comment_id = comment.id },
				opts = {
					cb = gh.create_callback({
						success = function()
							vim.notify("Deleted GitHub review comment", vim.log.levels.INFO)
							refresh_diffview_review_comments(view)
						end,
					}),
				},
			})
		end)
	end)
end

local function interact_with_diffview_review_comment()
	local view = require("diffview.lib").get_current_view()
	local entry = view and view.cur_entry
	local layout = view and view.cur_layout
	if not view or not view.octo_pr_context or not entry or not layout then
		return
	end

	local current_win = vim.api.nvim_get_current_win()
	local side = layout.a and layout.a.id == current_win and "LEFT"
		or layout.b and layout.b.id == current_win and "RIGHT"
		or nil
	local line = vim.api.nvim_win_get_cursor(0)[1]
	local comments = vim.tbl_filter(function(comment)
		return github_line(comment.line) == line
			and comment.side == side
			and (comment.path == entry.path or comment.path == entry.oldpath)
	end, view.octo_review_comments or {})
	if #comments == 0 then
		vim.notify("No GitHub review comment is attached to this line", vim.log.levels.INFO)
		return
	end

	local function choose_action(comment)
		local actions = { "React", "Reply", "Resolve thread" }
		if suggestion_text(comment) ~= nil then
			table.insert(actions, 1, "Commit suggestion")
		end
		vim.ui.select(actions, { prompt = "Review comment action" }, function(action)
			if action == "Commit suggestion" then
				commit_diffview_review_suggestion(view, comment)
			elseif action == "React" then
				react_to_diffview_review_comment(view, comment)
			elseif action == "Reply" then
				reply_to_diffview_review_comment(view, comment)
			elseif action == "Resolve thread" then
				resolve_diffview_review_thread(view, comment)
			end
		end)
	end

	if #comments == 1 then
		choose_action(comments[1])
		return
	end
	vim.ui.select(comments, {
		prompt = "Choose review comment",
		format_item = function(comment)
			local author = comment.user and comment.user.login or "unknown"
			local summary = (comment.body or ""):match("[^\n]*") or ""
			return string.format("@%s: %s", author, summary)
		end,
	}, function(comment)
		if comment then
			choose_action(comment)
		end
	end)
end

local function load_diffview_pending_review(view, callback)
	local context = view.octo_pr_context
	local gh = require("octo.gh")
	gh.api.get({
		"repos/{repo}/pulls/{pull_number}/reviews?per_page=100",
		format = { repo = context.repo, pull_number = context.number },
		opts = {
			cb = gh.create_callback({
				success = function(data)
					local ok, reviews = pcall(vim.json.decode, data)
					local viewer = is_present(vim.g.octo_viewer) and vim.g.octo_viewer:lower() or nil
					view.octo_pending_review = nil
					if ok then
						for _, review in ipairs(reviews or {}) do
							local login = review.user and review.user.login
							if review.state == "PENDING" and viewer and login and login:lower() == viewer then
								view.octo_pending_review = review
								break
							end
						end
					end
					view.octo_pending_review_loaded = true
					render_diffview_review_comments(view)
					if callback then
						callback(view.octo_pending_review)
					end
				end,
			}),
		},
	})
end

local function start_diffview_pending_review(view, callback)
	local context = view.octo_pr_context
	local gh = require("octo.gh")
	gh.api.post({
		"repos/{repo}/pulls/{pull_number}/reviews",
		format = { repo = context.repo, pull_number = context.number },
		f = { commit_id = context.commit_id },
		opts = {
			cb = gh.create_callback({
				success = function(data)
					local ok, review = pcall(vim.json.decode, data)
					if not ok or not review.id or not review.node_id then
						vim.notify("GitHub created a review but returned invalid metadata", vim.log.levels.ERROR)
						return
					end
					view.octo_pending_review = review
					view.octo_pending_review_loaded = true
					if callback then
						callback(review)
					end
				end,
			}),
		},
	})
end

local function submit_diffview_pending_review(view, event)
	local review = view.octo_pending_review
	local event_labels = {
		APPROVE = "Approve review",
		COMMENT = "Submit review comments",
		REQUEST_CHANGES = "Request changes",
	}
	local context = vim.tbl_extend("force", view.octo_pr_context, {
		editor_title_full = " "
			.. event_labels[event]
			.. (event == "REQUEST_CHANGES" and " · summary required " or " · optional summary "),
		allow_empty = event ~= "REQUEST_CHANGES",
	})
	open_diffview_comment_editor(context, { "" }, function(body)
		local gh = require("octo.gh")
		local endpoint = review and "repos/{repo}/pulls/{pull_number}/reviews/{review_id}/events"
			or "repos/{repo}/pulls/{pull_number}/reviews"
		local fields = { event = event, body = body }
		if not review then
			fields.commit_id = context.commit_id
		end
		gh.api.post({
			endpoint,
			format = { repo = context.repo, pull_number = context.number, review_id = review and review.id or "" },
			f = fields,
			opts = {
				cb = gh.create_callback({
					success = function()
						view.octo_pending_review = nil
						vim.notify(event_labels[event] .. " submitted to GitHub", vim.log.levels.INFO)
						refresh_diffview_review_comments(view)
					end,
				}),
			},
		})
	end)
end

local function diffview_pending_review_actions()
	local view = require("diffview.lib").get_current_view()
	if not view or not view.octo_pr_context then
		return
	end
	local function choose(review)
		view.octo_pending_review = review
		local actions = { "Approve", "Comment", "Request changes" }
		vim.ui.select(actions, { prompt = "Submit PR review" }, function(action)
			if action == "Approve" then
				submit_diffview_pending_review(view, "APPROVE")
			elseif action == "Comment" then
				submit_diffview_pending_review(view, "COMMENT")
			elseif action == "Request changes" then
				submit_diffview_pending_review(view, "REQUEST_CHANGES")
			end
		end)
	end

	if view.octo_pending_review_loaded then
		choose(view.octo_pending_review)
	else
		load_diffview_pending_review(view, choose)
	end
end

local function post_pending_diffview_review_comment(context, body, review)
	local gh = require("octo.gh")
	local query
	local raw_fields = {
		query = "",
		reviewId = review.node_id,
		body = body,
		path = context.path,
		side = context.side,
	}
	local typed_fields = { line = context.end_line }
	if context.start_line ~= context.end_line then
		query = [[
mutation($reviewId: ID!, $body: String!, $path: String!, $line: Int!, $side: DiffSide!, $startLine: Int!, $startSide: DiffSide!) {
  addPullRequestReviewThread(input: {pullRequestReviewId: $reviewId, body: $body, path: $path, line: $line, side: $side, startLine: $startLine, startSide: $startSide}) { thread { id } }
}
]]
		typed_fields.startLine = context.start_line
		raw_fields.startSide = context.side
	else
		query = [[
mutation($reviewId: ID!, $body: String!, $path: String!, $line: Int!, $side: DiffSide!) {
  addPullRequestReviewThread(input: {pullRequestReviewId: $reviewId, body: $body, path: $path, line: $line, side: $side}) { thread { id } }
}
]]
	end
	raw_fields.query = query
	gh.api.graphql({
		f = raw_fields,
		F = typed_fields,
		opts = {
			cb = gh.create_callback({
				success = function()
					vim.notify("Added comment to pending GitHub review", vim.log.levels.INFO)
					refresh_diffview_review_comments(context.diffview)
				end,
			}),
		},
	})
end

local function post_diffview_review_comment(context, body)
	if context.diffview and not context.diffview.octo_pending_review_loaded then
		load_diffview_pending_review(context.diffview, function()
			post_diffview_review_comment(context, body)
		end)
		return
	end
	local pending_review = context.diffview and context.diffview.octo_pending_review
	if pending_review then
		post_pending_diffview_review_comment(context, body, pending_review)
		return
	end
	if context.diffview then
		start_diffview_pending_review(context.diffview, function(review)
			post_pending_diffview_review_comment(context, body, review)
		end)
		return
	end
	local gh = require("octo.gh")
	local fields = {
		body = body,
		commit_id = context.commit_id,
		path = context.path,
		side = context.side,
	}
	local typed_fields = { line = context.end_line }
	if context.start_line ~= context.end_line then
		fields.start_side = context.side
		typed_fields.start_line = context.start_line
	end

	gh.api.post({
		"repos/{repo}/pulls/{pull_number}/comments",
		format = {
			repo = context.repo,
			pull_number = context.number,
		},
		f = fields,
		F = typed_fields,
		opts = {
			cb = gh.create_callback({
				success = function()
					vim.notify("Posted GitHub review comment", vim.log.levels.INFO)
					refresh_diffview_review_comments(context.diffview)
				end,
				failure = function(message)
					vim.notify("Could not post review comment: " .. vim.trim(message), vim.log.levels.ERROR)
				end,
			}),
		},
	})
end

local function selection_is_in_diff_hunk(context)
	if not is_present(context.base_ref) or not is_present(context.head_ref) then
		return false, "Reopen this PR Diffview so its review context can be refreshed"
	end
	local args = {
		"git",
		"diff",
		"--no-ext-diff",
		"--unified=3",
		context.base_ref .. "..." .. context.head_ref,
		"--",
		context.path,
	}
	if is_present(context.other_path) and context.other_path ~= context.path then
		table.insert(args, context.other_path)
	end

	local result = vim.system(args, { text = true, cwd = context.git_root }):wait()
	if result.code ~= 0 then
		return false, "Could not inspect the PR diff: " .. vim.trim(result.stderr or "git diff failed")
	end

	for header in (result.stdout or ""):gmatch("[^\n]+") do
		local left_start, left_count, right_start, right_count =
			header:match("^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@")
		if left_start then
			local hunk_start = tonumber(context.side == "LEFT" and left_start or right_start)
			local count_text = context.side == "LEFT" and left_count or right_count
			local hunk_count = count_text == "" and 1 or tonumber(count_text)
			local hunk_end = hunk_start + hunk_count - 1
			if hunk_count > 0 and context.start_line >= hunk_start and context.end_line <= hunk_end then
				return true
			end
		end
	end

	return false, "GitHub cannot attach a review comment to this selection; select lines within one diff hunk"
end

local function add_diffview_review_comment(is_suggestion)
	local view = require("diffview.lib").get_current_view()
	local pr_context = view and view.octo_pr_context
	local entry = view and view.cur_entry
	local layout = view and view.cur_layout
	if not pr_context or not entry or not layout then
		vim.notify("This Diffview was not opened from an Octo PR", vim.log.levels.WARN)
		return
	end

	local current_win = vim.api.nvim_get_current_win()
	local side, path
	if layout.a and layout.a.id == current_win then
		side = "LEFT"
		path = is_present(entry.oldpath) and entry.oldpath or entry.path
	elseif layout.b and layout.b.id == current_win then
		side = "RIGHT"
		path = entry.path
	else
		vim.notify("Select lines in a Diffview file window first", vim.log.levels.WARN)
		return
	end

	-- The '< and '> marks are only finalized after Visual mode exits. Reading
	-- them from a visual-mode mapping makes the first comment use an empty or
	-- stale range, which GitHub rejects with HTTP 422.
	local start_line = vim.fn.line("v")
	local end_line = vim.api.nvim_win_get_cursor(0)[1]
	if start_line > end_line then
		start_line, end_line = end_line, start_line
	end
	local context = vim.tbl_extend("force", pr_context, {
		diffview = view,
		path = path,
		other_path = side == "LEFT" and entry.path or entry.oldpath,
		side = side,
		start_line = start_line,
		end_line = end_line,
		is_suggestion = is_suggestion,
	})
	local valid, validation_error = selection_is_in_diff_hunk(context)
	if not valid then
		vim.notify(validation_error, vim.log.levels.WARN)
		return
	end
	local context_start = math.max(start_line - 2, 1)
	local context_end = math.min(end_line + 2, vim.api.nvim_buf_line_count(0))
	context.diff_context = {}
	for index, text in ipairs(vim.api.nvim_buf_get_lines(0, context_start - 1, context_end, false)) do
		local line_number = context_start + index - 1
		table.insert(context.diff_context, {
			line = line_number,
			text = text,
			selected = line_number >= start_line and line_number <= end_line,
		})
	end
	local initial_lines = { "" }
	if is_suggestion then
		initial_lines = { "```suggestion" }
		vim.list_extend(initial_lines, vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false))
		table.insert(initial_lines, "```")
	end
	open_diffview_comment_editor(context, initial_lines, function(body)
		post_diffview_review_comment(context, body)
	end)
end

local function set_diffview_comment_mapping(bufnr)
	local ok, view = pcall(require("diffview.lib").get_current_view)
	if not ok or not view or not view.octo_pr_context or not view.cur_layout then
		return
	end
	local layout = view.cur_layout
	local is_diff_buffer = (layout.a and layout.a.file and layout.a.file.bufnr == bufnr)
		or (layout.b and layout.b.file and layout.b.file.bufnr == bufnr)
	if not is_diff_buffer then
		return
	end
	local rendered, render_error = pcall(render_diffview_review_comments, view)
	if not rendered then
		vim.schedule(function()
			vim.notify("Could not render Octo review comments: " .. tostring(render_error), vim.log.levels.ERROR)
		end)
	end
	vim.keymap.set("n", "c", interact_with_diffview_review_comment, {
		buffer = bufnr,
		desc = "Interact with Octo PR comment",
		silent = true,
	})
	vim.keymap.set("n", "r", reply_to_diffview_thread_at_cursor, {
		buffer = bufnr,
		desc = "Reply to Octo PR comment",
		silent = true,
	})
	vim.keymap.set("n", "e", edit_diffview_review_comment, {
		buffer = bufnr,
		desc = "Edit your Octo PR comment",
		silent = true,
	})
	vim.keymap.set("n", "d", delete_diffview_review_comment, {
		buffer = bufnr,
		desc = "Delete your Octo PR comment",
		silent = true,
	})
	vim.keymap.set("n", "p", diffview_pending_review_actions, {
		buffer = bufnr,
		desc = "Manage pending Octo PR review",
		silent = true,
	})
	vim.keymap.set("x", "c", function()
		add_diffview_review_comment(false)
	end, {
		buffer = bufnr,
		desc = "Comment on Octo PR lines",
		silent = true,
	})
	vim.keymap.set("x", "s", function()
		add_diffview_review_comment(true)
	end, {
		buffer = bufnr,
		desc = "Suggest change to Octo PR lines",
		silent = true,
	})
end

local function setup_diffview_comment_mapping()
	vim.api.nvim_create_autocmd("BufEnter", {
		group = vim.api.nvim_create_augroup("OctoDiffviewReviewComment", { clear = true }),
		callback = function(event)
			set_diffview_comment_mapping(event.buf)
		end,
	})
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
	local view = require("diffview.lib").get_current_view()
	if view then
		view.octo_pr_context = {
			repo = base_repo,
			head_repo = head_repo,
			head_branch = pr.headRefName,
			number = buffer.number,
			commit_id = pr.headRefOid,
			base_ref = base,
			head_ref = head,
			git_root = git_stdout({ "rev-parse", "--show-toplevel" }),
		}
		set_diffview_comment_mapping(vim.api.nvim_get_current_buf())
		load_diffview_pending_review(view)
		refresh_diffview_review_comments(view)
	end
end

local function copy_current_pr_branch(branch_kind)
	local utils = require("octo.utils")
	local buffer = utils.get_current_buffer()
	if not buffer or not buffer:isPullRequest() then
		vim.notify("Open an Octo PR buffer first", vim.log.levels.WARN)
		return
	end

	local pr = buffer:pullRequest()
	local branch = branch_kind == "base" and pr.baseRefName or pr.headRefName
	if not is_present(branch) then
		vim.notify("Could not find PR " .. branch_kind .. " branch", vim.log.levels.ERROR)
		return
	end

	vim.fn.setreg("+", branch)
	vim.notify("Copied " .. branch_kind .. " branch: " .. branch, vim.log.levels.INFO)
end

local function update_pr_branch(rebase)
	local buffer = require("octo.utils").get_current_buffer()
	if not buffer or not buffer:isPullRequest() then
		vim.notify("Open an Octo PR buffer first", vim.log.levels.WARN)
		return
	end

	local pr = buffer:pullRequest()
	local repo = pr.baseRepository and pr.baseRepository.nameWithOwner or buffer.repo
	local args = {
		pr.number,
		repo = repo,
		opts = {
			cb = require("octo.gh").create_callback({
				success = function()
					vim.notify(
						rebase and "Updated PR branch with rebase" or "Updated PR branch with merge commit",
						vim.log.levels.INFO
					)
					if vim.api.nvim_buf_is_valid(buffer.bufnr) then
						require("octo").load_buffer({ bufnr = buffer.bufnr })
					end
				end,
			}),
		},
	}
	if rebase then
		args.rebase = true
	end
	require("octo.gh").pr.update_branch(args)
end

local function setup_pr_options_diffview()
	local mappings = require("octo.mappings")
	if mappings.pr_options_with_diffview then
		return
	end

	local original_pr_options = mappings.pr_options
	mappings.pr_options_with_diffview = true

	mappings.pr_options = function()
		local original_select = vim.ui.select

		vim.ui.select = function(items, opts, on_choice)
			if opts and opts.prompt == "Select an option:" and vim.tbl_contains(items, "Start Review") then
				local diffview_option = "See Diff Changes"
				local merge_after_checks_option = "Merge PR After Checks Success"
				local update_with_merge_option = "Update with Merge Commit"
				local update_with_rebase_option = "Update with Rebase"
				local copy_feature_branch_option = "Copy Feature Branch Name"
				local copy_base_branch_option = "Copy Base Branch Name"
				local choices = vim.tbl_filter(function(item)
					return item ~= "Update Base Branch"
				end, items)

				for _, extra_option in ipairs({
					diffview_option,
					merge_after_checks_option,
					update_with_merge_option,
					update_with_rebase_option,
					copy_feature_branch_option,
					copy_base_branch_option,
				}) do
					if not vim.tbl_contains(choices, extra_option) then
						table.insert(choices, extra_option)
					end
				end

				return original_select(choices, opts, function(choice, idx)
					if choice == diffview_option then
						open_pr_diffview()
						return
					end
					if choice == merge_after_checks_option then
						require("octo.commands").commands.pr.merge("auto")
						return
					end
					if choice == update_with_merge_option then
						update_pr_branch(false)
						return
					end
					if choice == update_with_rebase_option then
						update_pr_branch(true)
						return
					end
					if choice == copy_feature_branch_option then
						copy_current_pr_branch("feature")
						return
					end
					if choice == copy_base_branch_option then
						copy_current_pr_branch("base")
						return
					end

					on_choice(choice, idx)
				end)
			end

			return original_select(items, opts, on_choice)
		end

		local ok, err = pcall(original_pr_options)
		vim.ui.select = original_select

		if not ok then
			error(err)
		end
	end
end

local function setup_prompt_delete_branch_after_merge()
	local commands = require("octo.commands")
	if commands.merge_pr_with_delete_prompt then
		return
	end

	local config = require("octo.config")
	local gh = require("octo.gh")
	local mutations = require("octo.gh.mutations")
	local utils = require("octo.utils")
	local writers = require("octo.ui.writers")

	commands.merge_pr_with_delete_prompt = true

	local function has_param(params, expected)
		for _, param in ipairs(params) do
			if param == expected then
				return true
			end
		end

		return false
	end

	local function select_message(primary, secondary, fallback)
		if not utils.is_blank(primary) then
			return primary
		end
		if not utils.is_blank(secondary) then
			return secondary
		end

		return fallback
	end

	local function close_pr_buffer(bufnr)
		if vim.api.nvim_buf_is_valid(bufnr) then
			vim.api.nvim_buf_delete(bufnr, { force = true })
		end
	end

	local function delete_head_branch(pr)
		gh.api.graphql({
			query = mutations.delete_branch,
			F = { branchRef = pr.headRef.id },
			opts = {
				cb = gh.create_callback({
					success = function()
						utils.info("Deleted branch " .. pr.headRefName)
					end,
				}),
			},
		})
	end

	local function prompt_delete_head_branch(pr, after_choice)
		if utils.is_blank(pr.headRef) or utils.is_blank(pr.headRef.id) then
			utils.info("Branch is already deleted")
			after_choice()
			return
		end

		vim.ui.select({ "Delete branch", "Keep branch" }, {
			prompt = "Delete branch " .. pr.headRefName .. "?",
		}, function(choice)
			if choice == "Delete branch" then
				delete_head_branch(pr)
			end
			after_choice()
		end)
	end

	commands.merge_pr = function(...)
		local buffer = utils.get_current_buffer()
		if not buffer or not buffer:isPullRequest() then
			return
		end

		local pr = buffer:pullRequest()
		local params = table.pack(...)
		local conf = config.values
		local explicit_delete = has_param(params, "delete")
		local explicit_nodelete = has_param(params, "nodelete")
		local use_queue = has_param(params, "queue") or has_param(params, "auto")

		local merge_method = conf.default_merge_method
		for _, param in ipairs(params) do
			if utils.merge_method_to_flag[param] then
				merge_method = param
				break
			end
		end

		local opts = {
			buffer.number,
			repo = pr.baseRepository.nameWithOwner,
			["delete-branch"] = explicit_delete,
		}
		opts[merge_method] = true

		if use_queue then
			opts.auto = true
		end

		opts.opts = {
			cb = function(output, stderr, exit_code)
				if exit_code == 0 then
					utils.info(select_message(stderr, output, "Pull request merged successfully"))
				else
					utils.error(select_message(stderr, output, "Failed to merge pull request"))
				end

				writers.write_state(buffer.bufnr)

				if exit_code == 0 and not explicit_delete and not explicit_nodelete and not use_queue then
					prompt_delete_head_branch(pr, function()
						close_pr_buffer(buffer.bufnr)
					end)
				elseif exit_code == 0 then
					close_pr_buffer(buffer.bufnr)
				end
			end,
		}

		gh.pr.merge(opts)
	end
end

local function open_url(url)
	if vim.ui.open then
		vim.ui.open(url)
		return
	end

	vim.fn["netrw#BrowseX"](url, 0)
end

local function current_line_url()
	local line = vim.api.nvim_get_current_line()
	local cursor_col = vim.api.nvim_win_get_cursor(0)[2] + 1
	local candidates = {}

	local from = 1
	while from <= #line do
		local start_col, end_col, label, url, after = line:find("%[([^%]]+)%]%((https?://[^%)%s]+)%)()", from)
		if not start_col then
			break
		end

		if start_col == 1 or line:sub(start_col - 1, start_col - 1) ~= "!" then
			table.insert(candidates, {
				url = url,
				start_col = start_col,
				end_col = end_col,
				label_end_col = start_col + #label - 1,
			})
		end
		from = after
	end

	from = 1
	while from <= #line do
		local start_col, end_col, raw_url, after = line:find("(https?://[%w%-%._~:/%?#%[%]@!%$&'%(%)%*%+,;=%%]+)()", from)
		if not start_col then
			break
		end

		local url = raw_url:gsub("[%)%].,;:]+$", "")
		table.insert(candidates, {
			url = url,
			start_col = start_col,
			end_col = math.min(end_col, start_col + #url - 1),
			label_end_col = start_col + #url - 1,
		})
		from = after
	end

	if #candidates == 0 then
		return nil
	end

	table.sort(candidates, function(a, b)
		local function score(candidate)
			if cursor_col >= candidate.start_col and cursor_col <= candidate.label_end_col then
				return 0
			end
			if cursor_col >= candidate.start_col and cursor_col <= candidate.end_col then
				return 1
			end
			return math.abs(cursor_col - candidate.start_col) + 2
		end

		return score(a) < score(b)
	end)

	return candidates[1].url
end

local function open_current_octo_url()
	local url = current_line_url()
	if not url then
		vim.notify("No URL found on current line", vim.log.levels.WARN)
		return
	end

	open_url(url)
end

local project_dashboard = {
	bufnr = nil,
	project = nil,
	items = {},
	row_cells = {},
	columns = {},
	filter = "",
}

local project_dashboard_ns = vim.api.nvim_create_namespace("OctoProjectDashboard")

local function display_slice(value, width)
	value = value or ""
	if vim.fn.strdisplaywidth(value) <= width then
		return value .. string.rep(" ", width - vim.fn.strdisplaywidth(value))
	end
	local result = ""
	for index = 0, vim.fn.strchars(value) - 1 do
		local candidate = result .. vim.fn.strcharpart(value, index, 1)
		if vim.fn.strdisplaywidth(candidate .. "…") > width then
			break
		end
		result = candidate
	end
	return result .. "…" .. string.rep(" ", math.max(0, width - vim.fn.strdisplaywidth(result .. "…")))
end

local function project_item_status(item, field_id)
	for _, value in ipairs(vim.tbl_get(item, "fieldValues", "nodes") or {}) do
		if value.field and value.field.id == field_id and value.name then
			return value.name
		end
	end
	return "No status"
end

local function dashboard_item_at_cursor()
	if vim.api.nvim_get_current_buf() ~= project_dashboard.bufnr then
		return nil
	end
	local cursor = vim.api.nvim_win_get_cursor(0)
	for _, cell in ipairs(project_dashboard.row_cells[cursor[1]] or {}) do
		if cursor[2] >= cell.start_col and cursor[2] < cell.end_col then
			return cell.item
		end
	end
	return nil
end

local function render_project_dashboard()
	local bufnr = project_dashboard.bufnr
	local project = project_dashboard.project
	if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) or not project then
		return
	end

	local columns = vim.deepcopy(vim.tbl_get(project, "columns", "options") or {})
	table.insert(columns, { id = false, name = "No status" })
	project_dashboard.columns = columns
	local grouped = {}
	for _, column in ipairs(columns) do
		grouped[column.name] = {}
	end
	for _, item in ipairs(project_dashboard.items) do
		local content = item.content
		local haystack = content and table.concat({ content.title or "", tostring(content.number or ""),
			vim.tbl_get(content, "repository", "nameWithOwner") or "" }, " "):lower() or ""
		if content and (project_dashboard.filter == "" or haystack:find(project_dashboard.filter:lower(), 1, true)) then
			local status = project_item_status(item, project.columns.id)
			grouped[status] = grouped[status] or {}
			table.insert(grouped[status], item)
		end
	end
	for _, items in pairs(grouped) do
		table.sort(items, function(left, right)
			return (left.content.number or 0) > (right.content.number or 0)
		end)
	end

	local width = 34
	local gap = "  "
	local lines = {
		string.format("  %s  ·  %s", project.title, project.owner.login),
		string.format("  %d items%s", #project_dashboard.items,
			project_dashboard.filter ~= "" and "  ·  filter: " .. project_dashboard.filter or ""),
		"  <CR> open   a add issue   s move   / filter   r refresh   gx browser   q close",
		"",
	}
	project_dashboard.row_cells = {}

	local headers = {}
	local rules = {}
	local max_items = 0
	for _, column in ipairs(columns) do
		table.insert(headers, display_slice(string.format(" %s (%d)", column.name, #(grouped[column.name] or {})), width))
		table.insert(rules, string.rep("─", width))
		max_items = math.max(max_items, #(grouped[column.name] or {}))
	end
	table.insert(lines, table.concat(headers, gap))
	table.insert(lines, table.concat(rules, gap))

	for row = 1, max_items do
		local cards = {}
		local cells = {}
		local byte_col = 0
		for _, column in ipairs(columns) do
			local item = (grouped[column.name] or {})[row]
			local label = ""
			if item then
				local content = item.content
				local kind = content.__typename == "PullRequest" and "PR" or (content.__typename == "DraftIssue" and "Draft" or "#")
				label = kind == "#" and string.format(" #%d %s", content.number, content.title)
					or string.format(" %s %s%s", kind, content.number and "#" .. content.number .. " " or "", content.title)
			end
			local rendered = display_slice(label, width)
			if item then
				table.insert(cells, { start_col = byte_col, end_col = byte_col + #rendered, item = item })
			end
			table.insert(cards, rendered)
			byte_col = byte_col + #rendered + #gap
		end
		table.insert(lines, table.concat(cards, gap))
		project_dashboard.row_cells[#lines] = cells
	end
	if max_items == 0 then
		table.insert(lines, "  No project items match the current filter.")
	end

	vim.bo[bufnr].modifiable = true
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.bo[bufnr].modifiable = false
	vim.api.nvim_buf_clear_namespace(bufnr, project_dashboard_ns, 0, -1)
	vim.api.nvim_buf_add_highlight(bufnr, project_dashboard_ns, "Title", 0, 0, -1)
	vim.api.nvim_buf_add_highlight(bufnr, project_dashboard_ns, "Comment", 1, 0, -1)
	vim.api.nvim_buf_add_highlight(bufnr, project_dashboard_ns, "Comment", 2, 0, -1)
	vim.api.nvim_buf_add_highlight(bufnr, project_dashboard_ns, "OctoStateOpen", 4, 0, -1)
end

local project_items_query = [[
query($id: ID!, $after: String) {
  node(id: $id) {
    ... on ProjectV2 {
      items(first: 100, after: $after) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          content {
            __typename
            ... on Issue { id number title state url repository { nameWithOwner } }
            ... on PullRequest { id number title state url repository { nameWithOwner } }
            ... on DraftIssue { id title }
          }
          fieldValues(first: 50) {
            nodes {
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
                optionId
                field { ... on ProjectV2SingleSelectField { id name } }
              }
            }
          }
        }
      }
    }
  }
}
]]

local project_dashboard_query = [[
query($owner: String!, $name: String!) {
  repository(owner: $owner, name: $name) {
    projects: projectsV2(first: 100) {
      nodes { ...ProjectDashboard }
    }
  }
  viewer {
    projects: projectsV2(first: 100) {
      nodes { ...ProjectDashboard }
    }
    organizations(first: 100) {
      nodes {
        login
        projects: projectsV2(first: 100) {
          pageInfo { hasNextPage endCursor }
          nodes { ...ProjectDashboard }
        }
      }
    }
  }
}

fragment ProjectDashboard on ProjectV2 {
  id
  title
  url
  closed
  number
  owner {
    ... on User { login }
    ... on Organization { login }
  }
  columns: field(name: "Status") {
    ... on ProjectV2SingleSelectField {
      id
      options { id name }
    }
  }
}
]]

local organization_projects_query = [[
query($login: String!, $after: String) {
  organization(login: $login) {
    projects: projectsV2(first: 100, after: $after) {
      pageInfo { hasNextPage endCursor }
      nodes {
        id
        title
        url
        closed
        number
        owner { ... on Organization { login } }
        columns: field(name: "Status") {
          ... on ProjectV2SingleSelectField {
            id
            options { id name }
          }
        }
      }
    }
  }
}
]]

local function fetch_organization_project_pages(login, cursor, accumulated, done)
	local gh = require("octo.gh")
	local fields = { query = organization_projects_query, login = login }
	if cursor then
		fields.after = cursor
	end
	gh.api.graphql({
		f = fields,
		opts = { cb = gh.create_callback({
			success = function(output)
				local ok, response = pcall(vim.json.decode, output)
				local connection = ok and vim.tbl_get(response, "data", "organization", "projects") or nil
				if not connection then
					done(accumulated)
					return
				end
				vim.list_extend(accumulated, connection.nodes or {})
				if connection.pageInfo.hasNextPage then
					fetch_organization_project_pages(login, connection.pageInfo.endCursor, accumulated, done)
				else
					done(accumulated)
				end
			end,
			failure = function()
				done(accumulated)
			end,
		}) },
	})
end

local function fetch_project_items(project, done, cursor, accumulated)
	local gh = require("octo.gh")
	local fields = { query = project_items_query, id = project.id }
	if cursor then
		fields.after = cursor
	end
	gh.api.graphql({
		f = fields,
		opts = { cb = gh.create_callback({
			success = function(output)
				local ok, response = pcall(vim.json.decode, output)
				local items = ok and vim.tbl_get(response, "data", "node", "items") or nil
				if not items then
					vim.notify("Could not read GitHub project items", vim.log.levels.ERROR)
					return
				end
				accumulated = accumulated or {}
				vim.list_extend(accumulated, items.nodes or {})
				if items.pageInfo.hasNextPage then
					fetch_project_items(project, done, items.pageInfo.endCursor, accumulated)
				else
					done(accumulated)
				end
			end,
			failure = function(stderr)
				vim.notify("Could not load GitHub project. Ensure gh has the read:project scope.\n" .. vim.trim(stderr or ""), vim.log.levels.ERROR)
			end,
		}) },
	})
end

local function refresh_project_dashboard()
	if not project_dashboard.project then
		return
	end
	vim.notify("Refreshing GitHub project…", vim.log.levels.INFO)
	fetch_project_items(project_dashboard.project, function(items)
		project_dashboard.items = items
		render_project_dashboard()
	end)
end

local function open_dashboard_item()
	local item = dashboard_item_at_cursor()
	local content = item and item.content
	local repo = content and vim.tbl_get(content, "repository", "nameWithOwner")
	if not repo or not content.number then
		vim.notify("This project card cannot be opened in Octo", vim.log.levels.WARN)
		return
	end
	local width = math.max(60, math.floor(vim.o.columns * 0.9))
	local height = math.max(20, math.floor(vim.o.lines * 0.85))
	local placeholder = vim.api.nvim_create_buf(false, true)
	local winid = vim.api.nvim_open_win(placeholder, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2) - 1,
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = "rounded",
		title = string.format(" %s #%d · :w save · C comment · la/ld labels · aa/ad assignees · q close ", repo, content.number),
		title_pos = "center",
	})
	local utils = require("octo.utils")
	local ok, err
	if content.__typename == "PullRequest" then
		ok, err = pcall(utils.get_pull_request, content.number, repo)
	else
		ok, err = pcall(utils.get_issue, content.number, repo)
	end
	if not ok then
		if vim.api.nvim_win_is_valid(winid) then
			vim.api.nvim_win_close(winid, true)
		end
		vim.notify("Could not open project item: " .. tostring(err), vim.log.levels.ERROR)
		return
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local function map(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
	end
	map("q", function()
		if vim.api.nvim_win_is_valid(winid) then
			vim.api.nvim_win_close(winid, true)
		end
	end, "Close project item popup")
	map("C", "<cmd>Octo comment add<CR>", "Add GitHub comment")
	map("la", "<cmd>Octo label add<CR>", "Add GitHub label")
	map("ld", "<cmd>Octo label remove<CR>", "Remove GitHub label")
	map("aa", "<cmd>Octo assignee add<CR>", "Add GitHub assignee")
	map("ad", "<cmd>Octo assignee remove<CR>", "Remove GitHub assignee")
end

local function move_dashboard_item()
	local item = dashboard_item_at_cursor()
	if not item then
		vim.notify("Move the cursor onto a project card first", vim.log.levels.WARN)
		return
	end
	local project = project_dashboard.project
	vim.ui.select(project.columns.options, { prompt = "Move to status:", format_item = function(option)
		return option.name
	end }, function(option)
		if not option then
			return
		end
		local mutation = string.format(require("octo.gh.mutations").update_project_v2_item,
			project.id, item.id, project.columns.id, option.id)
		local gh = require("octo.gh")
		gh.api.graphql({ query = mutation, opts = { cb = gh.create_callback({ success = function()
			vim.notify("Moved project card to " .. option.name, vim.log.levels.INFO)
			refresh_project_dashboard()
		end }) } })
	end)
end

local function create_dashboard_issue_editor(repo, status)
	local width = math.max(60, math.floor(vim.o.columns * 0.7))
	local height = math.max(14, math.floor(vim.o.lines * 0.55))
	local bufnr = vim.api.nvim_create_buf(false, true)
	local winid = vim.api.nvim_open_win(bufnr, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2) - 1,
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = "rounded",
		title = string.format(" New issue · %s · %s · first line is title · :w create ", repo, status.name),
		title_pos = "center",
	})
	vim.bo[bufnr].buftype = "acwrite"
	vim.bo[bufnr].bufhidden = "wipe"
	vim.bo[bufnr].swapfile = false
	vim.bo[bufnr].filetype = "markdown"
	vim.api.nvim_buf_set_name(bufnr, "octo-project-new-issue://" .. repo)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "", "", "" })
	vim.bo[bufnr].modified = false
	vim.cmd("startinsert")

	local submitting = false
	vim.api.nvim_create_autocmd("BufWriteCmd", {
		buffer = bufnr,
		callback = function()
			if submitting then
				return
			end
			local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
			local title = vim.trim(lines[1] or "")
			if title == "" then
				vim.notify("The issue title cannot be empty", vim.log.levels.WARN)
				return
			end
			local body = table.concat(vim.list_slice(lines, 3), "\n")
			local owner, name = require("octo.utils").split_repo(repo)
			local gh = require("octo.gh")
			submitting = true
			gh.api.graphql({
				query = [[query($owner: String!, $name: String!) { repository(owner: $owner, name: $name) { id } }]],
				F = { owner = owner, name = name },
				opts = { cb = gh.create_callback({
					success = function(output)
						local ok, response = pcall(vim.json.decode, output)
						local repository_id = ok and vim.tbl_get(response, "data", "repository", "id") or nil
						if not repository_id then
							submitting = false
							vim.notify("Could not resolve repository " .. repo, vim.log.levels.ERROR)
							return
						end
						gh.api.graphql({
							query = [[
mutation($repositoryId: ID!, $title: String!, $body: String!) {
  createIssue(input: {repositoryId: $repositoryId, title: $title, body: $body}) {
    issue { id number }
  }
}
]],
							f = { repositoryId = repository_id, title = title, body = body },
							opts = { cb = gh.create_callback({
								success = function(created_output)
									local created_ok, created_response = pcall(vim.json.decode, created_output)
									local issue = created_ok and vim.tbl_get(created_response, "data", "createIssue", "issue") or nil
									if not issue then
										submitting = false
										vim.notify("GitHub did not return the created issue", vim.log.levels.ERROR)
										return
									end
									local project = project_dashboard.project
									local add_mutation = string.format(require("octo.gh.mutations").add_project_v2_item, issue.id, project.id)
									gh.api.graphql({ query = add_mutation, opts = { cb = gh.create_callback({
										success = function(added_output)
											local added_ok, added_response = pcall(vim.json.decode, added_output)
											local item_id = added_ok and vim.tbl_get(added_response, "data", "addProjectV2ItemById", "item", "id") or nil
											if not item_id then
												submitting = false
												vim.notify(string.format("Created %s#%d, but could not add it to the project", repo, issue.number), vim.log.levels.WARN)
												return
											end
											local status_mutation = string.format(require("octo.gh.mutations").update_project_v2_item,
												project.id, item_id, project.columns.id, status.id)
											gh.api.graphql({ query = status_mutation, opts = { cb = gh.create_callback({
												success = function()
													if vim.api.nvim_win_is_valid(winid) then
														vim.api.nvim_win_close(winid, true)
													end
													vim.notify(string.format("Created %s#%d in %s", repo, issue.number, status.name), vim.log.levels.INFO)
													refresh_project_dashboard()
												end,
												failure = function(stderr)
													submitting = false
													vim.notify("Issue created and added, but its status could not be set:\n" .. vim.trim(stderr or ""), vim.log.levels.WARN)
													refresh_project_dashboard()
												end,
											}) } })
										end,
										failure = function(stderr)
											submitting = false
											vim.notify("Issue created, but could not be added to the project:\n" .. vim.trim(stderr or ""), vim.log.levels.WARN)
										end,
									}) } })
								end,
								failure = function(stderr)
									submitting = false
									vim.notify("Could not create issue:\n" .. vim.trim(stderr or ""), vim.log.levels.ERROR)
								end,
							}) },
						})
					end,
					failure = function(stderr)
						submitting = false
						vim.notify("Could not resolve repository:\n" .. vim.trim(stderr or ""), vim.log.levels.ERROR)
					end,
				}) },
			})
		end,
	})
	vim.keymap.set("n", "q", function()
		if vim.api.nvim_win_is_valid(winid) then
			vim.api.nvim_win_close(winid, true)
		end
	end, { buffer = bufnr, silent = true, desc = "Cancel new GitHub issue" })
end

local function dashboard_status_at_cursor()
	if vim.api.nvim_get_current_buf() ~= project_dashboard.bufnr then
		return nil
	end
	local cursor = vim.api.nvim_win_get_cursor(0)
	if cursor[1] < 5 then
		return nil
	end
	local column_index = math.floor((vim.fn.virtcol(".") - 1) / 36) + 1
	local status = project_dashboard.columns[column_index]
	return status and status.id and status or nil
end

local function add_dashboard_issue(initial_status)
	local repositories = {}
	local seen = {}
	local current_repo = require("octo.utils").get_remote_name()
	if current_repo then
		seen[current_repo] = true
		table.insert(repositories, current_repo)
	end
	for _, item in ipairs(project_dashboard.items) do
		local repo = vim.tbl_get(item, "content", "repository", "nameWithOwner")
		if repo and not seen[repo] then
			seen[repo] = true
			table.insert(repositories, repo)
		end
	end
	table.sort(repositories)
	table.insert(repositories, "Enter another repository…")

	local function choose_status(repo)
		if initial_status then
			create_dashboard_issue_editor(repo, initial_status)
			return
		end
		vim.ui.select(project_dashboard.project.columns.options, {
			prompt = "Initial project status:",
			format_item = function(status) return status.name end,
		}, function(status)
			if status then
				create_dashboard_issue_editor(repo, status)
			end
		end)
	end
	vim.ui.select(repositories, { prompt = "Create issue in repository:" }, function(repo)
		if not repo then
			return
		end
		if repo == "Enter another repository…" then
			vim.ui.input({ prompt = "Repository (owner/name): " }, function(value)
				if value and value:match("^[^/]+/[^/]+$") then
					choose_status(value)
				elseif value then
					vim.notify("Expected repository in owner/name form", vim.log.levels.WARN)
				end
			end)
		else
			choose_status(repo)
		end
	end)
end

local function open_project_dashboard_buffer(project, items)
	vim.cmd("tabnew")
	local bufnr = vim.api.nvim_get_current_buf()
	project_dashboard.bufnr = bufnr
	project_dashboard.project = project
	project_dashboard.items = items
	project_dashboard.filter = ""
	vim.bo[bufnr].buftype = "nofile"
	vim.bo[bufnr].bufhidden = "wipe"
	vim.bo[bufnr].swapfile = false
	vim.bo[bufnr].filetype = "octo_project"
	vim.bo[bufnr].modifiable = false
	vim.api.nvim_buf_set_name(bufnr, "octo-project://" .. project.owner.login .. "/" .. project.number)
	vim.wo.wrap = false
	vim.wo.cursorline = true
	vim.wo.number = false
	vim.wo.relativenumber = false

	local function map(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
	end
	map("<CR>", open_dashboard_item, "Open project item in Octo")
	map("a", function()
		add_dashboard_issue(dashboard_status_at_cursor())
	end, "Add issue to GitHub project")
	map("s", move_dashboard_item, "Move project item to another status")
	map("r", refresh_project_dashboard, "Refresh GitHub project")
	map("/", function()
		vim.ui.input({ prompt = "Filter project items: ", default = project_dashboard.filter }, function(value)
			if value ~= nil then
				project_dashboard.filter = vim.trim(value)
				render_project_dashboard()
			end
		end)
	end, "Filter GitHub project")
	map("gx", function()
		local item = dashboard_item_at_cursor()
		open_url(item and item.content and item.content.url or project.url)
	end, "Open project item in browser")
	map("q", "<cmd>tabclose<CR>", "Close GitHub project")
	render_project_dashboard()
end

local function open_project_dashboard()
	local utils = require("octo.utils")
	local repo = utils.get_remote_name()
	if not repo then
		vim.notify("Could not determine the current GitHub repository", vim.log.levels.ERROR)
		return
	end
	local owner, name = utils.split_repo(repo)
	local gh = require("octo.gh")
	gh.api.graphql({
		query = project_dashboard_query,
		F = { owner = owner, name = name },
		opts = { cb = gh.create_callback({
			success = function(output)
				local ok, response = pcall(vim.json.decode, output)
				local projects, seen = {}, {}
				local function add_sources(sources)
					for _, source in ipairs(sources) do
						for _, project in ipairs(source) do
							if not seen[project.id] then
								seen[project.id] = true
								table.insert(projects, project)
							end
						end
					end
				end
				local function choose_project()
					projects = vim.tbl_filter(function(project)
						return not project.closed and project.columns and project.columns.id
					end, projects)
					table.sort(projects, function(left, right)
						if left.owner.login == right.owner.login then
							return left.number > right.number
						end
						return left.owner.login:lower() < right.owner.login:lower()
					end)
					if #projects == 0 then
						vim.notify("No open GitHub Projects v2 with a Status field were found", vim.log.levels.WARN)
						return
					end
					vim.ui.select(projects, { prompt = "Open GitHub project:", format_item = function(project)
						return string.format("%s/%d · %s", project.owner.login, project.number, project.title)
					end }, function(project)
						if project then
							fetch_project_items(project, function(items)
								open_project_dashboard_buffer(project, items)
							end)
						end
					end)
				end
				if not ok then
					choose_project()
					return
				end

				add_sources({
					vim.tbl_get(response, "data", "repository", "projects", "nodes") or {},
					vim.tbl_get(response, "data", "viewer", "projects", "nodes") or {},
				})
				local pending = 0
				for _, organization in ipairs(vim.tbl_get(response, "data", "viewer", "organizations", "nodes") or {}) do
					local connection = organization.projects or {}
					add_sources({ connection.nodes or {} })
					if connection.pageInfo and connection.pageInfo.hasNextPage then
						pending = pending + 1
						fetch_organization_project_pages(organization.login, connection.pageInfo.endCursor, {}, function(more)
							add_sources({ more })
							pending = pending - 1
							if pending == 0 then
								choose_project()
							end
						end)
					end
				end
				if pending == 0 then
					choose_project()
				end
			end,
			failure = function(stderr)
				vim.notify("Could not list GitHub projects. Run: gh auth refresh -s read:project\n" .. vim.trim(stderr or ""), vim.log.levels.ERROR)
			end,
		}) },
	})
end

function M.setup()
	setup_highlights()

	require("octo").setup({
		picker = "default",
		enable_builtin = true,
		default_to_projects_v2 = true,
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

		-- ── Changed-files panel ───────────────────────────────────────────────
		file_panel = {
			size  = 10,
			icons = true, -- requires nvim-web-devicons or mini.icons
		},

		poll = {
			enabled = true,
			interval = 10000,
			notify_on_refresh = true,
			notify_on_change = true,
		},
	})
	setup_issue_completion_metadata()
	setup_diffview_comment_mapping()
	setup_pr_options_diffview()
	setup_prompt_delete_branch_after_merge()
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
	vim.keymap.set("n", "<leader>Hb", open_project_dashboard, { desc = "GitHub project dashboard", silent = true })
	vim.keymap.set("n", "<leader>Hr", octo("review start"), { desc = "Octo start review", silent = true })
	vim.keymap.set("n", "<leader>HR", octo("review resume"), { desc = "Octo resume review", silent = true })
	vim.keymap.set("n", "<leader>Hq", octo("review close"), { desc = "Octo close review", silent = true })
	vim.keymap.set("n", "<leader>Hs", function()
		require("octo.utils").create_base_search_command({ include_current_repo = true })
	end, { desc = "Octo search current repo", silent = true })
	vim.api.nvim_create_user_command("Myprs", open_my_prs, { desc = "Octo list open PRs authored by me" })
	vim.api.nvim_create_user_command("Allprs", open_all_prs, { desc = "Octo list open PRs involving me" })
	vim.api.nvim_create_user_command("OctoProjectDashboard", open_project_dashboard, {
		desc = "Open a GitHub Projects v2 dashboard",
	})
	vim.api.nvim_create_user_command("GitHubNotificationsStart", start_github_notification_polling, {
		desc = "Start polling unread GitHub notifications",
	})
	vim.api.nvim_create_user_command("GitHubNotificationsStop", function()
		stop_github_notification_polling(true)
	end, { desc = "Stop polling GitHub notifications" })
	vim.api.nvim_create_user_command("GitHubNotificationsPoll", function()
		poll_github_notifications(true)
	end, { desc = "Check GitHub notifications now" })
	vim.api.nvim_create_user_command("GitHubNotificationsStatus", function()
		vim.notify(
			string.format(
				"GitHub notification polling: %s · baseline: %s · unread threads: %d",
				notification_timer and "running" or "stopped",
				notification_baseline_ready and "ready" or "loading",
				vim.tbl_count(notification_versions)
			),
			vim.log.levels.INFO
		)
	end, { desc = "Show GitHub notification polling status" })
	vim.keymap.set("n", "<leader>HN", function()
		poll_github_notifications(true)
	end, { desc = "Poll GitHub notifications", silent = true })

	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = vim.api.nvim_create_augroup("GitHubNotificationPolling", { clear = true }),
		callback = function()
			stop_github_notification_polling(false)
		end,
	})
	start_github_notification_polling()

	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("OctoOpenUrl", { clear = true }),
		pattern = "octo",
		callback = function(event)
			vim.keymap.set("i", "#", complete_octo_issue_reference, {
				buffer = event.buf,
				desc = "Complete Octo issue reference",
				expr = true,
				silent = true,
			})
			vim.keymap.set("n", "gx", open_current_octo_url, {
				buffer = event.buf,
				desc = "Open Octo markdown URL",
				silent = true,
			})
		end,
	})
end

return M
