-- Center the current buffer and make it as distraction free as possible

local Plug = vim.fn['plug#']

Plug 'folke/zen-mode.nvim'

local function configure_zen_mode()
	local success, zen_mode = pcall(require, 'zen-mode')
	if not success then
		return
	end

  zen_mode.setup {
    plugins = {
      tmux = { enabled = true }, -- disables the tmux statusline
      -- this will change the font size on kitty when in zen mode
      -- to make this work, you need to set the following kitty options:
      -- - allow_remote_control socket-only
      -- - listen_on unix:/tmp/kitty
      kitty = {
        enabled = true,
        font = "+10", -- font size increment
      },
    },
  }

end

local zen_mode_au = vim.api.nvim_create_augroup("ZenModeAU", {})
vim.api.nvim_create_autocmd({ "User" }, {
  pattern = { "DoAfterConfigs" },
  group = zen_mode_au,
  callback = configure_zen_mode
})
