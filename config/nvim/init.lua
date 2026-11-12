-- Options that differ from Neovim defaults; muscle memory comes from the
-- former vim setup, so its behaviour wins where the two disagree.
local opt = vim.opt

opt.number = true
opt.cursorline = true
opt.wrap = false
opt.linebreak = true
opt.title = true
opt.foldenable = false
opt.mouse = ""
opt.clipboard = "unnamedplus"
opt.shada = ""
opt.swapfile = false
opt.backup = false
opt.writebackup = false

opt.splitright = true
opt.splitbelow = true
opt.scrolloff = 5
opt.switchbuf = "useopen"
opt.showtabline = 2
opt.wildmode = "longest,list"
opt.synmaxcol = 512
opt.timeoutlen = 500
opt.shortmess:append("I")

opt.expandtab = true
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.copyindent = true
opt.ignorecase = true
opt.smartcase = true

opt.fileencodings = "ucs-bom,utf-8,big5,euc-jp,gbk,euc-kr,utf-16le,latin1"
opt.completeopt = "menuone,noinsert,noselect,popup"

-- Colours follow the terminal's ANSI palette instead of a hard-coded theme.
opt.termguicolors = false

-- Keymaps
local map = vim.keymap.set

-- Enter clears search highlight, except where Enter has a job (quickfix).
map("n", "<CR>", function()
  if vim.bo.buftype ~= "" then return "<CR>" end
  return "<Cmd>nohlsearch<CR>"
end, { expr = true })
map("n", "<C-A>", "ggVG")
map({ "n", "x", "o" }, "0", "^")

-- Tabs
map("n", "<F7>", "gT")
map("n", "<F8>", "gt")

-- Indent with Tab
map("n", "<Tab>", "v>")
map("n", "<S-Tab>", "v<")
map("x", "<Tab>", ">gv")
map("x", "<S-Tab>", "<gv")

-- %% expands to the current file's directory on the command line
map("c", "%%", function() return vim.fn.expand("%:h") .. "/" end, { expr = true })

map("n", "<Leader>0", "<Cmd>topleft split README.md<CR>")
map("n", "<Leader>gg", "<Cmd>topleft split Gemfile<CR>")
map("n", "<Leader>gr", "<Cmd>topleft split config/routes.rb<CR>")

-- Neovim maps Y to y$; keep vim's linewise Y.
pcall(vim.keymap.del, "n", "Y")

-- Autocmds
local group = vim.api.nvim_create_augroup("aura", {})

vim.api.nvim_create_autocmd("WinEnter", { group = group, command = "setlocal cursorline" })
vim.api.nvim_create_autocmd("WinLeave", { group = group, command = "setlocal nocursorline" })

-- Strip trailing whitespace, except in Markdown where two trailing spaces are a line break.
vim.api.nvim_create_autocmd("BufWritePre", {
  group = group,
  callback = function()
    if vim.bo.filetype == "markdown" then return end
    local view = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})
