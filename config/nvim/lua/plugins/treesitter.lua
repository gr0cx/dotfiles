return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter").setup({
            ensure_installed = {
                "python",
                "rust",
                "c",
                "lua",
                "javascript",
                "typescript",
                "java",
                "c_sharp",
                "markdown",
                "markdown_inline",
                "bash",
                "json",
                "yaml"
            },
            auto_install = true,
            highlight = {
                enable = true,
                additional_vim_regex_highlighting = false,
            },
            indent = { enable = true }
        })
    end,
}
