require('base')

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
local plugins = {
  {
    'yorickpeterse/nvim-grey',
    lazy = false,
    priority = 900,
    dependencies = { "nvim-telescope/telescope.nvim" },
  },
  {
    -- Default dark theme; the light/dark toggle keeps grey available.
    "webhooked/kanso.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("kanso").setup {
        bold = true,
        italics = false,
        keywordStyle = { italic = false },
        background = {
          dark = "zen",
          light = "pearl"
        },
      }
      vim.o.background = "dark"
      vim.cmd.colorscheme("kanso-zen")
      -- Straight underlines instead of undercurls for diagnostics
      vim.defer_fn(function()
        for _, group in ipairs({
          "DiagnosticUnderlineError",
          "DiagnosticUnderlineWarn",
          "DiagnosticUnderlineInfo",
          "DiagnosticUnderlineHint",
        }) do
          local hl = vim.api.nvim_get_hl(0, { name = group })
          hl.undercurl = false
          hl.underline = true
          hl.bold = false
          vim.api.nvim_set_hl(0, group, hl)
        end
      end, 50)
    end
  },
  {
    -- Alternative dark theme with a fully black background.
    -- Keep it opaque so the black background is independent of the terminal.
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 900,
    config = function()
      local black = "#000000"
      -- Only the dark variants go black. `all` would hit lotus too, which is a
      -- light theme — dark text on a black background.
      local blacken = {
        ui = {
          bg = black,
          bg_dim = black,
          bg_m3 = black,
          bg_m2 = black,
          bg_m1 = black,
          bg_gutter = "none",
        },
      }
      require("kanagawa").setup({
        compile = false,
        transparent = false,
        background = { dark = "wave", light = "lotus" },
        colors = {
          theme = {
            wave = blacken,
            dragon = blacken,
          },
        },
        overrides = function(colors)
          local theme = colors.theme
          -- Same guard for the highlight overrides: leave lotus alone.
          if theme.ui.bg ~= black then return {} end
          return {
            Normal       = { bg = black },
            NormalNC     = { bg = black },
            NormalFloat  = { bg = black },
            FloatBorder  = { bg = black, fg = theme.ui.bg_p2 },
            FloatTitle   = { bg = black },
            SignColumn   = { bg = black },
            StatusLine   = { bg = black },
            StatusLineNC = { bg = black },
            TabLine      = { bg = black },
            TabLineFill  = { bg = black },
            WinBar       = { bg = black },
            WinBarNC     = { bg = black },
            Folded       = { bg = black },
            EndOfBuffer  = { bg = black },
            -- would otherwise be black-on-black now that bg_m* are black
            WinSeparator = { fg = theme.ui.bg_p2, bg = "NONE" },
            TelescopeNormal = { bg = black },
            TelescopeBorder = { bg = black },
          }
        end,
      })
    end,
  },

  {
    -- Makes <C-h/j/k/l> continue past nvim's outermost split into the
    -- neighbouring tmux pane. The tmux half lives in ~/.tmux.conf.
    "christoomey/vim-tmux-navigator",
    lazy = false,
    init = function()
      vim.g.tmux_navigator_no_mappings = 1
      vim.g.tmux_navigator_save_on_switch = 1
    end,
  },

  {
    "j-hui/fidget.nvim",
    opts = {
      -- options
    },
  },

  { 'nvim-mini/mini.nvim', version = '*' },

  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').setup()

      local langs = {
        'ocaml', 'ocaml_interface', 'ocamllex', 'scheme',
        'rust', 'c', 'cpp', 'lua', 'bash', 'python',
        'json', 'toml', 'yaml', 'markdown', 'markdown_inline',
        'diff', 'gitcommit', 'query', 'vim', 'vimdoc',
      }

      -- Install anything missing in the background, once.
      local installed = require('nvim-treesitter.config').get_installed('parsers')
      local missing = vim.tbl_filter(function(lang)
        return not vim.tbl_contains(installed, lang)
      end, langs)
      if #missing > 0 then
        require('nvim-treesitter').install(missing)
      end

      -- Start highlighting per buffer. LaTeX is deliberately absent: VimTeX's
      -- own syntax understands more of a real document than the parser does.
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('TreesitterStart', { clear = true }),
        callback = function(ev)
          local lang = vim.treesitter.language.get_lang(ev.match)
          if not lang or vim.tbl_contains({ 'tex', 'bib' }, ev.match) then return end
          if not vim.tbl_contains(require('nvim-treesitter.config').get_installed('parsers'), lang) then
            return
          end
          pcall(vim.treesitter.start, ev.buf, lang)
        end,
      })
    end,
  },

  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
      {
        "nvim-telescope/telescope-live-grep-args.nvim",
        -- This will not install any breaking changes.
        -- For major updates, this must be adjusted manually.
        version = "^1.0.0",
      },
    }
  },

  'lewis6991/gitsigns.nvim',

  {
    'stevearc/oil.nvim',
    lazy = false,
    enabled = true,
    opts = {
      columns = {
        "size", "mtime"
      },
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      keymaps = {
        ["<C-s>"] = false,
        ["<C-v>"] = { "actions.select", opts = { vertical = true } },
        ["q"] = "actions.close",
        ["<esc>"] = "actions.close",
      },
      view_options = {
        is_always_hidden = function(name, bufnr)
          return false
        end,
        sort = {
          { "mtime", "desc" }
        }
      }
    },
    keys = {
      { "-", "<cmd>lua require('oil').toggle_float()<cr>", desc = "Open file browser" }
    },
  },

  {
    'neovim/nvim-lspconfig',
    lazy = true,
    config = function()
      -- Format on save lives in after/plugin/lsp-config.lua. This spec is
      -- `lazy = true` with nothing to trigger it, so anything placed here never
      -- runs — which is why the original `format_on_save` flag had no effect
      -- either way.
    end
  },

  {
    "lervag/vimtex",
    lazy = false,
    init = function()
      vim.g.vimtex_view_method = "skim"
      vim.g.vimtex_view_skim_sync = 1
      vim.g.vimtex_view_skim_activate = 1
      vim.g.vimtex_view_forward_search_on_start = 0

      vim.g.vimtex_compiler_method = "latexmk"
      vim.g.vimtex_compiler_latexmk = {
        out_dir = "",
        callback = 1,
        continuous = 1,
        executable = "latexmk",
      }

      -- Only warnings-free output is worth a quickfix window
      vim.g.vimtex_quickfix_open_on_warning = 0

      -- Leave nothing but the .tex and the .pdf behind. latexmk needs its aux
      -- files while the document is open (that is what makes recompiles fast),
      -- so they are removed on quit rather than never written.
      -- (g:vimtex_compiler_clean_paths does not apply to the latexmk backend,
      -- which cleans via `latexmk -c`; the extras it misses are swept below.)
      local vimtex_group = vim.api.nvim_create_augroup("VimTexClean", { clear = true })
      vim.api.nvim_create_autocmd("User", {
        pattern = "VimtexEventQuit",
        group = vimtex_group,
        callback = function()
          vim.cmd("VimtexClean")

          -- `latexmk -c` keeps the synctex file, so remove it by hand
          local state = vim.b.vimtex
          local stem
          if type(state) == "table" and state.root and state.name then
            stem = state.root .. "/" .. state.name
          else
            stem = vim.fn.expand("%:p:r")
          end
          for _, path in ipairs({ stem .. ".synctex.gz", stem .. ".synctex(busy)" }) do
            if vim.fn.filereadable(path) == 1 then
              vim.fn.delete(path)
            end
          end
        end,
      })
    end,
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    ---@type Flash.Config
    opts = {
      highlight = {
        backdrop = false,
        matches = false,
      },
      label = {
        style = "overlay"
      }
    },
    -- stylua: ignore
    keys = {
      { "s",     mode = { "n", "x", "o" }, function() require("flash").jump() end,   desc = "Flash" },
      { "<c-s>", mode = { "c" },           function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
  },
  {
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
    config = function()
      local mc = require("multicursor-nvim")
      mc.setup()

      local set = vim.keymap.set

      -- Add or skip cursor above/below the main cursor.
      set({ "n", "x" }, "<leader>K", function() mc.lineAddCursor(-1) end)
      set({ "n", "x" }, "<leader>J", function() mc.lineAddCursor(1) end)
      set({ "n", "x" }, "<leader>K", function() mc.lineSkipCursor(-1) end)
      set({ "n", "x" }, "<leader>J", function() mc.lineSkipCursor(1) end)

      -- Add or skip adding a new cursor by matching word/selection
      set({ "n", "x" }, "<leader>N", function() mc.matchAddCursor(1) end)
      set({ "n", "x" }, "<leader>s", function() mc.matchSkipCursor(1) end)
      set({ "n", "x" }, "<leader>N", function() mc.matchAddCursor(-1) end)
      set({ "n", "x" }, "<leader>S", function() mc.matchSkipCursor(-1) end)

      -- Mappings defined in a keymap layer only apply when there are
      -- multiple cursors. This lets you have overlapping mappings.
      mc.addKeymapLayer(function(layerSet)
        -- Select a different cursor as the main one.
        layerSet({ "n", "x" }, "<left>", mc.prevCursor)
        layerSet({ "n", "x" }, "<right>", mc.nextCursor)

        layerSet({ "n", "x" }, "<C-h>", mc.prevCursor)
        layerSet({ "n", "x" }, "<C-l>", mc.nextCursor)
        layerSet({ "n", "x" }, "<C-k>", mc.prevCursor)
        layerSet({ "n", "x" }, "<C-j>", mc.nextCursor)

        -- Disable and enable cursors.
        set({ "n", "x" }, "<c-q>", mc.toggleCursor)

        -- Align cursor columns.
        set("n", "<leader>a", mc.alignCursors)

        -- Delete the main cursor.
        layerSet({ "n", "x" }, "<leader>x", mc.deleteCursor)

        -- Enable and clear cursors using escape.
        layerSet("n", "<esc>", function()
          if not mc.cursorsEnabled() then
            mc.enableCursors()
          else
            mc.clearCursors()
          end
        end)
      end)

      -- Customize how cursors look.
      local hl = vim.api.nvim_set_hl
      hl(0, "MultiCursorCursor", { reverse = true })
      hl(0, "MultiCursorVisual", { link = "Visual" })
      hl(0, "MultiCursorSign", { link = "SignColumn" })
      hl(0, "MultiCursorMatchPreview", { link = "Search" })
      hl(0, "MultiCursorDisabledCursor", { reverse = true })
      hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
      hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
    end
  }
}

require("lazy").setup(plugins, opts)

require('globals')

vim.api.nvim_create_autocmd("LspAttach", {
  desc = "Setup LSP stuff",
  group = vim.api.nvim_create_augroup("knix-lsp", {}),
  callback = function(ev)
    local buf = ev.buf
    local data = ev.data
    local client_id = data.client_id
    local client = assert(vim.lsp.get_client_by_id(client_id))
    if client:supports_method("textDocument/completion") then
      vim["bo"][buf]["omnifunc"] = "v:lua.vim.lsp.omnifunc"
      vim.lsp.completion.enable(true, client.id, buf, { autotrigger = false })
    end
    -- Inlay hints stay off. ocamllsp annotates pattern variables, let bindings
    -- and parameters, which reads as noise scattered unevenly through a file.
    -- <leader>uh turns them on for the current buffer when they are wanted.
    return nil
  end,
})

vim.lsp.config('*', {
  on_attach = on_attach
})
vim.lsp.enable('rust_analyzer')
vim.lsp.enable('clangd')
-- ocamllsp lives inside the opam switch; only enable it when it is on PATH
if vim.fn.executable('ocamllsp') == 1 then
  vim.lsp.enable('ocamllsp')
end

local run_in_term = function(prefix)
  return function(opts)
    -- Expand % and # BEFORE opening new buffer
    local current = vim.fn.expand "%:p"
    local alt = vim.fn.expand "#:p"
    local cmd = prefix .. opts.args:gsub("%%:p", current):gsub("%%", current):gsub("#", alt)
    vim.cmd "new"
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "hide"
    vim.bo.swapfile = false
    vim.b.no_auto_close = true
    vim.fn.termopen(cmd, {
      on_stdout = function()
        vim.schedule(function()
          vim.cmd [[ stopinsert ]]
          vim.api.nvim_feedkeys("G", "t", false)
        end)
      end,
    })
    vim.api.nvim_buf_set_keymap(0, "n", "q", ":q!<CR>", { noremap = true, silent = true })
  end
end

vim.api.nvim_create_user_command("R", run_in_term(""), { nargs = "+", complete = "shellcmdline" })
vim.keymap.set('n', '<leader>j', function() vim.api.nvim_feedkeys(":C just ", "t", false) end, {})
vim.api.nvim_create_user_command("J", run_in_term("just "), { nargs = "+", complete = "shellcmdline" })
