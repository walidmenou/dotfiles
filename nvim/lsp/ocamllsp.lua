-- OCaml language server (ocaml-lsp-server, `ocamllsp` on PATH via opam).
-- Formatting is delegated to ocamlformat through the server, so it only
-- applies when the project has an .ocamlformat file.
---@type vim.lsp.Config
return {
  cmd = { 'ocamllsp' },
  filetypes = {
    'ocaml',
    'ocaml.interface',
    'ocaml.menhir',
    'ocaml.cram',
    'ocaml.mlx',
    'dune',
    'reason',
  },
  root_markers = {
    'dune-project',
    'dune-workspace',
    'esy.json',
    'package.json',
    '.merlin',
    '.git',
  },
  settings = {
    codelens = { enable = true },
    inlayHints = {
      hintPatternVariables = false,
      hintFunctionParams = false,
      hintLetBindings = false,
    },
    -- Type-on-hover with the full signature rather than a truncated one
    extendedHover = { enable = true },
    -- Surface dune's own diagnostics (build errors from other files)
    duneDiagnostics = { enable = true },
    syntaxDocumentation = { enable = true },
  },
  -- ocamllsp announces support for these; keep the standard on_attach maps
  on_attach = function(client, bufnr)
    -- Semantic tokens paint at a higher priority than treesitter, and ocamllsp
    -- emits @lsp.type.* groups the theme has no colours for — which silently
    -- flattens constructors, modules and types back to black. Treesitter owns
    -- the colours here; the server keeps doing hover, hints and diagnostics.
    client.server_capabilities.semanticTokensProvider = nil

    local function named_opts(desc)
      return { noremap = true, silent = true, desc = desc, buffer = bufnr }
    end

    -- Jump between foo.ml and foo.mli, the OCaml equivalent of clangd's
    -- source/header switch.
    vim.api.nvim_buf_create_user_command(bufnr, 'OCamlSwitchImplIntf', function()
      -- Params are a positional array holding the document URI. A bare string
      -- is what the spec says but JSON-RPC drops it; {uri=...} is rejected.
      client:request('ocamllsp/switchImplIntf', { vim.uri_from_bufnr(bufnr) }, function(err, result)
        if err then
          return vim.notify('switchImplIntf: ' .. tostring(err.message), vim.log.levels.ERROR)
        end
        if not result or #result == 0 then
          return vim.notify('No corresponding .ml/.mli file', vim.log.levels.WARN)
        end
        vim.cmd.edit(vim.uri_to_fname(result[1]))
      end, bufnr)
    end, { desc = 'Switch between .ml and .mli' })

    vim.keymap.set('n', '<leader>oi', '<cmd>OCamlSwitchImplIntf<cr>',
      named_opts('[O]Caml switch [i]mpl/intf'))

    on_attach(client, bufnr)
  end,
}
