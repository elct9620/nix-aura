-- Language servers are not bundled; each is enabled only when found on PATH
-- (ruby-lsp comes from the project's Ruby, clangd from Xcode).
local servers = {
  ruby_lsp = "ruby-lsp",
  clangd = "clangd",
  terraformls = "terraform-ls",
}

for name, cmd in pairs(servers) do
  if vim.fn.executable(cmd) == 1 then
    vim.lsp.enable(name)
  end
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("aura-lsp", {}),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client or client.name == "copilot" then return end

    if client:supports_method("textDocument/completion") then
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

-- Tab: next completion item, else accept a Copilot suggestion, else a literal Tab.
vim.keymap.set("i", "<Tab>", function()
  if vim.fn.pumvisible() == 1 then return "<C-n>" end
  if vim.lsp.inline_completion.get() then return "" end
  return "<Tab>"
end, { expr = true })
vim.keymap.set("i", "<S-Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
end, { expr = true })
