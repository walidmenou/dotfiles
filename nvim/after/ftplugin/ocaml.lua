-- Typing `(*` opens a comment and closes it: `(*  *)`, cursor between the
-- spaces. Applies to .ml and .mli, both of which are filetype `ocaml`.
--
-- Two earlier attempts are worth recording, since both look correct and are not:
--
--   * an expr mapping on `*` that checks whether the previous character is `(`.
--     Inside an insert-mode expr mapping the character just typed has not been
--     committed to the buffer, so the look-behind reads one character stale: it
--     misses `(*` entirely and fires on the `*` in `( * )`.
--   * an InsertCharPre autocommand. It sees the buffer correctly, but cannot
--     edit it (textlock), so the insert has to be deferred with vim.schedule —
--     and anything typed in the meantime lands first. `(*hello` came out as
--     `(hello*  *)`.
--
-- A two-character mapping is resolved by the key handler itself, so the whole
-- expansion is atomic. The cost is that `(` waits for 'timeoutlen' (300ms) to
-- see whether a `*` follows; continuous typing resolves it on the next key.
--
-- `( * )`, OCaml's multiplication operator, is unaffected: the space after `(`
-- ends the mapping before it can match.

vim.keymap.set('i', '(*', '(*  *)<Left><Left><Left>', {
  buffer = true,
  desc = 'Open and close an OCaml comment',
})

-- Say something if this project never opted in to ocamlformat, rather than
-- letting format-on-save quietly do nothing.
require('ocamlformat').check(0)

-- ─────────────────────────────────────────────────────────────────────────────
-- Build and REPL. <leader>o is the OCaml namespace.
-- ─────────────────────────────────────────────────────────────────────────────
local repl = require('ocaml-repl')
local compile = require('compile-mode')

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { buffer = true, silent = true, desc = desc })
end

-- Build and test go through the compile terminal, so <leader>r re-runs the last
-- one from anywhere and errors land in a buffer you can scroll.
local function dune(args)
  return function() vim.cmd('C dune ' .. args) end
end

map('n', '<leader>ob', dune('build'), '[O]Caml [b]uild')
map('n', '<leader>ot', dune('test'), '[O]Caml [t]est')
map('n', '<leader>ox', dune('exec ' .. vim.fn.expand('%:t:r') .. '.exe'), '[O]Caml e[x]ec this file')
map('n', '<leader>oc', dune('build @check'), '[O]Caml [c]heck (typecheck only)')

map('n', '<leader>ou', repl.toggle, 'Toggle [u]top')
map('n', '<leader>oe', repl.send_phrase, 'Send phrase to utop')
map('x', '<leader>oe', function()
  vim.cmd('normal! \27') -- leave visual so '< '> are set
  repl.send_selection()
end, 'Send selection to utop')
map('n', '<leader>oE', repl.send_buffer, 'Send whole buffer to utop')
map('n', '<leader>oR', repl.restart, '[R]estart utop')
