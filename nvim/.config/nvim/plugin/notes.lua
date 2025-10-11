-- plugin/notes.lua

-- files in this directory are loaded automatically by Neovim upon startup. This is different from the "plugins" directory which is used by plugin managers to store and manage plugins.
local notes_file = vim.fn.stdpath('config') .. '/notes.md'

local state = {
  floating = {
    buf = -1,
    win = -1,
  }
}

local function save_buffer(buf)
  if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modified then
    vim.api.nvim_buf_call(buf, function()
      vim.cmd('silent write')
    end)
  end
end

local function hide_window(win, buf)
    vim.api.nvim_win_hide(win)
    save_buffer(buf)
end

local function create_floating_window(opts)
  opts = opts or {}
  local width = opts.width or math.floor(vim.o.columns * 0.8)
  local height = opts.height or math.floor(vim.o.lines * 0.8)

  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  local buf
  if vim.api.nvim_buf_is_valid(opts.buf) then
    buf = opts.buf
  else
    local dir = vim.fn.fnamemodify(notes_file, ':h')
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, 'p')
    end
    buf = vim.fn.bufadd(notes_file)
    vim.fn.bufload(buf)
  end

  local win_config = {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
  }

  local win = vim.api.nvim_open_win(buf, true, win_config)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')

  -- Close with <esc><esc>
  vim.keymap.set("n", "<esc><esc>", function() hide_window(win, buf) end, { silent = true, buffer = buf, nowait = true })

  return { buf = buf, win = win }
end

local function toggle_notes()
  if not vim.api.nvim_win_is_valid(state.floating.win) then
    state.floating = create_floating_window({ buf = state.floating.buf })
  else
    hide_window(state.floating.win, state.floating.buf)
  end
end

vim.keymap.set("n", "<leader><leader>n", toggle_notes, { silent = true, noremap = true, desc = "Toggle notes" })
vim.api.nvim_create_user_command("Notes", toggle_notes, {})
