on_attach = function(client, bufnr)

  local function named_opts(desc)
    return { noremap = true, silent = true, desc = desc, buffer = bufnr }
  end

  -- LSP
  vim.keymap.set('n', 'gs', require('telescope.builtin').lsp_dynamic_workspace_symbols,
    named_opts('[G]oto [S]ymbols lsp'))
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, named_opts('[G]o [d]efinition'))
  vim.keymap.set("n", "[e", function() vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR }) end,
    named_opts("Prev [E]rror"))
  vim.keymap.set("n", "]e", function() vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR }) end,
    named_opts("Next [E]rror"))
  vim.keymap.set("n", "<leader>d", function()
    vim.fn.setqflist({}, 'r', { title = "Diagnostics" })
    vim.diagnostic.setqflist({ severity = { min = vim.diagnostic.severity.WARN } })
  end, named_opts("[D]iagnostics"))
  vim.keymap.set("n", "<leader>D",
    function()
      vim.fn.setqflist({}, 'r', { title = "Diagnostics" })
      vim.diagnostic.setqflist({ severity = vim.diagnostic.severity.ERROR })
    end,
    named_opts("[D]iagnostics"))
  vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format, named_opts("[l]sp [f]ormat"))
  vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, named_opts("[H]elp signature"))
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Format on save, via whichever language server offers formatting: ocamlformat
-- through ocamllsp, rustfmt through rust_analyzer, clang-format through clangd.
-- No formatting plugin — the project's own formatter config stays authoritative.
-- ─────────────────────────────────────────────────────────────────────────────
local format_group = vim.api.nvim_create_augroup('FormatOnSave', { clear = true })

vim.api.nvim_create_autocmd('LspAttach', {
  group = format_group,
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or not client:supports_method('textDocument/formatting') then
      return
    end
    -- One autocommand per buffer, even when several servers attach to it.
    vim.api.nvim_clear_autocmds({ group = format_group, event = 'BufWritePre', buffer = args.buf })
    vim.api.nvim_create_autocmd('BufWritePre', {
      group = format_group,
      buffer = args.buf,
      desc = 'Format with the language server before writing',
      callback = function(ev)
        if vim.b[ev.buf].format_on_save == false then return end
        vim.lsp.buf.format({ bufnr = ev.buf, id = client.id, async = false, timeout_ms = 3000 })
      end,
    })
  end,
})

-- Escape hatch for a buffer you do not want rewritten.
vim.api.nvim_create_user_command('NoFormatOnSave', function()
  vim.b.format_on_save = false
  vim.notify('format on save disabled for this buffer')
end, { desc = 'Disable format on save for this buffer' })

-- Diagnostics stay out of the text: signs in the gutter only.
-- (Was vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, ...), which is
-- deprecated on nvim 0.12 and printed a warning on every startup.)
vim.diagnostic.config({
  underline = false,
  virtual_text = false,
  -- virtual_text = {
  --   spacing = 2,
  --   min = "Error",
  -- },
  -- No W/E letters scattered down the gutter either. Errors are still very
  -- much reachable: the statusline carries the counts, ]e / [e jump between
  -- them, <leader>sl floats the one under the cursor, <leader>d fills quickfix.
  signs = false,
  severity_sort = true,
})
