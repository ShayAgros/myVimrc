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

return {
    "nvim-lualine/lualine.nvim",
    opts = {
        theme = vim.g.colors_name,

        sections = {
            lualine_x = { is_obsession_set, 'encoding', 'fileformat', 'filetype' },
            lualine_z = { print_virt_location }
        }
    }
}
