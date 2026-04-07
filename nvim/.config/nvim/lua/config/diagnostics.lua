vim.diagnostic.config({
	virtual_text = true,
	signs = true,
	float = {
		border = "rounded",
		focusable = false,
		source = "always",
	},
	severity_sort = true,
})

vim.opt.numberwidth = 2
