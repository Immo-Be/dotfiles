local M = {}

local function pascal_case(name)
	return (name:gsub("[%-%_ ](%w)", function(c)
		return c:upper()
	end):gsub("^%w", string.upper))
end

local function get_default_parent_dir()
	local bufname = vim.api.nvim_buf_get_name(0)
	if bufname ~= "" then
		return vim.fs.dirname(vim.fn.fnamemodify(bufname, ":p"))
	end

	return vim.fn.getcwd()
end

local function create_component(parent_dir, component_name)
	local component_dir = vim.fs.joinpath(parent_dir, component_name)
	if vim.uv.fs_stat(component_dir) then
		vim.notify("Component folder already exists: " .. component_dir, vim.log.levels.ERROR)
		return
	end

	vim.fn.mkdir(component_dir, "p")

	local tsx_path = vim.fs.joinpath(component_dir, component_name .. ".tsx")
	local css_path = vim.fs.joinpath(component_dir, component_name .. ".module.css")
	local component_fn = pascal_case(component_name)

	vim.fn.writefile({
		'import styles from "./' .. component_name .. '.module.css"',
		"",
		"type Props = {};",
		"",
		"export default function " .. component_fn .. "({}: Props) {",
		"  return (",
		'    <div className={styles.default}>',
		"    </div>",
		"  )",
		"}",
	}, tsx_path)

	vim.fn.writefile({}, css_path)

	vim.notify("Created component: " .. component_dir)
	vim.cmd.edit(vim.fn.fnameescape(tsx_path))
end

local function prompt_component_name(parent_dir)
	vim.ui.input({ prompt = "Component name: " }, function(input)
		if not input or input == "" then
			return
		end

		create_component(parent_dir, input)
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
				local parent_dir = get_default_parent_dir()

				if node then
					local node_path = node:get_id()
					if vim.fn.isdirectory(node_path) == 1 then
						parent_dir = node_path
					else
						parent_dir = vim.fs.dirname(node_path)
					end
				end

				prompt_component_name(parent_dir)
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

	vim.api.nvim_create_user_command("NewComponent", function()
		prompt_component_name(get_default_parent_dir())
	end, { desc = "Create a new React component folder" })
end

return M
