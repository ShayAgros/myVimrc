vim.g.g_disable_amazon_plugins = vim.fn.isdirectory(vim.fn.expand("~/.midway")) == 0

require("config.settings")
require("config.keymaps")
require("config.abbrevations")

-- configure the package manager which is called lazy
require("config.lazy")

-- Configure custom plugins I wrote
require("addons.copyWebLink")
require("addons.CWLogsOps")
require("addons.yankBuffers")

-- Instance configuration
require ("addons.instance_sync")

require ("addons.smartFileOpening")
require ("addons.debug_setup")
require ("addons.claudeWarm").setup()

require ("autocmds.general")
require ("autocmds.filetypes")
require ("autocmds.project")

require("code_notes_init")

-- Start a server automatically if not already running
if vim.fn.has('nvim') == 1 then
      local servername = '/tmp/nvim-' .. vim.fn.getpid() .. '.sock'
      vim.fn.serverstart(servername)
end
