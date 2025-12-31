-- Basic Settings
vim.opt.autoindent      = true
vim.opt.expandtab       = true
vim.opt.tabstop         = 4
vim.opt.shiftwidth      = 4
vim.opt.autoread        = true
vim.opt.ignorecase      = true
vim.opt.langmenu        = "en_US.UTF-8"
vim.opt.mouse           = "a"
vim.opt.wrap            = false
vim.opt.number          = true
vim.opt.relativenumber  = true
vim.opt.iskeyword:remove("_")
vim.opt.shell = "zsh"

-- Autocommands
vim.api.nvim_create_autocmd("InsertEnter", {
  pattern = "*",
  command = "set norelativenumber"
})

vim.api.nvim_create_autocmd("InsertLeave", {
  pattern = "*",
  command = "set relativenumber"
})

-- Searching
vim.opt.hlsearch  = true
vim.opt.incsearch = true
vim.opt.smartcase = true
vim.opt.gdefault  = true
vim.opt.list      = true

vim.opt.listchars = {
	eol = "¬",
	tab = "––",
	trail = "·",
	extends = ">",
	precedes = "<",
	space = "·"
}

-- Theme
-- vim.cmd("colorscheme habamax")
vim.cmd("colorscheme vim")
-- vim.cmd("colorscheme murphy")

-- Shortcut keys
-- Normal mode
vim.keymap.set("n", "<C-c>", ":set clipboard=unnamedplus<CR>")
vim.keymap.set("n", ":q", ":q!")
vim.keymap.set("n", "mm", ":execute '!zed ' . expand('%') . ':' . line('.') . ':' . col('.') <CR> <ESC> :q! ")
vim.keymap.set("n", "mn", ":Explore <CR>")
vim.keymap.set("n", "mt", ":terminal <CR>")

-- Open the like in browser
vim.keymap.set('n', 'gl', function()
	local file = vim.fn.expand("<cfile>")          -- get the file/URL under cursor
	local escaped = vim.fn.shellescape(file)       -- safely escape for shell
	vim.cmd("silent !open " .. escaped)            -- run macOS open command
end, { desc = "Open file/URL under cursor with system handler" })


-- Visual mode
vim.keymap.set("v", "x", '"_x')

-- Command mode
vim.keymap.set("n", "x", '"_x')

-- Insert mode: Auto-pairs
vim.keymap.set("i", "(", "()<Left>")
vim.keymap.set("i", "{", "{}<Left>")
vim.keymap.set("i", "[", "[]<Left>")
vim.keymap.set("i", '"', '""<Left>')
vim.keymap.set("i", "'", "''<Left>")
vim.keymap.set("i", "`", "``<Left>")
