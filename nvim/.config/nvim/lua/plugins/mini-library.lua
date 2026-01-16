return {
  {
    "echasnovski/mini.files",
    version = false,
    config = function()
      local mini_files = require("mini.files")
      mini_files.setup({
        mappings = {
          close       = 'q',
          go_in       = '',
          go_in_plus  = 'L',
          go_out      = 'h',
          go_out_plus = 'H',
          reset       = '<BS>',
          reveal_cwd  = '@',
          show_help   = 'g?',
          synchronize = '=',
          trim_left   = '<',
          trim_right  = '>',
        },
      })
      
      -- Custom 'l' key: open file and close window, or navigate into directory
      vim.api.nvim_create_autocmd('User', {
        pattern = 'MiniFilesBufferCreate',
        callback = function(args)
          local buf_id = args.data.buf_id
          vim.keymap.set('n', 'l', function()
            local fs_entry = mini_files.get_fs_entry()
            if fs_entry and fs_entry.fs_type == 'file' then
              mini_files.go_in()
              vim.schedule(function() mini_files.close() end)
            else
              mini_files.go_in()
            end
          end, { buffer = buf_id })
        end,
      })
    end,
  },
  { 'echasnovski/mini.comment', version = false }
}
