return {
    {
        "mfussenegger/nvim-jdtls",
        dependencies = {
            "mfussenegger/nvim-dap"
        }
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            'WhoIsSethDaniel/mason-tool-installer.nvim',
            -- Display a status message when indexing code
            { 'j-hui/fidget.nvim', opts = {} },
            -- Show function signature when you type
            { 'ray-x/lsp_signature.nvim', opts = {} },
            -- Autocompletion
            "hrsh7th/cmp-nvim-lsp",
            {
                url = "ssh://git.amazon.com/pkg/VimBrazilConfig",
                branch = "mainline",
                ft = "brazil-config",
            },
        },

        config = function()
            local lspconfig = require("lspconfig")
            local configs = require("lspconfig.configs")
            local mason = require("mason")
            local mason_lspconfig = require("mason-lspconfig")
            local mason_tool_installer = require("mason-tool-installer")
            local default_capabilities = vim.lsp.protocol.make_client_capabilities()
            local cmp_nvim_lsp = require("cmp_nvim_lsp")
            local clangd_config = require "lspconfig.configs.clangd"

            vim.filetype.add({
                filename = {
                    ['Config'] = function()
                        vim.b.brazil_package_Config = 1
                        return 'brazil-config'
                    end,
                },
            })
            configs.barium = {
                default_config = {
                    cmd = {'barium'};
                    filetypes = {'brazil-config'};
                    root_dir = function(fname)
                        return lspconfig.util.find_git_ancestor(fname)
                    end;
                    settings = {};
                };
            }
            lspconfig.barium.setup({})
            lspconfig.lua_ls.setup{}

            local server_configs = {
                -- Configure C LSP
                -- clangd = {
                --     on_attach = function()
                --         vim.bo.tagfunc = ""
                --     end
                -- },
                clangd = clangd_config,
                bashls = {},
                tsserver = {},
                pyright = {
                    cmd = { "pyright-langserver", "--stdio", "--verbose" },
                },
            }

            mason.setup()

            local machine_arch = vim.system({ "uname", "-m" }):wait().stdout:gsub("[\n\r]", "")
            local mason_ensure_installed = {}
            -- Don't install any servers on non x86_64 machines as mason doesn't necessarily supports that
            -- if machine_arch == "x86_64" then
            --     mason_ensure_installed = { "clangd", "bashls", "pyright" }
            -- end

            vim.list_extend(
                mason_ensure_installed,
                {
                    -- place other packages you want to install but not configure with mason here
                    -- e.g. language servers not configured with nvim-lspconfig, linters, formatters, etc.
                    "jdtls",
                }
            )
            mason_tool_installer.setup({
                ensure_installed = mason_ensure_installed
            })

            mason_lspconfig.setup({
                handlers = {
                    function(server_name)
                        local server_config = server_configs[server_name] or {}
                        server_config.capabilities = vim.tbl_deep_extend(
                            "force",
                            default_capabilities,
                            server_config.capabilities or {},
                            cmp_nvim_lsp.default_capabilities()
                        )
                        lspconfig[server_name].setup(server_config)
                    end,
                    ['jdtls'] = function() end,
                },
            })

            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("lsp-attach-keybinds", { clear = true }),
                callback = function(e)
                    local keymap = function(keys, func)
                        vim.keymap.set("n", keys, func, { buffer = e.buf })
                    end
                    local builtin = require("telescope.builtin")
                    local snacks_exist, snacks = pcall(require, "snacks")

                    keymap('K', vim.lsp.buf.hover)
                    keymap('gld', vim.lsp.buf.definition)
                    keymap("glT", builtin.lsp_type_definitions)
                    keymap('glD', vim.lsp.buf.declaration)
                    if snacks_exist then
                        keymap('glR', snacks.picker.lsp_references)
                    else
                        keymap('glR', builtin.lsp_references)
                    end
                    keymap('gli', builtin.lsp_implementations)
                    keymap('glr', vim.lsp.buf.rename)
                    keymap('glt', vim.diagnostic.hide)
                    keymap("]g", vim.diagnostic.goto_next)
                    keymap("[g", vim.diagnostic.goto_prev)
                    keymap("glk", vim.diagnostic.open_float)


                    keymap('gla', vim.lsp.buf.code_action)
                    keymap('gls', builtin.lsp_dynamic_workspace_symbols)
                    keymap('glo', builtin.lsp_document_symbols)

                    require("lsp_signature").on_attach({ hint_prefix = "💡 " }, e.buf)

                    -- local clangd = vim.lsp.get_clients{ name = "clangd" }
                    -- if #clangd > 0 then
                    --     clangd[1].stop()
                    -- end
                end
            })
        end
    },
    -- luaLS configuration for neovim development
    {
        "folke/lazydev.nvim",
        ft = "lua", -- only load on lua files
        opts = {
            library = {
                -- See the configuration section for more details
                -- Load luvit types when the `vim.uv` word is found
                { path = "luvit-meta/library", words = { "vim%.uv" } },
            },
        },
    },
    { "Bilal2453/luvit-meta", lazy = true }, -- optional `vim.uv` typings
    { -- optional completion source for require statements and module annotations
        "hrsh7th/nvim-cmp",
        opts = function(_, opts)
            opts.sources = opts.sources or {}
            table.insert(opts.sources, {
                name = "lazydev",
                group_index = 0, -- set group index to 0 to skip loading LuaLS completions
            })
            opts.experimental = {
                ghost_text = true,
            }
        end,
    },
}
