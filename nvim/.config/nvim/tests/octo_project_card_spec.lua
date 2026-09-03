local source = debug.getinfo(1, "S").source:sub(2)
local config_root = vim.fn.fnamemodify(source, ":h:h")
local octo = assert(loadfile(config_root .. "/lua/plugins/octo.lua"))()
local card = octo._project_card_test

local function assert_equal(actual, expected, message)
	assert(actual == expected, string.format("%s: expected %s, got %s", message, vim.inspect(expected), vim.inspect(actual)))
end

local function assert_card_shape(rendered, width, message)
	assert_equal(#rendered.lines, 3, message .. " row count")
	for index, line in ipairs(rendered.lines) do
		assert_equal(vim.fn.strdisplaywidth(line), width, string.format("%s row %d width", message, index))
		assert(vim.trim(line) ~= "", string.format("%s row %d must not be empty", message, index))
	end
end

local base = {
	id = "item-1",
	content = {
		number = 2508,
		title = "Bug shot 7b - highlight the background across the complete viewport",
		state = "OPEN",
		updatedAt = "2026-09-03T10:00:00Z",
		repository = { nameWithOwner = "ubilabs/example" },
		labels = { nodes = { { name = "bug", color = "d73a4a" }, { name = "frontend", color = "0366d6" } } },
		assignees = { nodes = { { login = "immo" } } },
		milestone = { title = "CFS Req275" },
	},
}

local now = vim.fn.strptime("%Y-%m-%dT%H:%M:%SZ", "2026-09-03T12:00:00Z")
local long = card.render(base, "To Do", 34, now)
assert_card_shape(long, 34, "long title")
assert(long.lines[1]:find("%.%.%."), "long title must use an ASCII ellipsis")
assert(long.lines[2]:find("bug", 1, true), "labels must appear on row two")
assert(long.lines[2]:find("CFS Req275", 1, true), "milestone must appear on row two")
assert(long.lines[3]:find("open", 1, true), "text status must appear on row three")
assert(long.lines[3]:match("2h%s*$"), "age must be right-aligned on row three")

local missing = vim.deepcopy(base)
missing.content.title = "Small fix"
missing.content.updatedAt = nil
missing.content.labels = { nodes = {} }
missing.content.assignees = { nodes = {} }
missing.content.milestone = nil
local sparse = card.render(missing, "No status", 34, now)
assert_card_shape(sparse, 34, "missing metadata")
assert(sparse.lines[2]:find("no labels", 1, true), "missing labels need textual fallback")
assert(sparse.lines[3]:find("unassigned", 1, true), "missing assignee needs textual fallback")
assert(sparse.lines[3]:match("%-%s*$"), "missing timestamp needs a compact fallback")

local narrow = card.render(base, "Blocked", 16, now)
assert_card_shape(narrow, 16, "narrow card")

local wide_char = card.truncate("ab界界界cd", 8)
assert(vim.fn.strdisplaywidth(wide_char) <= 8, "double-width truncation must respect terminal display width")
assert(wide_char:find("%.%.%."), "truncated double-width text must use an ellipsis")

vim.cmd("qa!")
