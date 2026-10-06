local M = {}

-- Large generated and minified files can make parsers, language servers, and
-- decoration plugins do substantially more work than reading the file itself.
M.max_bytes = 1024 * 1024
M.max_lines = 20000

local function set_window_options(bufnr)
	for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
		vim.wo[winid].wrap = false
		vim.wo[winid].spell = false
		vim.wo[winid].foldmethod = "manual"
	end
end

local function stop_buffer_services(bufnr)
	pcall(vim.treesitter.stop, bufnr)

	for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
		vim.lsp.buf_detach_client(bufnr, client.id)
	end

	if package.loaded.colorizer then
		pcall(require("colorizer").detach_from_buffer, bufnr)
	end

	if package.loaded.ibl then
		pcall(require("ibl").setup_buffer, bufnr, { enabled = false })
	end

	if package.loaded["rainbow-delimiters"] then
		pcall(require("rainbow-delimiters").disable, bufnr)
	end
end

local function apply(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) or not vim.b[bufnr].bigfile then
		return
	end

	vim.bo[bufnr].swapfile = false
	vim.bo[bufnr].undofile = false
	vim.bo[bufnr].syntax = ""
	vim.bo[bufnr].indentexpr = ""
	vim.bo[bufnr].synmaxcol = 300
	set_window_options(bufnr)
	stop_buffer_services(bufnr)
end

local function mark(bufnr, reason)
	if vim.b[bufnr].bigfile then
		return
	end

	vim.b[bufnr].bigfile = true
	vim.b[bufnr].bigfile_reason = reason
	apply(bufnr)
end

function M.is_large(bufnr)
	bufnr = bufnr or 0
	return vim.b[bufnr].bigfile == true
end

function M.setup()
	local group = vim.api.nvim_create_augroup("BigFileMode", { clear = true })

	-- Detect by bytes before FileType plugins and LSP have a chance to attach.
	vim.api.nvim_create_autocmd("BufReadPre", {
		group = group,
		callback = function(args)
			local stat = vim.uv.fs_stat(args.file)
			if stat and stat.type == "file" and stat.size > M.max_bytes then
				mark(args.buf, string.format("%.1f MiB", stat.size / 1024 / 1024))
			end
		end,
	})

	-- This also covers buffers without a path, such as content read from stdin.
	vim.api.nvim_create_autocmd("BufReadPost", {
		group = group,
		callback = function(args)
			local lines = vim.api.nvim_buf_line_count(args.buf)
			if lines > M.max_lines then
				mark(args.buf, string.format("%d lines", lines))
			end

			if M.is_large(args.buf) and #vim.api.nvim_list_uis() > 0 then
				vim.schedule(function()
					if vim.api.nvim_buf_is_valid(args.buf) and not vim.b[args.buf].bigfile_notified then
						vim.b[args.buf].bigfile_notified = true
						vim.notify(
							"Large-file mode enabled (" .. vim.b[args.buf].bigfile_reason .. ")",
							vim.log.levels.INFO
						)
					end
				end)
			end
		end,
	})

	-- Filetype detection and entering another window can reset local options.
	vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
		group = group,
		callback = function(args)
			apply(args.buf)
			if M.is_large(args.buf) then
				-- Built-in syntax and indent FileType handlers can run after ours.
				vim.schedule(function()
					apply(args.buf)
				end)
			end
		end,
	})

	-- A third-party LSP start should not keep a large buffer attached.
	vim.api.nvim_create_autocmd("LspAttach", {
		group = group,
		callback = function(args)
			if M.is_large(args.buf) then
				vim.lsp.buf_detach_client(args.buf, args.data.client_id)
			end
		end,
	})

	vim.api.nvim_create_user_command("BigFileStatus", function()
		if M.is_large(0) then
			vim.notify("Large-file mode: enabled (" .. (vim.b.bigfile_reason or "manual") .. ")")
		else
			vim.notify("Large-file mode: disabled")
		end
	end, { desc = "Show large-file mode status" })
end

return M
