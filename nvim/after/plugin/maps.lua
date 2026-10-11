-- Telescope

local lga_actions = require("telescope-live-grep-args.actions")
require('telescope').setup {
  theme = "ivy",
  pickers = {
    colorscheme = {
      enable_preview = true
    },
    lsp_references = {
      show_line = false,
      fname_width = 60
    }
  },
  defaults = {
    mappings = {
      i = {
        ["<esc>"] = require('telescope.actions').close
      },
    },
    file_ignore_patterns = { ".git/", "node_modules/" },
    layout_config = {
      horizontal = {
        prompt_position = "top"
      }
    }
  },
  extensions = {
    fzf = {},
    live_grep_args = {
      auto_quoting = true, -- enable/disable auto-quoting
      -- define mappings, e.g.
      mappings = {         -- extend mappings
        i = {
          ["<C-k>"] = lga_actions.quote_prompt({ postfix = " -t" }),
          ["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
          -- freeze the current list and start a fuzzy search in the frozen list
          ["<C-space>"] = lga_actions.to_fuzzy_refine,
        },
      },
      theme = "ivy", -- use ivy theme
    }
  }
}
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "TelescopePrompt", "TelescopeResults" },
  callback = function()
    vim.opt_local.foldenable = false
  end,
})

require('telescope').load_extension('fzf')
require('telescope').load_extension("live_grep_args")

require('gitsigns').setup()

require('mini.basics').setup({
  options = {
    extra_ui = true,
  },
})
require('mini.surround').setup({
  mappings = {
    add = 'ys',
    delete = 'ds',
    find = '',
    find_left = '',
    highlight = '',
    replace = 'cs',
    update_n_lines = '',
  },
  search_method = 'cover_or_next'
})
require('mini.align').setup()

require('mini.ai').setup({
  n_lines = 300,
  search_method = 'cover'
})
require('mini.bufremove').setup({})
require('mini.bracketed').setup({})
require('startscreen').setup()

require('mini.clue').setup({
  window = {
    -- Wait before popping the hint window, like which-key did
    delay = 500,
    width = 'auto'
  },
  triggers = {
    -- Leader triggers
    { mode = 'n', keys = '\\' },
    { mode = 'n', keys = '<Leader>' },
    { mode = 'x', keys = '<Leader>' },
    -- Bracketed
    { mode = 'n', keys = '[' },
    { mode = 'n', keys = ']' },

    -- Built-in completion
    { mode = 'i', keys = '<C-x>' },

    -- `g` key
    { mode = 'n', keys = 'g' },
    { mode = 'x', keys = 'g' },

    -- Marks
    { mode = 'n', keys = "'" },
    { mode = 'n', keys = '`' },
    { mode = 'x', keys = "'" },
    { mode = 'x', keys = '`' },

    -- Registers
    { mode = 'n', keys = '"' },
    { mode = 'x', keys = '"' },
    { mode = 'i', keys = '<C-r>' },
    { mode = 'c', keys = '<C-r>' },

    -- Window commands
    { mode = 'n', keys = '<C-w>' },

    -- `z` key
    { mode = 'n', keys = 'z' },
    { mode = 'x', keys = 'z' },
  },

  clues = {
    -- Enhance this by adding descriptions for <Leader> mapping groups
    require('mini.clue').gen_clues.builtin_completion(),
    require('mini.clue').gen_clues.g(),
    require('mini.clue').gen_clues.marks(),
    require('mini.clue').gen_clues.registers(),
    require('mini.clue').gen_clues.windows(),
    require('mini.clue').gen_clues.z(),
    { mode = 'n', keys = '<leader>b', desc = '+Buffers' },
    { mode = 'n', keys = '<leader>t', desc = '+Tasks' },
    { mode = 's', keys = '<leader>s', desc = '+Show' },
    { mode = 'n', keys = ']',         desc = '+Next' },
    { mode = 'n', keys = '[',         desc = '+Prev' },
  },
})

function named_opts(desc)
  return { noremap = true, silent = true, desc = desc }
end

local opts = { noremap = true, silent = true }

