-- OCaml plumbing. Colours now live in colors.lua, which covers OCaml's modules,
-- constructors, types and labelled arguments as part of the global palette.

-- dune files are S-expressions and nvim-treesitter has no `dune` parser. The
-- scheme grammar reads them accurately enough to be worth borrowing.
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('OCamlFiletypes', { clear = true }),
  pattern = 'dune',
  callback = function(ev)
    if vim.tbl_contains(require('nvim-treesitter.config').get_installed('parsers'), 'scheme') then
      pcall(vim.treesitter.start, ev.buf, 'scheme')
    end
  end,
})
