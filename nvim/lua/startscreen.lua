-- Start screen: the ASCII art from the previous config, plus the version line.
-- Everything else in Neovim's default intro is dropped.

local art = [[
⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⣤⣤⣄⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⣠⡾⠛⠙⢿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⡿⣆⠀⠉⢙⡛⠿⣿⠗⠲⠖⢲⡆
⠀⠀⠀⠀⣠⡾⠋⠀⠀⠀⢸⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣿⣃⡈⠻⣾⣇⠀⠸⠁⠀⢹⡗⠀⠀⣸⡇
⠀⠀⠀⣰⡟⠁⠀⠀⠀⠀⠘⣿⡾⠀⠀⡄⠀⣀⣠⣴⣶⠿⢻⡿⠛⢯⣁⣠⡟⠉⠙⠳⢶⣶⣯⣁⣀⣴⡿⠃
⠀⠀⢠⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡈⣿⣟⣛⣉⣁⣀⣠⡟⠑⠀⠀⣰⠏⠀⠀⠀⠀⠀⠈⠉⠉⠛⠉⠀⠀
⠀⠀⠈⠀⠀⢀⣀⣤⣤⣶⣶⣿⣿⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠛⠛⢶⡄⠀⠀⠀⠀⠀⠀⠀⠀
⠀⢀⣤⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣆⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⢿⡇⠀⠀⠸⡇⢀⣠⣄⡀⠀⠀⠀⠀
⣾⠋⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⢻⡟⣿⣏⡛⠻⠿⠿⠿⠿⠛⠋⣡⣴⣿⠇⠀⠀⠀⣿⠋⣏⠉⢻⣆⠀⠀⠀
⣿⠀⣿⣿⣿⣿⣿⣿⣿⠿⠋⣠⣾⠁⠸⣿⣿⣷⣶⣶⣤⣶⣾⣿⣿⣿⡟⡀⠀⠀⠀⣿⡾⠟⢻⡄⢻⣆⠀⠀
⣿⠀⣿⣧⣉⡉⢉⣉⣤⣴⣿⣿⠏⠀⠀⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠃⠀⠀⠀⣿⠀⠀⣼⠇⢈⣿⠀⠀
⢿⡀⠸⣿⣿⣿⣿⣿⣿⣿⣿⣯⣶⡾⠟⣷⣦⠈⠉⠛⠛⠛⠋⢻⡿⠃⠀⠀⠀⠀⢀⡏⢀⣾⡟⠀⣼⡟⠀⠀
⢸⡇⠀⠈⠛⠿⠿⠿⠿⠛⠉⠙⠿⠿⠿⠛⠁⠀⠀⠀⠀⠀⣴⡿⠁⠀⠀⠀⠀⠀⢸⡿⠛⠉⢀⣼⠟⠀⠀⠀
⠘⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⡿⠋⠀⠀⠀⠀⠀⠀⢠⣿⠁⢀⣴⡿⠋⠀⠀⠀⠀
⠀⢿⡆⠀⠀⠀⠠⣤⣀⠀⠀⠀⠀⠀⠀⠀⣀⣤⡶⠟⠋⠀⠀⠀⠀⠀⠀⠀⢀⣾⡧⠶⠛⠉⠀⠀⠀⠀⠀⠀
⠀⠈⣿⡀⠀⠀⠀⠈⠙⠻⠶⢶⣶⠶⠶⠟⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣾⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠘⢿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠈⠙⢷⣦⣄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣾⠟⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠈⠉⠛⠻⢷⣶⡶⢤⣤⣤⣤⣤⣤⣶⠶⠟⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
]]

local M = {}

local ns = vim.api.nvim_create_namespace('startscreen')

local function content()
  local v = vim.version()
  local lines = vim.split(vim.trim(art), '\n')
  table.insert(lines, '')
  table.insert(lines, ('NVIM v%d.%d.%d'):format(v.major, v.minor, v.patch))
  return lines
end

-- Only take over a genuinely empty start: `nvim` with no file, no stdin pipe,
-- no session being restored.
local function should_draw()
  if vim.fn.argc() > 0 then return false end
  if vim.g.startscreen_disable then return false end
  local buf = vim.api.nvim_get_current_buf()
  if vim.api.nvim_buf_get_name(buf) ~= '' then return false end
  if vim.bo[buf].buftype ~= '' then return false end
  if vim.api.nvim_buf_line_count(buf) > 1 then return false end
  return (vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or '') == ''
end

local function draw()
  if not should_draw() then return end

  local lines = content()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()

  local art_width = 0
  for _, line in ipairs(lines) do
    art_width = math.max(art_width, vim.fn.strdisplaywidth(line))
  end
  local pad_left = math.max(0, math.floor((vim.api.nvim_win_get_width(win) - art_width) / 2))
  local pad_top = math.max(0, math.floor((vim.api.nvim_win_get_height(win) - #lines) / 2))

  local out = {}
  for _ = 1, pad_top do table.insert(out, '') end
  for _, line in ipairs(lines) do
    table.insert(out, line == '' and '' or (string.rep(' ', pad_left) .. line))
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].buflisted = false
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = 'startscreen'

  vim.wo[win].cursorline = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = 'no'
  vim.wo[win].list = false
  vim.wo[win].fillchars = 'eob: '

  vim.api.nvim_set_hl(0, 'StartScreen', { link = 'Comment', default = true })
  for i = pad_top, #out - 1 do
    vim.api.nvim_buf_set_extmark(buf, ns, i, 0, { end_col = #out[i + 1], hl_group = 'StartScreen' })
  end

  pcall(vim.api.nvim_win_set_cursor, win, { math.min(pad_top + 1, #out), 0 })
end

function M.setup()
  -- Drop Neovim's built-in intro; the version line is redrawn below the art.
  vim.opt.shortmess:append('I')

  vim.api.nvim_create_autocmd('VimEnter', {
    group = vim.api.nvim_create_augroup('StartScreen', { clear = true }),
    nested = true,
    callback = draw,
  })
end

return M