vim.keymap.set('n', '<leader>bd', require('mini.bufremove').delete)

-- Move between splits, and on past the last one into the neighbouring tmux
-- pane. Falls back to plain window movement when nvim is not inside tmux.
vim.keymap.set('n', '<C-h>', '<cmd>TmuxNavigateLeft<cr>', named_opts('Window/pane left'))
vim.keymap.set('n', '<C-j>', '<cmd>TmuxNavigateDown<cr>', named_opts('Window/pane down'))
vim.keymap.set('n', '<C-k>', '<cmd>TmuxNavigateUp<cr>', named_opts('Window/pane up'))
vim.keymap.set('n', '<C-l>', '<cmd>TmuxNavigateRight<cr>', named_opts('Window/pane right'))
vim.keymap.set('n', '<C-q>', '<C-w>q')

-- Swap lines up and down

vim.keymap.set('v', '<C-j>', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', '<C-k>', ":m '<-2<CR>gv=gv")

-- Get out of terminal with my old tmux prefix, good times
vim.keymap.set('t', '<C-a>', '<C-\\><C-n>')

vim.keymap.set('n', '<C-d>', '<C-d>zz', named_opts("Page down (centered)"))
vim.keymap.set('n', '<C-u>', '<C-u>zz', named_opts("Page up (centered)"))

-- Do not yank with x
vim.keymap.set('n', 'x', '"_x', opts)

function ts_grep_from_dir(dir)
  require('telescope.builtin').live_grep({ cwd = dir })
end

function ts_grep_from_buffer_dir()
  local buf_dir = require('telescope.utils').buffer_dir()
  ts_grep_from_dir(buf_dir)
end

local function open_lsp_logs()
  return string.format("<Cmd>term tail -f -n500 %s<CR>", vim.lsp.log.get_filename())
end
vim.keymap.set('n', '<leader>ll', open_lsp_logs(), { desc = "Open [l]sp [l]ogs" })

vim.keymap.set('n', '<leader>f', function()
  local opts = require('telescope.themes').get_ivy {
    previewer = false,
  }
  require('telescope.builtin').find_files(opts)
end, named_opts('[F]ind [f]ile'))

vim.keymap.set('n', '<leader>/', function()
  local opts = require('telescope.themes').get_ivy {
    previewer = true,
  }
  require('telescope').extensions.live_grep_args.live_grep_args(opts)
end, named_opts('Grep Workspace'))

vim.keymap.set('v', '<leader>*', function()
  local opts = require('telescope.themes').get_ivy {
    previewer = true,
  }
  require("telescope-live-grep-args.shortcuts").grep_visual_selection(opts)
end, named_opts('Grep visual selection'))

-- <leader>s for Show
vim.keymap.set('n', '<leader>sl', vim.diagnostic.open_float, named_opts('Line diagnostics'))

vim.keymap.set('n', '<leader><tab>',
  function() require('telescope.builtin').buffers({ sort_mru = true }) end,
  named_opts('Open buffer picker'))

-- <leader>h for help
function edit_neovim()
  require('telescope.builtin').find_files {
    hidden = true,
    cwd = vim.fn.stdpath("config"),
    layout_strategy = 'horizontal',
  }
end

vim.keymap.set('n', '<leader>ho', '<cmd>lua edit_neovim()<cr>', named_opts('[O]pen config dir'))
vim.keymap.set('n', '<leader>hs', '<cmd>source %<cr>', named_opts('Source current buffer'))
vim.keymap.set('n', '<leader>hx', ':.lua<cr>', named_opts('e[x]ecute line lua'))
vim.keymap.set('v', '<leader>hx', ':.lua<cr>', named_opts('e[x]ecute selection lua'))
vim.keymap.set('n', '<leader>h/', function() ts_grep_from_dir('~/.config/nvim') end, named_opts('Grep config dir'))
vim.keymap.set('n', '<leader>hh', require('telescope.builtin').help_tags, named_opts('Help'))

-- Toggle the quickfix window with tab
local toggle_qf = function()
  vim.cmd(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and 'cclose' or 'copen')
end

vim.keymap.set('n', '`', toggle_qf, named_opts('Toggle quickfix'))

-- Forward / Back
vim.keymap.set("n", "]g",         "<cmd>Gitsigns next_hunk<cr>",                                 named_opts("Next hunk"))
vim.keymap.set("n", "[g",         "<cmd>Gitsigns prev_hunk<cr>",                                 named_opts("Prev hunk"))
vim.keymap.set("n", "<leader>gz", '<cmd>Gitsigns reset_hunk<CR>')
vim.keymap.set("n", "<leader>gg", "<cmd>term lazygit<CR>",                                       named_opts("open lazy[g]it"))

vim.keymap.set("n", "<leader>?",  require('telescope.builtin').command_history,                  named_opts("Command history"))

vim.keymap.set('n', 'gf',         '<cmd>vsplit<cr>gF',                                           named_opts("[G]o to [F]ile and line (in vsplit)"))
vim.keymap.set('n', '<leader>nc', '<cmd>silent grep! -Tsh -Tmd nocommit<cr>',                    named_opts("Review [n][c]ommits"))

-- ─────────────────────────────────────────────────────────────────────────────
-- LazyVim muscle memory: the bindings carried over from the previous config,
-- pointed at this config's equivalents.
-- ─────────────────────────────────────────────────────────────────────────────

-- File browser. There is no sidebar tree here; oil edits the directory as if it
-- were a buffer. <leader>e and - both open it, floating over the current window.
vim.keymap.set('n', '<leader>e', function() require('oil').toggle_float() end,
  named_opts('File [e]xplorer'))
vim.keymap.set('n', '<leader>E', '<cmd>Oil<cr>', named_opts('File [E]xplorer (full window)'))

-- Find
vim.keymap.set('n', '<leader>ff', function()
  require('telescope.builtin').find_files(require('telescope.themes').get_ivy { previewer = false })
end, named_opts('[F]ind [f]iles'))
vim.keymap.set('n', '<leader>fr', function()
  require('telescope.builtin').oldfiles(require('telescope.themes').get_ivy {})
end, named_opts('[F]ind [r]ecent'))
vim.keymap.set('n', '<leader>fb', function()
  require('telescope.builtin').buffers({ sort_mru = true })
end, named_opts('[F]ind [b]uffer'))
vim.keymap.set('n', '<leader>,', function()
  require('telescope.builtin').buffers({ sort_mru = true })
end, named_opts('Switch buffer'))

-- Search
vim.keymap.set('n', '<leader>sg', function()
  require('telescope').extensions.live_grep_args.live_grep_args(
    require('telescope.themes').get_ivy { previewer = true })
end, named_opts('[S]earch by [g]rep'))
vim.keymap.set('n', '<leader>sk', function()
  require('telescope.builtin').keymaps(require('telescope.themes').get_ivy {})
end, named_opts('[S]earch [k]eymaps'))
vim.keymap.set('n', '<leader>sh', function()
  require('telescope.builtin').help_tags(require('telescope.themes').get_ivy {})
end, named_opts('[S]earch [h]elp'))

-- Shift + h/l steps through buffers; [b / ]b from mini.bracketed still work, and
-- <leader>, / <leader><tab> open the picker.
vim.keymap.set('n', '<S-h>', '<cmd>bprevious<cr>', named_opts('Prev buffer'))
vim.keymap.set('n', '<S-l>', '<cmd>bnext<cr>', named_opts('Next buffer'))
vim.keymap.set('n', '<leader>bb', '<cmd>e #<cr>', named_opts('Alternate [b]uffer'))

-- Shift + j/k moves ten lines, in normal, visual and operator-pending mode, so
-- d<S-j> deletes ten lines down.
vim.keymap.set({ 'n', 'x', 'o' }, '<S-j>', '10j', named_opts('Down ten lines'))
vim.keymap.set({ 'n', 'x', 'o' }, '<S-k>', '10k', named_opts('Up ten lines'))

-- Which costs the two defaults those keys carried, so they move rather than go.
vim.keymap.set('n', 'gh', vim.lsp.buf.hover, named_opts('Hover (was K)'))
vim.keymap.set({ 'n', 'x' }, '<M-j>', 'J', named_opts('Join lines (was J)'))

-- Keep the selection after an action, so < and > can be held down and a yank
-- does not drop what you had highlighted.
vim.keymap.set('x', '<', '<gv', named_opts('Shift left, keep selection'))
vim.keymap.set('x', '>', '>gv', named_opts('Shift right, keep selection'))
vim.keymap.set('x', 'y', 'ygv', named_opts('Yank, keep selection'))

-- `q` starts a macro recording, which is almost always an accident — that stray
-- "recording @q" in the corner. Recording moves to Q; @ still replays.
vim.keymap.set('n', 'q', '<Nop>', named_opts('disabled — record with Q'))
vim.keymap.set('n', 'Q', 'q', named_opts('Record macro'))

-- Alt+Backspace deletes the previous word. Terminals send Alt as ESC followed by
-- the key, so without this the ESC leaves insert mode and the backspace lands in
-- normal mode. Also mapped on the command line, where the same thing happens.
vim.keymap.set({ 'i', 'c' }, '<M-BS>', '<C-w>', { desc = 'Delete previous word' })

-- Backspace in leading whitespace clears the whole indent and joins with the
-- line above, in one press, the way JetBrains editors do.
vim.keymap.set('i', '<BS>', function()
  local col = vim.fn.col('.') - 1
  local before = vim.api.nvim_get_current_line():sub(1, col)
  if col > 0 and before:match('^%s+$') then
    return '<C-u><BS>'
  end
  return '<BS>'
end, { expr = true, replace_keycodes = true, desc = 'Backspace through indentation in one press' })

-- Code
vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, named_opts('[C]ode [a]ction'))
vim.keymap.set('n', '<leader>cr', vim.lsp.buf.rename, named_opts('[C]ode [r]ename'))
vim.keymap.set('n', '<leader>cf', function() vim.lsp.buf.format({ async = true }) end,
  named_opts('[C]ode [f]ormat'))

