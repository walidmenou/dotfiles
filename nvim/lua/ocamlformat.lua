-- ocamlformat only formats a file if the project it lives in has opted in with
-- an .ocamlformat file. Inside a project (nearest ancestor holding dune-project,
-- .git or .hg) the global config in ~/.config is ignored entirely — so without
-- that file, formatting silently does nothing and the server still reports
-- formatting as supported. That silence is what makes it feel inconsistent.
--
-- This module writes the file, and says something when it is missing.

local M = {}

M.settings = table.concat({
  'profile = conventional',
  '',
}, '\n')

local announced = {}

---Nearest ancestor that ocamlformat would treat as the project root.
function M.project_root(path)
  local marker = vim.fs.find({ 'dune-project', '.git', '.hg' }, { path = path, upward = true })[1]
  return marker and vim.fs.dirname(marker) or nil
end

---The .ocamlformat governing `path`, if any.
function M.find_config(path)
  return vim.fs.find('.ocamlformat', { path = path, upward = true })[1]
end

---Write .ocamlformat at the project root. Returns the path, or nil plus a reason.
---`force` replaces a config that is already governing this file — which is the
---usual reason formatting looks nothing like these settings.
function M.init(path, force)
  path = path or vim.fn.expand('%:p')
  local dir = vim.fn.isdirectory(path) == 1 and path or vim.fs.dirname(path)

  local existing = M.find_config(dir)
  if existing and not force then
    return nil, ('already governed by %s — :OCamlFormatInit! to replace it')
        :format(vim.fn.fnamemodify(existing, ':~'))
  end
  if existing and force then
    local ok, err = pcall(vim.fn.writefile, vim.split(M.settings, '\n'), existing)
    if not ok then return nil, tostring(err) end
    return existing
  end

  local root = M.project_root(dir) or dir
  local target = root .. '/.ocamlformat'
  local ok, err = pcall(vim.fn.writefile, vim.split(M.settings, '\n'), target)
  if not ok then
    return nil, tostring(err)
  end
  return target
end

---Warn once per project per session when formatting would be a no-op.
function M.check(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr or 0)
  if name == '' then return end
  local dir = vim.fs.dirname(name)
  if M.find_config(dir) then return end

  local root = M.project_root(dir) or dir
  if announced[root] then return end
  announced[root] = true

  vim.notify(
    ('no .ocamlformat in %s — formatting will do nothing here.\nRun :OCamlFormatInit to create one.')
    :format(vim.fn.fnamemodify(root, ':~')),
    vim.log.levels.WARN
  )
end

vim.api.nvim_create_user_command('OCamlFormatInit', function(opts)
  local target, reason = M.init(nil, opts.bang)
  if target then
    announced[M.project_root(vim.fs.dirname(target)) or ''] = nil
    vim.notify('wrote ' .. vim.fn.fnamemodify(target, ':~'), vim.log.levels.INFO)
  else
    vim.notify('.ocamlformat not created: ' .. reason, vim.log.levels.WARN)
  end
end, { bang = true, desc = 'Create .ocamlformat at the project root (! replaces an existing one)' })

---Which config is actually formatting this file — the first question worth
---asking when the result does not match the settings you think you chose.
vim.api.nvim_create_user_command('OCamlFormatWhich', function()
  local name = vim.api.nvim_buf_get_name(0)
  local dir = name ~= '' and vim.fs.dirname(name) or vim.fn.getcwd()
  local cfg = M.find_config(dir)
  if not cfg then
    vim.notify(('no .ocamlformat governs %s — formatting does nothing here')
      :format(vim.fn.fnamemodify(name, ':~')), vim.log.levels.WARN)
    return
  end
  vim.notify(('%s\n\n%s'):format(vim.fn.fnamemodify(cfg, ':~'),
    table.concat(vim.fn.readfile(cfg), '\n')), vim.log.levels.INFO)
end, { desc = 'Show the .ocamlformat governing this file, and its contents' })

return M
