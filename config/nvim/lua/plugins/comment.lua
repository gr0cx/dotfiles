return {
    "numToStr/Comment.nvim",
    config = function()
        require("Comment").setup()

        vim.keymap.set("n", "<C-_>", "gcc", { remap = true, desc = "Comment/Uncomment line" })
        vim.keymap.set("x", "<C-_>", "gc", { remap = true, desc = "Comment/Uncomment selection" })

        vim.keymap.set("n", "<leader>c", "gcc", { remap = true, desc = "Comment line" })
        vim.keymap.set("x", "<leader>c", "gc", { remap = true, desc = "Comment selection" })
    end,
}
