-- Configure Lualine and bufferline plugins

-- Taken from https://dev.to/vonheikemen/neovim-using-vim-plug-in-lua-3oom
local Plug = vim.fn['plug#']

--Plug 'kyazdani42/nvim-web-devicons'
Plug 'nvim-lualine/lualine.nvim'

-- vim obsession plugin icon
local function is_obsession_set()
  --print("Called to check")
  if not vim.fn.exists("*ObsessionStatus") then
    return ""
  end

  --print("obsession function exists")

--  return vim.call("ObsessionStatus", "✍️")
  return vim.call("ObsessionStatus", "📝")
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
    }
  }
end

local lualine_au = vim.api.nvim_create_augroup("LuaLineAU", {})
vim.api.nvim_create_autocmd({ "User" }, {
  pattern = { "DoAfterConfigs" },
  group = lualine_au,
  callback = Configure_lualine
})
