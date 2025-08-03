local M = {
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      "windwp/nvim-ts-autotag",                   -- Auto-close tags for HTML, JSX, TSX, Svelte
      "HiPhish/rainbow-delimiters.nvim",          -- Colored matching brackets
      "nvim-treesitter/nvim-treesitter-textobjects", -- Advanced text objects
      "nvim-treesitter/nvim-treesitter-context",  -- Sticky scroll for function/class headers
    },

    build = function()
      require("nvim-treesitter.install").update({ with_sync = true })()
    end,
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "javascript",
          "typescript",
          "tsx", -- TypeScript + React TSX
          "svelte",
          "html",
          "css",
          "json", -- Web dev essentials
          "lua",
          "vim", -- Neovim scripting
          "astro",
        },
        sync_install = false,
        highlight = { enable = true, additional_vim_regex_highlighting = false },
        indent = { enable = true },
        autotag = { enable = true },                                         -- Auto-close & rename JSX/Svelte tags
        rainbow = { enable = true, extended_mode = true, max_file_lines = nil }, -- Colored brackets

        -- Treesitter Textobjects
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
              ["al"] = "@loop.outer",
              ["il"] = "@loop.inner",
              ["aa"] = "@parameter.outer",
              ["ia"] = "@parameter.inner",
            },
          },
          move = {
            enable = true,
            set_jumps = true,
            goto_next_start = {
              ["]m"] = { query = "@function.outer", desc = "Next function" },
              -- these are not used becase we use [ / [c for navigating between changes
              -- ["]c"] = { query = "@class.outer", desc = "Next class" },
              ["]a"] = { query = "@parameter.outer", desc = "Next parameter" },
              ["]r"] = { query = "@return.outer", desc = "Next return statement" },
            },
            goto_next_end = {
              ["]M"] = "@function.outer",
              ["]C"] = "@class.outer",
              ["]A"] = "@parameter.outer",
            },
            goto_previous_start = {
              ["[m"] = { query = "@function.outer", desc = "Previous function" },
              -- ["[c"] = { query = "@class.outer", desc = "Previous class" },
              ["[a"] = { query = "@parameter.outer", desc = "Previous parameter" },
              ["[r"] = { query = "@return.outer", desc = "Previous return statement" }, -- Jump to previous return statement
            },
            goto_previous_end = {
              ["[M"] = "@function.outer",
              ["[C"] = "@class.outer",
              ["[A"] = "@parameter.outer",
            },
          },
          swap = {
            enable = true,
            swap_next = {
              ["<leader>sp"] = "@parameter.inner",
            },
            swap_previous = {
              ["<leader>sP"] = "@parameter.inner",
            },
          },
        },
      })

      -- Enable Sticky Scroll
      require("treesitter-context").setup({
        enable = true, -- Enable sticky scroll
        throttle = true, -- Improve performance
        max_lines = 2, -- Maximum lines to show
        patterns = { -- Define which elements should be sticky
          default = {
            "class",
            "function",
            "method",
          },
        },
      })

      vim.keymap.set("n", "[f", function()
        require("treesitter-context").go_to_context()
      end, { desc = "Jump to sticky function" })
    end,
  },
}

return { M }
