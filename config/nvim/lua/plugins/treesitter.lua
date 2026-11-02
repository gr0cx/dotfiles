return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    lazy = false,
    config = function()
        local ts = require("nvim-treesitter")
        ts.setup({})

        local parsers = {
            "python", "rust", "c", "lua", "javascript", "typescript",
            "java", "c_sharp", "markdown", "markdown_inline", "bash",
            "json", "yaml", "html", "css",
        }

        local installed = ts.get_installed()
        local missing = vim.tbl_filter(function(p)
            return not vim.tbl_contains(installed, p)
        end, parsers)
        if #missing > 0 then
            ts.install(missing):wait(300000)
        end

        vim.api.nvim_create_autocmd("FileType", {
            callback = function(args)
                local lang = vim.treesitter.language.get_lang(args.match)
                if not lang then return end
                if pcall(vim.treesitter.start, args.buf, lang) then
                    vim.bo[args.buf].indentexpr =
                    "v:lua.require'nvim-treesitter'.indentexpr()"
                end
            end,
        })
    end,
}
