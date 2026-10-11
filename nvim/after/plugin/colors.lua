-- Full-colour layer on top of nvim-grey.
--
-- Treesitter does capture every keyword — `let` is @keyword, `fun` is
-- @keyword.function, `type` is @keyword.type, `open` is @keyword.import. The
-- reason they looked uncoloured is that nvim-grey answers all of those with
-- `Keyword = black + bold`: the theme is deliberately near-monochrome, so the
-- parser's work was landing on rules that paint it black.
--
-- So rather than colour groups language by language, this redefines the base
-- highlight groups the whole editor already funnels into. Treesitter captures
-- link to these by default (@keyword -> Keyword, @function -> Function), and so
-- does classic regex syntax, which means LaTeX and anything without a parser
-- gets the same palette for free.
--
-- Colours are nvim-grey's own, arranged the way light themes conventionally
-- read (keywords warm, functions purple, types cool).

local palette = {
  black       = '#000000',
  background  = '#f2f2f2',
  blue        = '#1561b8',
  green       = '#1c5708',
  red         = '#c4331d',
  grey        = '#5e5e5e',
  dark_yellow = '#b37f02',
  yellow      = '#f9db70',
  orange      = '#a55000',
  purple      = '#5c21a5',
  cyan        = '#007872',
}

-- Base groups: everything else inherits from these.
local base = {
  Keyword      = { fg = palette.red },                  -- let, match, fun, module, if
  Statement    = { link = 'Keyword' },
  Conditional  = { link = 'Keyword' },
  Repeat       = { link = 'Keyword' },
  Exception    = { link = 'Keyword' },
  Include      = { link = 'Keyword' },
  StorageClass = { link = 'Keyword' },
  Structure    = { link = 'Keyword' },
  Typedef      = { link = 'Keyword' },
  Define       = { link = 'Keyword' },
  Boolean      = { link = 'Keyword' },

  Function     = { fg = palette.purple },
  Type         = { fg = palette.cyan },
  Constant     = { fg = palette.blue },
  Number       = { fg = palette.blue },
  Float        = { fg = palette.blue },
  String       = { fg = palette.green },
  Character    = { link = 'String' },
  Comment      = { fg = palette.grey },
  Identifier   = { fg = palette.black },
  Operator     = { fg = palette.black },
  Delimiter    = { fg = palette.grey },
  Macro        = { fg = palette.orange },
  PreProc      = { fg = palette.orange },
  Special      = { fg = palette.orange },
}

-- Treesitter captures that do not inherit from a classic group, or that deserve
-- to differ from the one they would inherit.
local treesitter = {
  ['@module']                = { fg = palette.blue },
  ['@module.builtin']        = { fg = palette.blue },
  ['@constructor']           = { fg = palette.orange },
  ['@type.definition']       = { fg = palette.cyan, bold = true },
  ['@type.builtin']          = { fg = palette.cyan },
  ['@variable']              = { fg = palette.black },
  ['@variable.member']       = { fg = palette.black },
  ['@variable.parameter']    = { fg = palette.dark_yellow },
  ['@attribute']             = { fg = palette.dark_yellow, bold = true },
  ['@attribute.builtin']     = { fg = palette.dark_yellow, bold = true },
  ['@property']              = { fg = palette.black },
  ['@punctuation.bracket']   = { fg = palette.grey },
  ['@punctuation.delimiter'] = { fg = palette.grey },
  ['@punctuation.special']   = { fg = palette.grey },
  ['@string.escape']         = { fg = palette.orange },
  ['@string.special']        = { fg = palette.orange },
  ['@comment.documentation'] = { fg = palette.grey, italic = false },
}

-- A second cursor colour: the insert-mode bar is thin, and yellow on a near
-- white background all but disappears. Normal mode keeps the yellow block.
local cursors = {
  Cursor       = { bg = palette.yellow, fg = palette.black },
  InsertCursor = { bg = palette.black, fg = palette.background },
}

-- Window separators and the cursor line used to be set once at startup, which
-- meant a light hairline survived into whatever theme came next.
local chrome = {
  WinSeparator = { fg = '#c5c9c7' },
  CursorLine   = { bg = '#ececec' },
}

-- Two cursor configurations. The grey one uses the custom InsertCursor group;
-- every other theme gets the stock arrangement, pointing at its own Cursor
-- group, so nothing here touches how kanso draws a cursor.
local guicursor = {
  grey  = 'n-v-c:block-Cursor,i-ci-ve:ver35-InsertCursor,r-cr:hor20-Cursor,o:hor50-Cursor',
  other = 'n-v-c:block-Cursor,i-ci-ve:ver25-Cursor,r-cr:hor20-Cursor,o:hor50-Cursor',
}

local function apply()
  if vim.g.colors_name ~= 'grey' then
    -- Any other theme (kanso and its ink/zen/mist variants) keeps its own
    -- palette, separators, cursor line and cursor. Nothing to do but hand the
    -- cursor back to it.
    vim.opt.guicursor = guicursor.other
    return
  end

  for group, opts in pairs(base) do vim.api.nvim_set_hl(0, group, opts) end
  for group, opts in pairs(treesitter) do vim.api.nvim_set_hl(0, group, opts) end
  for group, opts in pairs(cursors) do vim.api.nvim_set_hl(0, group, opts) end
  for group, opts in pairs(chrome) do vim.api.nvim_set_hl(0, group, opts) end
  vim.opt.guicursor = guicursor.grey
end

vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('Colors', { clear = true }),
  callback = apply,
})

apply()
