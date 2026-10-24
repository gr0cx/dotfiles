return {
    "nvim-telescope/telescope.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        -- {
        --     "nvim-telescope/telescope-fzf-native.nvim",
        --     build = "make",
        --     cond = function()
        --         return vim.fn.executable("make") == 1
        --     end,
        -- },
    },
    config = function()
        local telescope = require("telescope")
        telescope.setup({
            defaults = {
                file_ignore_patterns = { "node_modules", ".git", "target", "build" },
            },
        })

        -- pcall(telescope.load_extension, "fzf")

        local builtin = require("telescope.builtin")
        vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Search files in the project" })
        vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Search text in the files (Grep)" })
        vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "See open buffers" })
        vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Search in the Neovim help" })
    end,
}
