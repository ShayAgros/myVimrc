vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.expandtab = true

vim.api.nvim_create_autocmd("BufWritePre", {
    buffer = 0,
    callback = function()
        vim.lsp.buf.format({ async = false, timeout_ms = 3000 })
    end,
})
