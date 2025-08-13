return {
    "hrsh7th/nvim-cmp",
    lazy = false,
    priority = 100,
    dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        'hrsh7th/cmp-path',
        'hrsh7th/cmp-buffer',
        { "L3MON4D3/LuaSnip" , build = "make install_jsregexp"},
        "saadparwaiz1/cmp_luasnip",
    },
    config = function()
        local cmp = require("cmp")

        vim.opt.completeopt = { "menu", "menuone", "noselect" }
        -- vim.opt.shortmess:append("c")

        cmp.setup({
            mapping = cmp.mapping.preset.insert({
                ["<C-n>"] = cmp.mapping.select_next_item(),
                ["<C-p>"] = cmp.mapping.select_prev_item(),
                ["<C-s>"] = cmp.mapping.complete(),
                ["<C-y>"] = cmp.mapping(
                    cmp.mapping.confirm {
                        behavior = cmp.ConfirmBehavior.Insert,
                        select = true,
                    }, { "i", "s" }),
            }),

            snippet = {
                expand = function(args)
                    require("luasnip").lsp_expand(args.body)
                end,
            },

            sources = cmp.config.sources({
                { name = "nvim_lsp" },
                { name = "path" },
                { name = "buffer" },
                { name = "luasnip" },
            }),
            experimental = {
                ghost_text = true,
            },
        })

        local ls = require "luasnip"
        ls.config.set_config {
            history = false,
            updateevents = "TextChanged, TextChangedI",
        }

        for _, ft_path in ipairs(vim.api.nvim_get_runtime_file("lua/custom/snippets/*.lua", true)) do
            loadfile(ft_path)()
        end

        vim.keymap.set({"i", "s"}, "<c-j>", function ()
            if ls.expand_or_jumpable() then
                ls.expand_or_jump()
            end
        end, { silent = true })

        vim.keymap.set({"i", "s"}, "<c-k>", function ()
            if ls.jumpable(-1) then
                ls.jump(-1)
            end
        end, { silent = true })
    end
}
