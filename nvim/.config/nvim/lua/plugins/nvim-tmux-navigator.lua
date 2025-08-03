return {
    "christoomey/vim-tmux-navigator",
    lazy = false, -- Ensure it's always loaded
  keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>",  desc = "Move left" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>",  desc = "Move down" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>",    desc = "Move up" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Move right" },
      { "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Move to last" },
    }
}

