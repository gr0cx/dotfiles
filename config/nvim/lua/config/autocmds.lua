local augroup = vim.api.nvim_create_augroup("TNPUNK_AutoSave", { clear = true })

vim.api.nvim_create_autocmd("BufWritePre", {
    group = augroup,
    pattern = "*",
    callback = function(args)
        local save_cursor = vim.fn.getpos(".")
        vim.cmd([[%s/\s\+$//e]])
        vim.fn.setpos(".", save_cursor)

        local clients = vim.lsp.get_clients({ bufnr = args.buf })
        if #clients > 0 then
            vim.lsp.buf.format({ bufnr = args.buf, timeout_ms = 2000 })
        end
    end,
})
