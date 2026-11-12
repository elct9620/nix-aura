-- Neovim blends statusline highlight groups over StatusLine/StatusLineNC, so
-- Solarized's `reverse` leaks into every airline section and swaps its colours.
-- Bake the reverse into plain fg/bg so airline renders as it does in vim.
local function unreverse(name)
  local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
  local cterm = hl.cterm or {}
  if not hl.reverse and not cterm.reverse then return end
  hl.reverse, cterm.reverse = nil, nil
  hl.fg, hl.bg = hl.bg, hl.fg
  hl.ctermfg, hl.ctermbg = hl.ctermbg, hl.ctermfg
  hl.cterm = cterm
  vim.api.nvim_set_hl(0, name, hl)
end

local function fix()
  unreverse("StatusLine")
  unreverse("StatusLineNC")
end

fix()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("aura-airline", {}),
  callback = fix,
})
