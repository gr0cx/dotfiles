return {
    {
        "olimorris/onedarkpro.nvim",
        priority = 1000,
        config = function()
            require("onedarkpro").setup({
                options = { transparency = false, terminal_colors = true },
            })
            vim.cmd("colorscheme onedark")
        end,
    },
    {
        "folke/tokyonight.nvim",
        lazy = true,
        opts = { style = "storm" },
    },
}
