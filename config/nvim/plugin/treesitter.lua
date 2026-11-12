-- Highlight with tree-sitter where a parser is installed; other filetypes keep regex syntax.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("aura-treesitter", {}),
  callback = function(ev)
    pcall(vim.treesitter.start, ev.buf)
  end,
})
