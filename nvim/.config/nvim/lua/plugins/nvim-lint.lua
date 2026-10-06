local M = {}

function M.setup()
	local lint = require("lint")

	-- Configure linters by filetype
	lint.linters_by_ft = {
		sh = { "shellcheck" },
		bash = { "shellcheck" },
	}

	local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
		group = lint_augroup,
		callback = function(args)
			if not require("config.bigfile").is_large(args.buf) then
				lint.try_lint()
			end
		end,
	})
end

return M
