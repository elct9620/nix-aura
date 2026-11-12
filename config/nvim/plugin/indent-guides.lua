vim.g.indent_guides_enable_on_vim_startup = 1
vim.g.indent_guides_start_level = 2
vim.g.indent_guides_auto_colors = 0

-- Every other level gets a dark band; guibg is needed because termguicolors is on.
local function colors()
  vim.api.nvim_set_hl(0, "IndentGuidesOdd", {})
  vim.api.nvim_set_hl(0, "IndentGuidesEven", { bg = "#262626", ctermbg = 235 })
end

colors()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("aura-indent-guides", {}),
  callback = colors,
})
