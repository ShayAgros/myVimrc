-- highlight_sections.lua
-- Visual-mode <leader>ht: floating menu to color/uncolor the sign column
-- for selected lines, cycling through distinct colors per session.

local M = {}

local ns = vim.api.nvim_create_namespace("highlight_sections")

-- Palette of distinct background colors for the sign column marker
local palette = {
  "#e06c75", -- red
  "#61afef", -- blue
  "#98c379", -- green
  "#e5c07b", -- yellow
  "#c678dd", -- purple
  "#56b6c2", -- cyan
  "#d19a66", -- orange
  "#be5046", -- dark red
  "#7ec8e3", -- light blue
  "#b5e48c", -- light green
}

local color_index = 0
local hl_groups = {} -- cache created highlight groups

--- Get the next highlight group, creating it if needed
local function next_hl_group()
  color_index = (color_index % #palette) + 1
  local name = "HlSection_" .. color_index

  if not hl_groups[name] then
    vim.api.nvim_set_hl(0, name, { bg = palette[color_index] })
    hl_groups[name] = true
  end

  return name
end

--- Add a colored sign-column marker to the given lines
local function add_color(buf, start_line, end_line)
  local hl = next_hl_group()

  for lnum = start_line, end_line do
    vim.api.nvim_buf_set_extmark(buf, ns, lnum, 0, {
      sign_text = "▌",
      sign_hl_group = hl,
      priority = 100,
    })
  end
end

--- Remove all highlight_sections extmarks on the given lines
local function remove_color(buf, start_line, end_line)
  local marks = vim.api.nvim_buf_get_extmarks(buf, ns, { start_line, 0 }, { end_line, -1 }, {})
  for _, mark in ipairs(marks) do
    vim.api.nvim_buf_del_extmark(buf, ns, mark[1])
  end
end

--- Show a floating menu with the highlight options
local function show_menu(start_line, end_line)
  local buf = vim.api.nvim_get_current_buf()
  local options = {
    { label = "Add color column", fn = function() add_color(buf, start_line, end_line) end },
    { label = "Remove color",     fn = function() remove_color(buf, start_line, end_line) end },
  }

  vim.ui.select(
    vim.tbl_map(function(o) return o.label end, options),
    { prompt = "Highlight section:" },
    function(_, idx)
      if idx then
        options[idx].fn()
      end
    end
  )
end

function M.setup()
  vim.keymap.set("v", "<leader>ht", function()
    -- Get visual selection range (0-indexed)
    local start_line = vim.fn.line("v") - 1
    local end_line = vim.fn.line(".") - 1

    -- Normalize order
    if start_line > end_line then
      start_line, end_line = end_line, start_line
    end

    -- Exit visual mode before showing the menu
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)

    -- Defer to let mode change settle
    vim.schedule(function()
      show_menu(start_line, end_line)
    end)
  end, { desc = "Highlight section menu" })
end

M.setup()

return M
