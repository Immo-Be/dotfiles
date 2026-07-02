local M = {}

local function pascal_case(name)
	local parts = vim.split(name, "-", { trimempty = true })
	for i, part in ipairs(parts) do
		parts[i] = part:gsub("^%w", string.upper)
	end

	return table.concat(parts, "")
end

local function normalize_component_name(name)
	name = vim.trim(name or "")
	if name == "" then
		return nil, "Component name is required"
	end

	if name:find("[/\\:]") or name:find("%.%.", 1, true) then
		return nil, "Component name must not contain path separators"
	end

	local normalized = name
		:gsub("(%u)(%u%l)", "%1-%2")
		:gsub("(%l)(%u)", "%1-%2")
		:gsub("[%s_]+", "-")
		:gsub("[^%w%-]", "-")
		:gsub("%-+", "-")
		:gsub("^%-", "")
		:gsub("%-$", "")
		:lower()

	if normalized == "" then
		return nil, "Component name must contain letters or numbers"
	end

	return normalized
end

local function get_default_anchor_dir()
	local bufname = vim.api.nvim_buf_get_name(0)
	if bufname ~= "" then
		return vim.fs.dirname(vim.fn.fnamemodify(bufname, ":p"))
	end

	return vim.fn.getcwd()
end

local function find_project_root(anchor_dir)
	return vim.fs.root(anchor_dir, {
		".git",
		"package.json",
		"tsconfig.json",
		"vite.config.js",
		"vite.config.ts",
		"next.config.js",
		"next.config.mjs",
	}) or vim.fn.getcwd()
end

local function is_directory(path)
	return path and vim.fn.isdirectory(path) == 1
end

local function is_ignored_components_dir(path)
	local ignored = {
		"/.git/",
		"/node_modules/",
		"/.next/",
		"/dist/",
		"/build/",
	}
	local normalized = "/" .. vim.fs.normalize(path) .. "/"
	for _, segment in ipairs(ignored) do
		if normalized:find(segment, 1, true) then
			return true
		end
	end

	return false
end

local function find_nearest_components_dir(anchor_dir, root)
	local current = vim.fs.normalize(anchor_dir)
	root = vim.fs.normalize(root)

	while current and current ~= "" do
		if vim.fs.basename(current) == "components" and is_directory(current) then
			return current
		end

		local sibling = vim.fs.joinpath(current, "components")
		if is_directory(sibling) then
			return sibling
		end

		if current == root then
			break
		end

		local parent = vim.fs.dirname(current)
		if not parent or parent == current then
			break
		end
		current = parent
	end
end

local function find_components_candidates(root)
	local glob = vim.fs.joinpath(root, "**", "components")
	local matches = vim.fn.glob(glob, false, true)
	local candidates = {}
	local seen = {}

	for _, path in ipairs(matches) do
		path = vim.fs.normalize(path)
		if is_directory(path) and not is_ignored_components_dir(path) and not seen[path] then
			seen[path] = true
			table.insert(candidates, path)
		end
	end

	table.sort(candidates)
	return candidates
end

local function select_components_dir(anchor_dir, callback)
	local root = find_project_root(anchor_dir)
	local nearest = find_nearest_components_dir(anchor_dir, root)
	if nearest then
		callback(nearest)
		return
	end

	local candidates = find_components_candidates(root)
	if #candidates == 0 then
		vim.notify("No components directory found under: " .. root, vim.log.levels.ERROR)
	elseif #candidates == 1 then
		callback(candidates[1])
	else
		vim.ui.select(candidates, {
			prompt = "Select components directory:",
			format_item = function(item)
				return vim.fn.fnamemodify(item, ":~:.")
			end,
		}, callback)
	end
end

