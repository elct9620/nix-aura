-- The vault is whichever directory holds `.obsidian/` above the first Markdown
-- file opened, so no vault paths live in this repository. One vault per session.
vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
  group = vim.api.nvim_create_augroup("aura-obsidian", {}),
  pattern = "*.md",
  callback = function(ev)
    local root = vim.fs.root(ev.file, ".obsidian")
    if not root then return end

    -- obsidian.nvim's UI (link and checkbox rendering) needs concealing.
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown",
      command = "setlocal conceallevel=2",
    })

    require("obsidian").setup({
      legacy_commands = false,
      workspaces = { { name = vim.fs.basename(root), path = root } },
      picker = { name = "mini.pick" },
    })
    return true -- set up once; drop this autocmd
  end,
})
