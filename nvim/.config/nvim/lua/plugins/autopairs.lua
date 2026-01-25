return {
	"windwp/nvim-autopairs",
	event = "InsertEnter",
	dependencies = { "hrsh7th/nvim-cmp" },
	config = function()
		local autopairs = require("nvim-autopairs")
		autopairs.setup({
			check_ts = true, -- Enable treesitter integration
			ts_config = {
				lua = { "string" }, -- Don't add pairs in lua string treesitter nodes
				javascript = { "template_string" }, -- Don't add pairs in JS template strings
				java = false, -- Disable for java
			},
			disable_filetype = { "TelescopePrompt", "vim" },
		})

		-- Integration with nvim-cmp
		local cmp_autopairs = require("nvim-autopairs.completion.cmp")
		local cmp = require("cmp")
		cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
	end,
}
