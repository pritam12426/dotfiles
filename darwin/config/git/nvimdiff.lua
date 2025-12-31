-- Load your real Neovim config first
dofile(vim.fn.expand("~/.config/nvim/init.lua"))

-- OVERRIDE :q and :q! to close ALL buffers and quit Neovim
vim.keymap.set("n", ":q", ":qa!")
vim.keymap.set("n", "mm", "")

-- Searching
vim.opt.list      = false