local function write_component_files(components_dir, component_name)
	local normalized_name, error_message = normalize_component_name(component_name)
	if not normalized_name then
		vim.notify(error_message, vim.log.levels.ERROR)
		return
	end

	local component_dir = vim.fs.joinpath(components_dir, normalized_name)
	if vim.uv.fs_stat(component_dir) then
		vim.notify("Component folder already exists: " .. component_dir, vim.log.levels.ERROR)
		return
	end

	local tsx_path = vim.fs.joinpath(component_dir, normalized_name .. ".tsx")
	local css_path = vim.fs.joinpath(component_dir, normalized_name .. ".module.css")
	if vim.uv.fs_stat(tsx_path) or vim.uv.fs_stat(css_path) then
		vim.notify("Component files already exist: " .. component_dir, vim.log.levels.ERROR)
		return
	end

	vim.fn.mkdir(component_dir, "p")
	vim.fn.writefile({
		'import styles from "./' .. normalized_name .. '.module.css";',
		"",
		"const " .. pascal_case(normalized_name) .. " = () => {",
		"  return <div></div>;",
		"};",
		"",
		"export default " .. pascal_case(normalized_name) .. ";",
	}, tsx_path)

	vim.fn.writefile({}, css_path)

	vim.notify("Created component: " .. component_dir)
	vim.cmd.edit(vim.fn.fnameescape(tsx_path))
end

local function create_component(anchor_dir, component_name)
	select_components_dir(anchor_dir, function(components_dir)
		if components_dir then
			write_component_files(components_dir, component_name)
		end
	end)
end

local function prompt_component_name(anchor_dir)
	vim.ui.input({ prompt = "Component name: " }, function(input)
		if not input or input == "" then
			return
		end

		create_component(anchor_dir, input)
	end)
end

function M.setup()
	require("neo-tree").setup({
		commands = {
			open_in_finder = function(state)
				local node = state.tree:get_node()
				if not node then
					return
				end

				vim.fn.jobstart({ "open", "-R", node:get_id() }, { detach = true })
			end,
			copy_path = function(state)
				local node = state.tree:get_node()
				if not node then
					return
				end

				local path = node:get_id()
				vim.fn.setreg("+", path)
				vim.fn.setreg("*", path)
				vim.notify("Copied path: " .. path)
			end,
			new_component = function(state)
				local node = state.tree:get_node()
				local anchor_dir = get_default_anchor_dir()

				if node then
					local node_path = node:get_id()
					if vim.fn.isdirectory(node_path) == 1 then
						anchor_dir = node_path
					else
						anchor_dir = vim.fs.dirname(node_path)
					end
				end

				prompt_component_name(anchor_dir)
			end,
		},
		filesystem = {
			follow_current_file = { enabled = true },
			hijack_netrw = true,
			use_libuv_file_watcher = true,
			window = {
				mappings = {
					["O"] = "open_in_finder",
					["Y"] = "copy_path",
					["C"] = "new_component",
				},
			},
			filtered_items = {
				visible = true,
				hide_dotfiles = false,
				hide_gitignored = false,
			},
		},
	})

	vim.keymap.set("n", "<C-b>", ":Neotree toggle right<CR>", { desc = "Toggle Neo-tree" })
	vim.keymap.set("n", "<C-\\>", ":Neotree reveal right<CR>", { desc = "Reveal in Neo-tree" })
	vim.keymap.set("n", "<C-S-e>", ":Neotree focus<CR>", { desc = "Focus Neo-tree" })
	vim.keymap.set("n", "<C-S-b>", ":Neotree close<CR>", { desc = "Close Neo-tree" })

	vim.api.nvim_create_user_command("E", function()
		vim.cmd("Neotree current")
	end, { desc = "Open Neo-tree in current buffer" })

	vim.api.nvim_create_user_command("NewComponent", function(opts)
		local anchor_dir = get_default_anchor_dir()
		if opts.args ~= "" then
			create_component(anchor_dir, opts.args)
		else
			prompt_component_name(anchor_dir)
		end
	end, { desc = "Create a new React component folder", nargs = "*" })
end

return M
