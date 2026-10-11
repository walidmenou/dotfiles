-- A utop window, and a way to throw code at it.
--
-- Modelled on compile-mode: one long-lived terminal buffer, kept in a side
-- split, fed with nvim_chan_send. `dune utop` is preferred over bare `utop`
-- because it loads the project's own libraries, which is what makes the REPL
-- useful for testing the thing you are actually writing.

local M = {}

local state = { buf = nil, win = nil, ready = false }

local function project_root(path)
  local marker = vim.fs.find({ 'dune-project', 'dune-workspace' }, { path = path, upward = true })[1]
  return marker and vim.fs.dirname(marker) or nil
end

---`..`, `../..`, or `.` — the way back from a directory to one of its ancestors.
local function path_up_to(from, ancestor)
  if from == ancestor then return '.' end
  local rest = from:sub(#ancestor + 2)
  local _, depth = rest:gsub('[^/]+', '')
  return (string.rep('../', depth):gsub('/$', ''))
end

---Where to start the REPL, decided from a specific buffer's file. Passing the
---buffer explicitly matters: by the time the split exists, the current buffer is
---the empty terminal scratch, whose path is nvim's cwd — which is only the
---project root by luck, and otherwise gives you a utop with none of your code in
---it.
local function repl_command(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr or 0)
  local here = file ~= '' and vim.fs.dirname(file) or vim.fn.getcwd()
  local root = project_root(here)
  if root and vim.fn.executable('dune') == 1 then
    -- Start in the file's own directory so `open_in "input"` finds the file
    -- sitting next to the source, exactly as it would for the built program,
    -- and hand dune the project root so the project's libraries get loaded.
    -- (Starting at the root instead, then issuing #cd, races utop's readline:
    -- the directive and whatever follows it arrive together and one is lost.)
    return { 'dune', 'utop', path_up_to(here, root) }, here
  end
  return { 'utop' }, here
end

local function buf_valid()
  return state.buf and vim.api.nvim_buf_is_valid(state.buf)
end

local function find_win()
  if not buf_valid() then return nil end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == state.buf then return win end
  end
  return nil
end

---Open the utop window (creating the REPL if needed). Returns to the previous
---window, so the cursor never leaves the code.
function M.open()
  local origin = vim.api.nvim_get_current_win()
  -- Resolve these before any window juggling, while the code buffer is current.
  local origin_buf = vim.api.nvim_get_current_buf()
  local cmd, cwd = repl_command(origin_buf)

  local win = find_win()
  if win then
    state.win = win
    return
  end

  vim.cmd('vertical botright split')
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_width(state.win, math.max(60, math.floor(vim.o.columns * 0.42)))

  if buf_valid() then
    vim.api.nvim_win_set_buf(state.win, state.buf)
  else
    -- A fresh scratch buffer first. Splitting shows the *current* buffer, and
    -- jobstart{term=true} converts whatever buffer is current into the terminal
    -- — which would turn the file you are editing into the REPL, name and all.
    local scratch = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(state.win, scratch)

    vim.api.nvim_buf_call(scratch, function()
      vim.fn.jobstart(cmd, { cwd = cwd, term = true })
    end)
    vim.notify(('%s in %s'):format(table.concat(cmd, ' '), vim.fn.fnamemodify(cwd, ':~')))

    state.buf = scratch
    pcall(vim.api.nvim_buf_set_name, state.buf, '*utop*')
    vim.bo[state.buf].buflisted = false

    -- Leaving a terminal window otherwise means reaching for the mouse: the
    -- terminal swallows every key. These are buffer-local, so C-l still clears
    -- the screen in ordinary shells elsewhere.
    local function nav(key, dir)
      vim.keymap.set('t', key, ('<C-\\><C-n><cmd>TmuxNavigate%s<cr>'):format(dir),
        { buffer = state.buf, desc = 'Leave utop, move ' .. dir:lower() })
    end
    nav('<C-h>', 'Left')
    nav('<C-j>', 'Down')
    nav('<C-k>', 'Up')
    nav('<C-l>', 'Right')
    vim.keymap.set('t', '<C-w>', '<C-\\><C-n><C-w>', { buffer = state.buf, desc = 'Window command' })
  end

  vim.wo[state.win].number = false
  vim.wo[state.win].signcolumn = 'no'
  vim.api.nvim_set_current_win(origin)
end

function M.toggle()
  local win = find_win()
  if win then
    vim.api.nvim_win_close(win, false)
    state.win = nil
  else
    M.open()
  end
end

---Kill the REPL so the next open starts a fresh one — the OCaml way of
---picking up a changed library.
function M.restart()
  local win = find_win()
  if win then vim.api.nvim_win_close(win, false) end
  if buf_valid() then vim.api.nvim_buf_delete(state.buf, { force = true }) end
  state.buf, state.win, state.ready = nil, nil, false
  M.open()
end

---`dune utop` builds the project before it prints a prompt. Anything sent
---before then is swallowed with no trace, so block (briefly, once) until the
---prompt shows up.
local function wait_for_prompt()
  if state.ready or not buf_valid() then return state.ready end
  local shown = false
  state.ready = vim.wait(60000, function()
    if not buf_valid() then return true end
    local text = table.concat(vim.api.nvim_buf_get_lines(state.buf, 0, -1, false), '')
    if not shown and not text:find('utop #', 1, true) then
      shown = true
      vim.notify('waiting for utop to build the project…', vim.log.levels.INFO)
    end
    return text:find('utop #', 1, true) ~= nil
  end, 200)
  if not state.ready then
    vim.notify('utop did not come up in time', vim.log.levels.WARN)
    return false
  end

  return state.ready
end

---Send raw text, terminating the phrase if the text does not already.
function M.send(text)
  M.open()
  if not buf_valid() then return end
  if not wait_for_prompt() then return end

  text = vim.trim(text)
  if text == '' then return end
  if not text:match(';;$') then text = text .. ' ;;' end

  local chan = vim.bo[state.buf].channel
  if chan and chan > 0 then
    vim.api.nvim_chan_send(chan, text .. '\n')
    local win = find_win()
    if win then
      vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(state.buf), 0 })
    end
  end