-- Quit / write. <leader>w is deliberately left free (it was the window prefix
-- in LazyVim); saving is <C-s> as before.
vim.keymap.set('n', '<leader>qq', '<cmd>qa<cr>', named_opts('[Q]uit all'))
vim.keymap.set({ 'n', 'i', 'x' }, '<C-s>', '<cmd>w<cr><esc>', named_opts('Save file'))

-- Lazy
vim.keymap.set('n', '<leader>L', '<cmd>Lazy<cr>', named_opts('[L]azy'))

-- Toggles (<leader>u namespace, as before)
vim.keymap.set('n', '<leader>ul', function()
  vim.wo.number = not vim.wo.number
end, named_opts('Toggle [l]ine numbers'))
vim.keymap.set('n', '<leader>uh', function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
end, named_opts('Toggle inlay [h]ints'))
vim.keymap.set('n', '<leader>uw', function()
  vim.wo.wrap = not vim.wo.wrap
end, named_opts('Toggle [w]rap'))
-- Light <-> dark: grey and the default Kanso Zen theme.
vim.keymap.set('n', '<leader>uc', function()
  if vim.g.colors_name == 'grey' then
    vim.o.background = 'dark'
    vim.cmd.colorscheme('kanso-zen')
  else
    vim.o.background = 'light'
    vim.cmd.colorscheme('grey')
  end
end, named_opts('Toggle light/dark [c]olorscheme'))

-- Compile mode mappings
package.loaded['compile-mode'] = nil; require('compile-mode').reset()
local compile = require('compile-mode')

vim.keymap.set("n", "<leader>c", require('compile-mode').command, named_opts("Run a command"))
vim.keymap.set("n", "<leader>r", require('compile-mode').recompile, named_opts("Re-run last command"))
vim.keymap.set('n', '<leader>Cb', require('compile-mode').scroll_to_bottom,
  named_opts("Scroll compile buffer to [b]ottom"))
vim.keymap.set('n', '<leader>Ct', require('compile-mode').toggle_window, named_opts("[T]oggle compile buffer"))
vim.keymap.set('n', '<leader>CR', require('compile-mode').reset, named_opts("Reset"))
