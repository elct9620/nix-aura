-- Language servers are not bundled; each is enabled only when found on PATH
-- (ruby-lsp comes from the project's Ruby, clangd from Xcode).
local servers = {
  ruby_lsp = "ruby-lsp",
  clangd = "clangd",
  terraformls = "terraform-ls",
}

-- ruby-lsp can answer a semantic tokens request it already acknowledged as
-- cancelled, which Neovim reports as a red NO_RESULT_CALLBACK_FOUND error.
-- Its tokens only cover ambiguous syntax, so tree-sitter loses little.
vim.lsp.config("ruby_lsp", {
  init_options = { enabledFeatures = { semanticHighlighting = false } },
})

for name, cmd in pairs(servers) do
  if vim.fn.executable(cmd) == 1 then
    vim.lsp.enable(name)
  end
end

-- Follows the |lsp-attach| example in the Neovim docs.
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("aura-lsp", {}),
  callback = function(ev)
    local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))
    if client.name == "copilot" then return end

    -- Complete while typing, as asyncomplete did: trigger on every printable key.
    if client:supports_method("textDocument/completion") then
      local chars = {}
      for i = 32, 126 do table.insert(chars, string.char(i)) end
      client.server_capabilities.completionProvider.triggerCharacters = chars
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end

    -- Format on save with the server's own formatter (e.g. rubocop via ruby-lsp).
    if client:supports_method("textDocument/formatting") then
      vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = ev.buf,
        group = vim.api.nvim_create_augroup("aura-lsp-format-" .. ev.buf, {}),
        callback = function()
          vim.lsp.buf.format({ bufnr = ev.buf, id = client.id })
        end,
      })
    end
  end,
})

-- Same keys as the vim setup (asyncomplete): Tab/S-Tab move through the menu,
-- Enter confirms without a newline. Tab also accepts a Copilot suggestion.
vim.keymap.set("i", "<Tab>", function()
  if vim.fn.pumvisible() == 1 then return "<C-n>" end
  if vim.lsp.inline_completion.get() then return "" end
  return "<Tab>"
end, { expr = true })
vim.keymap.set("i", "<S-Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
end, { expr = true })
vim.keymap.set("i", "<CR>", function()
  return vim.fn.pumvisible() == 1 and "<C-y>" or "<CR>"
end, { expr = true })
