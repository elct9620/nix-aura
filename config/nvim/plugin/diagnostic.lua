-- Present LSP diagnostics the way ALE did: ✗/⚠ signs (info shares the warning
-- sign, as in ALE), the message at the end of the line, and the message of the
-- line under the cursor echoed in the command line.
local severity = vim.diagnostic.severity

vim.diagnostic.config({
  signs = {
    text = {
      [severity.ERROR] = "✗",
      [severity.WARN] = "⚠",
      [severity.INFO] = "⚠",
      [severity.HINT] = "⚠",
    },
  },
  virtual_text = true,
})

local echoed = false
vim.api.nvim_create_autocmd({ "CursorMoved", "DiagnosticChanged" }, {
  group = vim.api.nvim_create_augroup("aura-diagnostic-echo", {}),
  callback = function()
    if vim.fn.mode() ~= "n" then return end
    local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
    local diagnostics = vim.diagnostic.get(0, { lnum = lnum })
    if #diagnostics == 0 then
      if echoed then vim.api.nvim_echo({}, false, {}) end
      echoed = false
      return
    end
    table.sort(diagnostics, function(a, b) return a.severity < b.severity end)
    local message = diagnostics[1].message:gsub("\n.*", "")
    -- Truncate so a long message never triggers the hit-enter prompt.
    message = vim.fn.strcharpart(message, 0, vim.o.columns - 12)
    vim.api.nvim_echo({ { message } }, false, {})
    echoed = true
  end,
})
