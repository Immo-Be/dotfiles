vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")

require("config.options")
require("config.keymaps")

-- Should be last to ensure all plugins are loaded before lazy.nvim
require("config.lazy")
