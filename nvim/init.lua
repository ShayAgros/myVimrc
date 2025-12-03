vim.g.g_disable_amazon_plugins = vim.fn.isdirectory(vim.fn.expand("~/.midway")) == 0

require("config.settings")
require("config.keymaps")
require("config.abbrevations")

-- configure the package manager which is called lazy
require("config.lazy")

-- Configure custom plugins I wrote
require("addons.copyWebLink")
require("addons.CWLogsOps")

-- Instance configuration
require ("addons.instance_sync")

require ("addons.smartFileOpening")

require ("autocmds.general")
require ("autocmds.filetypes")
require ("autocmds.project")