end

---Fallback when no parser is running on the buffer: the surrounding block of
---non-blank lines.
local function paragraph_at_cursor()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local first, last = row, row
  while first > 1 and lines[first - 1]:match('%S') do first = first - 1 end
  while last < #lines and lines[last + 1]:match('%S') do last = last + 1 end
  return table.concat(vim.list_slice(lines, first, last), '\n')
end

---The top-level phrase the cursor sits in, via treesitter — a `let`, a `type`,
---a `module`, whatever encloses the cursor at the outermost level.
local function phrase_at_cursor()
  local ok, node = pcall(vim.treesitter.get_node)
  if not ok or not node then return paragraph_at_cursor() end
  while node:parent() and node:parent():type() ~= 'compilation_unit' do
    node = node:parent()
  end
  return vim.treesitter.get_node_text(node, 0)
end

function M.send_phrase()
  local text = phrase_at_cursor()
  if not text then
    return vim.notify('no phrase under the cursor', vim.log.levels.WARN)
  end
  M.send(text)
end

function M.send_selection()
  local a = vim.fn.getpos("'<")
  local b = vim.fn.getpos("'>")
  local lines = vim.api.nvim_buf_get_text(0, a[2] - 1, a[3] - 1, b[2] - 1,
    math.min(b[3], #vim.fn.getline(b[2])), {})
  M.send(table.concat(lines, '\n'))
end

---Whole buffers go through a file and `#use`, not down the terminal pipe.
---Pasted text is read as a single phrase, so the first `;;` in the buffer ends
---it and everything after is dropped on the floor. `#use` reads the file the way
---the compiler would, phrase by phrase, `;;` and all.
function M.send_buffer()
  M.open()
  if not buf_valid() or not wait_for_prompt() then return end

  local name = vim.api.nvim_buf_get_name(0)
  local stem = name ~= '' and vim.fn.fnamemodify(name, ':t:r') or 'buffer'
  local tmp = ('%s/%s-utop.ml'):format(vim.fn.stdpath('run'), stem)
  vim.fn.writefile(vim.api.nvim_buf_get_lines(0, 0, -1, false), tmp)

  local chan = vim.bo[state.buf].channel
  if chan and chan > 0 then
    vim.api.nvim_chan_send(chan, ('#use "%s";;\n'):format(tmp))
  end
end

return M
