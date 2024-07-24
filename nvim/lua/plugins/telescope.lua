return {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "kyazdani42/nvim-web-devicons"
    },

    config = function()
        local keymap = function(keys, func)
            vim.keymap.set("n", keys, func, {})
        end

        require("telescope").setup({
        })
        local builtin = require("telescope.builtin")

        keymap("<leader>sn", function()
            builtin.find_files {
                cwd = vim.fn.stdpath "config"
            }
        end)

        keymap("<space><space>", builtin.find_files)
        keymap("<space>a", function () builtin.buffers{ sort_mru = true, ignore_current_buffer = true } end)
    end
}
