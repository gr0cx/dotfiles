vim.g.mapleader = " "
vim.g.maplocalleader = " "

local keymap = vim.keymap.set

keymap("n", "<C-h>", "<C-w>h", { desc = "Window left" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Window dowm" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Window up" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Window right" })

keymap("n", "<esc>", ":noh<CR>", { silent = true })

keymap("n", "<leader>w", ":w<CR>", { desc = "Save file" })
keymap("n", "<leader>q", ":q<CR>", { desc = "Exit" })

keymap("n", "<leader>x", "<cmd>bdelete<CR>", { desc = "Close current buffer" })

keymap("n", "<leader>ts", ":Telescope colorscheme<CR>", { desc = "Theme selector" })
