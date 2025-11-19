-- Lua LSP download and configuration {{{

--- install lua-language-server if needed {{{
-- Add this to your Neovim config
-- Auto-install lua-language-server based on architecture
local function install_luals_if_not_found()

    -- Check if already installed
    if vim.fn.executable('lua-language-server') == 1 then
        return
    end

    local install_dir = vim.fn.expand("~/workspace/software/lua-language-server")
    local bin_dir = vim.fn.expand("~/.local/bin")

    -- Detect architecture
    local arch = vim.fn.system("uname -m"):gsub("%s+", "") -- Remove whitespace/newlines
    local url_arch

    if arch == "aarch64" or arch == "arm64" then
        url_arch = "arm64"
    elseif arch == "x86_64" or arch == "amd64" then
        url_arch = "x64" 
    else
        vim.notify(string.format("Unsupported architecture: %s", arch), vim.log.levels.ERROR)
        return
    end

    local url = string.format(
        "https://github.com/LuaLS/lua-language-server/releases/latest/download/lua-language-server-3.15.0-linux-%s.tar.gz",
        url_arch
    )

    vim.notify(string.format("Installing lua-language-server for %s architecture...", arch), vim.log.levels.INFO)

    -- Create directories
    vim.fn.mkdir(install_dir, "p")
    vim.fn.mkdir(bin_dir, "p")

    -- Prepare the installation script
    local script_content = string.format([[
#!/bin/bash
set -e
cd %s
wget %s -O lua-language-server.tar.gz
tar xf lua-language-server.tar.gz
rm lua-language-server.tar.gz
ln -sf %s/bin/lua-language-server %s/lua-language-server
echo "Installation completed successfully"
]], 
        vim.fn.shellescape(install_dir),
        vim.fn.shellescape(url),
        vim.fn.shellescape(install_dir),
        vim.fn.shellescape(bin_dir)
    )

    -- Write script to temporary file
    local script_file = vim.fn.tempname() .. ".sh"
    local file = io.open(script_file, "w")
    if file then
        file:write(script_content)
        file:close()
        vim.fn.system("chmod +x " .. vim.fn.shellescape(script_file))

        -- Run asynchronously
        vim.fn.jobstart(script_file, {
            on_exit = function(_, exit_code)
                vim.schedule(function()
                    if exit_code == 0 then
                        vim.notify("✓ lua-language-server installed successfully!", vim.log.levels.INFO)
                        vim.notify("Please restart Neovim or reload your LSP configuration", vim.log.levels.INFO)
                    else
                        vim.notify("✗ lua-language-server installation failed!", vim.log.levels.ERROR)
                    end
                    -- Clean up temporary script
                    vim.fn.delete(script_file)
                end)
            end,
            stdout_buffered = true,
            stderr_buffered = true,
        })
    else
        vim.notify("✗ Could not create installation script", vim.log.levels.ERROR)
    end
end
--- }}}

local function configure_lua_lsp()
    vim.lsp.config['lua-ls'] = {
        cmd = { 'lua-language-server' },
        -- Filetypes to automatically attach to.
        filetypes = { 'lua' },
        root_markers = { { '.luarc.json', '.luarc.jsonc' }, '.git' },
        settings = {
            Lua = {
                workspace = {
                    library = vim.api.nvim_get_runtime_file("", true)
                }
            },
        }
    }
    vim.lsp.enable('lua-ls')

    -- Optional: Create a command to manually trigger installation
    vim.api.nvim_create_user_command('InstallLuaLS', install_luals_if_not_found, {
        desc = "Install lua-language-server if not found"
    })
end
-- }}}

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
                -- dont include if were not on amazon machine
                enabled = function()
                    return not vim.g.g_disable_amazon_plugins
                end,
            },
        },

        config = function()
            -- Configure LSP using neovim native LSP
            vim.lsp.config['pyright'] = {
                -- Command and arguments to start the server.
                cmd = { "pyright-langserver", "--stdio", "--verbose" },
                -- Filetypes to automatically attach to.
                filetypes = { 'python' },
                -- Sets the "workspace" to the directory where any of these files is found.
                -- Files that share a root directory will reuse the LSP server connection.
                -- Nested lists indicate equal priority, see |vim.lsp.Config|.
                root_markers = { '.git' },
            }

            vim.lsp.enable('pyright')


            vim.lsp.config['bashls'] = {
                -- Command and arguments to start the server.
                cmd = { "bash-language-server" , "start" },
                -- Filetypes to automatically attach to.
                filetypes = { 'bash', 'zsh', 'sh' },
                -- Sets the "workspace" to the directory where any of these files is found.
                -- Files that share a root directory will reuse the LSP server connection.
                -- Nested lists indicate equal priority, see |vim.lsp.Config|.
                root_markers = { '.git' },
            }

            vim.lsp.enable('bashls')

            vim.lsp.config['clangd'] = {
                -- Command and arguments to start the server.
                -- Filetypes to automatically attach to.
                filetypes = { 'c', 'cpp' },
            }

            vim.lsp.enable('clangd')

            configure_lua_lsp()


            -- local lspconfig = require("lspconfig")
            -- local configs = require("lspconfig.configs")
            -- local mason = require("mason")
            -- local mason_lspconfig = require("mason-lspconfig")
            -- local mason_tool_installer = require("mason-tool-installer")
            -- local default_capabilities = vim.lsp.protocol.make_client_capabilities()
            -- local cmp_nvim_lsp = require("cmp_nvim_lsp")
            -- local clangd_config = require "lspconfig.configs.clangd"
            --
            -- vim.filetype.add({
            --     filename = {
            --         ['Config'] = function()
            --             vim.b.brazil_package_Config = 1
            --             return 'brazil-config'
            --         end,
            --     },
            -- })
            -- configs.barium = {
            --     default_config = {
            --         cmd = {'barium'};
            --         filetypes = {'brazil-config'};
            --         root_dir = function(fname)
            --             return lspconfig.util.find_git_ancestor(fname)
            --         end;
            --         settings = {};
            --     };
            -- }
            -- lspconfig.barium.setup({})
            --
            -- local server_configs = {
            --     -- Configure C LSP
            --     -- clangd = {
            --     --     on_attach = function()
            --     --         vim.bo.tagfunc = ""
            --     --     end
            --     -- },
            --     clangd = clangd_config,
            --     bashls = {},
            --     tsserver = {},
            --     pyright = {
            --         cmd = { "pyright-langserver", "--stdio", "--verbose" },
            --     },
            -- }
            --
            -- mason.setup()
            --
            -- local machine_arch = vim.system({ "uname", "-m" }):wait().stdout:gsub("[\n\r]", "")
            -- local mason_ensure_installed = {}
            -- -- Don't install any servers on non x86_64 machines as mason doesn't necessarily supports that
            -- -- if machine_arch == "x86_64" then
            -- --     mason_ensure_installed = { "clangd", "bashls", "pyright" }
            -- -- end
            --
            -- vim.list_extend(
            --     mason_ensure_installed,
            --     {
            --         -- place other packages you want to install but not configure with mason here
            --         -- e.g. language servers not configured with nvim-lspconfig, linters, formatters, etc.
            --         "jdtls",
            --     }
            -- )
            -- mason_tool_installer.setup({
            --     ensure_installed = mason_ensure_installed
            -- })
            --
            -- mason_lspconfig.setup({
            --     handlers = {
            --         function(server_name)
            --             local server_config = server_configs[server_name] or {}
            --             server_config.capabilities = vim.tbl_deep_extend(
            --                 "force",
            --                 default_capabilities,
            --                 server_config.capabilities or {},
            --                 cmp_nvim_lsp.default_capabilities()
            --             )
            --             lspconfig[server_name].setup(server_config)
            --         end,
            --         ['jdtls'] = function() end,
            --     },
            -- })

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
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
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
