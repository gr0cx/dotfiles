return {
    "folke/trouble.nvim",
    dependencies = { "nvim-web-devicons" },
    opts = {
        use_diagnostic_signs = true,
    },
    config = function()
        require("trouble").setup({})

        vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>",
            { desc = "Errors panel (Trouble)" })
        vim.keymap.set("n", "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>",
            { desc = "Actual file errors" })
        vim.keymap.set("n", "<leader>xs", "<cmd>Trouble symbols toggle<CR>",
            { desc = "File symbols (Classes/Functions)" })
    end,
}
