-- Copilot through Neovim's built-in inline completion; sign in with :LspCopilotSignIn.
-- Like every vim.lsp.enable() server it attaches on FileType, so a buffer
-- without a filetype (a bare `nvim`) has no Copilot until one is set.
if vim.fn.executable("copilot-language-server") == 1 then
  vim.lsp.enable("copilot")
  vim.lsp.inline_completion.enable()
end
