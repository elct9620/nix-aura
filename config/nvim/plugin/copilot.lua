-- Copilot through Neovim's built-in inline completion; sign in with :LspCopilotSignIn.
if vim.fn.executable("copilot-language-server") == 1 then
  vim.lsp.enable("copilot")
  vim.lsp.inline_completion.enable()
end
