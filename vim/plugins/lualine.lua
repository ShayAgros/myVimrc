-- Configure Lualine and bufferline plugins

-- Taken from https://dev.to/vonheikemen/neovim-using-vim-plug-in-lua-3oom
local Plug = vim.fn['plug#']

--Plug 'kyazdani42/nvim-web-devicons'
Plug 'nvim-lualine/lualine.nvim'

-- vim obsession plugin icon
local function is_obsession_set()
  if not vim.fn.exists("*ObsessionStatus") then
    return ""
  end

  return vim.call("ObsessionStatus", "📝")
end

local function print_virt_location()
  local line = vim.fn.line('.')
  local col = vim.fn.virtcol('.')

  return string.format('%3d:%-2d', line, col)
end

local function Configure_lualine()
	local success, lualine = pcall(require, 'lualine')

	if not success then
		return
	end

  lualine.setup {
    always_divide_middle = false,
    sections = {
      lualine_x = {is_obsession_set, 'encoding', 'fileformat', 'filetype'},
      lualine_z = { print_virt_location }
    }
  }
end

local lualine_au = vim.api.nvim_create_augroup("LuaLineAU", {})
vim.api.nvim_create_autocmd({ "User" }, {
  pattern = { "DoAfterConfigs" },
  group = lualine_au,
  callback = Configure_lualine
})
