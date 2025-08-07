return {
  "nvimtools/none-ls.nvim",
  dependencies = {
    "nvimtools/none-ls-extras.nvim",
  },
  config = function()
    local null_ls = require("null-ls")

    null_ls.setup({
      sources = {
        null_ls.builtins.formatting.stylua,
        null_ls.builtins.formatting.prettierd,
      },
    })

    vim.keymap.set("n", "<leader><leader>f", function()
      vim.lsp.buf.format({
        filter = function(client)
          print("client.name =", client.name)
          return client.name == "null-ls"
        end,
        timeout_ms = 2000,
      })
    end, { desc = "Format with null-ls" })
  end,
}
