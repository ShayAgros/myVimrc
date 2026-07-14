-- Load the fleet-wide find-implementations addon (registers :FindImpls) and
-- bind `glI` in Java buffers as the out-of-workspace complement to `gli`
-- (jdtls implementation search, which only sees the local workspace).
require("addons.find_impls")

vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  group = vim.api.nvim_create_augroup("find_impls_java", { clear = true }),
  callback = function(e)
    vim.keymap.set("n", "glI", function() require("addons.find_impls").find() end,
      { buffer = e.buf, desc = "Fleet-wide find implementations (csimpl)" })
  end,
})
