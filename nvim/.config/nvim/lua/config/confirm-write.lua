local M = {}

local MAX_DIFF_LINES = 160

local function buffer_lines(bufnr)
	return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
end

local function count_changes(diff_lines)
	local added = 0
	local removed = 0

	for _, line in ipairs(diff_lines) do
		if line:sub(1, 1) == "+" and line:sub(1, 3) ~= "+++" then
			added = added + 1
		elseif line:sub(1, 1) == "-" and line:sub(1, 3) ~= "---" then
			removed = removed + 1
		end
	end

	return added, removed
end

local function unified_diff(old_lines, new_lines)
	local old_text = table.concat(old_lines, "\n")
	local new_text = table.concat(new_lines, "\n")
	local ok, diff = pcall(vim.diff, old_text, new_text, {
		result_type = "unified",
		ctxlen = 3,
		algorithm = "histogram",
	})

	if not ok or not diff or diff == "" then
		return {}
	end

	return vim.split(diff, "\n", { plain = true })
end

local function diff_preview(path, diff_lines)
	local added, removed = count_changes(diff_lines)
	local relative_path = vim.fn.fnamemodify(path, ":~:.")
	local lines = {
		string.format("Confirm write: %s", relative_path),
		string.format("+%d -%d", added, removed),
		"",
	}

	if #diff_lines > MAX_DIFF_LINES then
		vim.list_extend(lines, vim.list_slice(diff_lines, 1, MAX_DIFF_LINES))
		table.insert(lines, "")
		table.insert(lines, string.format("... %d more diff lines hidden", #diff_lines - MAX_DIFF_LINES))
	else
		vim.list_extend(lines, diff_lines)
	end

	return lines
end

local function open_preview(lines)
	local width = math.min(100, math.max(50, vim.o.columns - 8))
	local height = math.min(math.max(12, math.floor(vim.o.lines * 0.55)), #lines)
	local buf = vim.api.nvim_create_buf(false, true)

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].modifiable = false
	vim.bo[buf].filetype = "diff"

	local win = vim.api.nvim_open_win(buf, false, {
		relative = "editor",
		width = width,
		height = height,
		row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
		col = math.max(0, math.floor((vim.o.columns - width) / 2)),
		style = "minimal",
		border = "rounded",
		title = " Write changes? ",
		title_pos = "center",
	})

	return win
end

local function is_octo_buffer(bufnr)
	return vim.bo[bufnr].filetype == "octo" and vim.api.nvim_buf_get_name(bufnr):match("^octo://") ~= nil
end

local function remember_octo_lines(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) or not is_octo_buffer(bufnr) then
		return
	end

	vim.b[bufnr].confirm_write_saved_lines = buffer_lines(bufnr)
end

local function should_confirm(bufnr)
	if vim.g.confirm_write_changes == false or vim.b[bufnr].confirm_write_changes == false then
		return false
	end

	if not is_octo_buffer(bufnr) then
		return false
	end

	if vim.bo[bufnr].readonly or vim.bo[bufnr].binary then
		return false
	end

	return vim.b[bufnr].confirm_write_saved_lines ~= nil
end

local function confirm_write(bufnr)
	if not should_confirm(bufnr) then
		return true
	end

	local path = vim.api.nvim_buf_get_name(bufnr)
	local diff_lines = unified_diff(vim.b[bufnr].confirm_write_saved_lines, buffer_lines(bufnr))
	if vim.tbl_isempty(diff_lines) then
		return true
	end

	local win = open_preview(diff_preview(path, diff_lines))
	vim.cmd("redraw")

	local choice = vim.fn.confirm("Write these changes?", "&Write\n&Cancel", 2)
	if vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
	end

	if choice ~= 1 then
		vim.api.nvim_err_writeln("Write cancelled")
		return false
	end

	return true
end

function M.setup()
	local group = vim.api.nvim_create_augroup("ConfirmWriteOcto", { clear = true })

	vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
		group = group,
		pattern = { "octo://*", "octo" },
		callback = function(args)
			vim.defer_fn(function()
				if vim.api.nvim_buf_is_valid(args.buf) and not vim.bo[args.buf].modified then
					remember_octo_lines(args.buf)
				end
			end, 100)
		end,
	})

	vim.api.nvim_create_autocmd("BufWritePost", {
		group = group,
		pattern = "octo://*",
		callback = function(args)
			vim.defer_fn(function()
				remember_octo_lines(args.buf)
			end, 100)
		end,
	})

	vim.api.nvim_create_user_command("ConfirmWrite", function(opts)
		if confirm_write(vim.api.nvim_get_current_buf()) then
			local command = opts.bang and "write!" or "write"
			if opts.args ~= "" then
				command = command .. " " .. opts.args
			end
			vim.cmd(command)
		end
	end, {
		bang = true,
		complete = "file",
		desc = "Write after confirming the current buffer changes",
		nargs = "*",
	})

	vim.api.nvim_create_user_command("ConfirmWriteToggle", function()
		vim.g.confirm_write_changes = vim.g.confirm_write_changes == false
		vim.notify(
			string.format("Confirm write changes: %s", vim.g.confirm_write_changes and "enabled" or "disabled"),
			vim.log.levels.INFO
		)
	end, { desc = "Toggle confirmation before writing changed files" })

	vim.cmd([[
		cnoreabbrev <expr> w getcmdtype() == ':' && getcmdline() ==# 'w' && &filetype ==# 'octo' && expand('%') =~# '^octo://' ? 'ConfirmWrite' : 'w'
		cnoreabbrev <expr> w! getcmdtype() == ':' && getcmdline() ==# 'w!' && &filetype ==# 'octo' && expand('%') =~# '^octo://' ? 'ConfirmWrite!' : 'w!'
		cnoreabbrev <expr> write getcmdtype() == ':' && getcmdline() ==# 'write' && &filetype ==# 'octo' && expand('%') =~# '^octo://' ? 'ConfirmWrite' : 'write'
		cnoreabbrev <expr> write! getcmdtype() == ':' && getcmdline() ==# 'write!' && &filetype ==# 'octo' && expand('%') =~# '^octo://' ? 'ConfirmWrite!' : 'write!'
	]])
end

return M
