local M = {}

-- State
vim.g.code_notes_current_project = nil
local notes_dir = vim.fn.expand("~/.config/nvim/code_notes")

-- Ensure notes directory exists
vim.fn.mkdir(notes_dir, "p")

-- Get git hash for current file
local function get_git_hash()
  local handle = io.popen("git rev-parse HEAD 2>/dev/null")
  if not handle then return nil end
  local hash = handle:read("*a"):gsub("\n", "")
  handle:close()
  return hash ~= "" and hash or nil
end

-- Get project file path
local function get_project_file(project_name)
  return notes_dir .. "/" .. project_name:gsub(" ", "_") .. ".md"
end

-- Get list of existing projects sorted by modification time
local function get_projects()
  local projects = {}
  local handle = io.popen("ls -t " .. notes_dir .. "/*.md 2>/dev/null")
  if handle then
    for file in handle:lines() do
      local name = vim.fn.fnamemodify(file, ":t:r"):gsub("_", " ")
      table.insert(projects, name)
    end
    handle:close()
  end
  return projects
end

-- Parse sections from project file
local function get_sections(project_name)
  local file_path = get_project_file(project_name)
  local sections = {}
  local file = io.open(file_path, "r")
  if not file then return sections end
  
  local current_section = nil
  local content_lines = {}
  
  for line in file:lines() do
    if line:match("^## %[(.+)%]%((.+)%)") then
      if current_section then
        current_section.content = table.concat(content_lines, "\n")
        table.insert(sections, current_section)
      end
      current_section = { line = line }
      content_lines = {}
    elseif line == "---" then
      if current_section then
        current_section.content = table.concat(content_lines, "\n")
        table.insert(sections, current_section)
        current_section = nil
        content_lines = {}
      end
    elseif current_section and not line:match("^<!%-%-") then
      table.insert(content_lines, line)
    end
  end
  
  if current_section then
    current_section.content = table.concat(content_lines, "\n")
    table.insert(sections, current_section)
  end
  
  file:close()
  return sections
end

-- Get function name using treesitter
local function get_function_name(bufnr, line_num)
  if not pcall(require, "nvim-treesitter") then
    return "line"
  end
  
  local node = vim.treesitter.get_node({ bufnr = bufnr, pos = { line_num - 1, 0 } })
  if not node then return "global scope" end
  
  while node do
    if node:type() == "function_definition" then
      for child in node:iter_children() do
        if child:type() == "declarator" then
          for subchild in child:iter_children() do
            if subchild:type() == "function_declarator" then
              for func_child in subchild:iter_children() do
                if func_child:type() == "identifier" then
                  return vim.treesitter.get_node_text(func_child, bufnr)
                elseif func_child:type() == "qualified_identifier" then
                  -- Handle class methods like Class::method
                  for qual_child in func_child:iter_children() do
                    if qual_child:type() == "identifier" then
                      return vim.treesitter.get_node_text(qual_child, bufnr)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
    node = node:parent()
  end
  
  return "global scope"
end

-- Add note entry
local function add_note(project_name, file_path, line_num, git_hash)
  local project_file = get_project_file(project_name)
  local rel_path = vim.fn.fnamemodify(file_path, ":.")
  local bufnr = vim.fn.bufnr(file_path)
  local func_name = get_function_name(bufnr, line_num)
  
  -- Create link with metadata
  local link = string.format("## [%s:%d - %s](file://%s#L%d)\n<!-- git:%s -->\n\n",
    rel_path, line_num, func_name, file_path, line_num, git_hash or "none")
  
  -- Open capture buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(link, "\n"))
  vim.api.nvim_buf_set_option(buf, "buftype", "acwrite")
  vim.api.nvim_buf_set_name(buf, "code-note")
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = math.floor(vim.o.columns * 0.8),
    height = math.floor(vim.o.lines * 0.6),
    col = math.floor(vim.o.columns * 0.1),
    row = math.floor(vim.o.lines * 0.2),
    style = "minimal",
    border = "rounded",
    title = " Add Note - " .. project_name .. " ",
    title_pos = "center"
  })
  
  vim.api.nvim_win_set_option(win, "conceallevel", 2)
  
  -- Move cursor to end for writing
  vim.api.nvim_win_set_cursor(win, {4, 0})
  vim.cmd("startinsert")
  
  -- Save handler for :w
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local file = io.open(project_file, "a")
      if file then
        file:write(table.concat(lines, "\n") .. "\n\n---\n\n")
        file:close()
      end
      vim.api.nvim_buf_set_option(buf, "modified", false)
      vim.api.nvim_buf_delete(buf, { force = true })
      vim.notify("Note saved to " .. project_name, vim.log.levels.INFO)
    end
  })
  
  vim.keymap.set("n", "q", function()
    vim.api.nvim_buf_delete(buf, { force = true })
  end, { buffer = buf })
end

-- Select or create project
local function select_project(callback)
  if vim.g.code_notes_current_project then
    callback(vim.g.code_notes_current_project)
    return
  end
  
  local projects = get_projects()
  table.insert(projects, 1, "+ New Project")
  
  vim.ui.select(projects, {
    prompt = "Select Project:",
    format_item = function(item) return item end
  }, function(choice)
    if not choice then return end
    
    if choice == "+ New Project" then
      vim.ui.input({ prompt = "Project Name: " }, function(name)
        if name and name ~= "" then
          vim.g.code_notes_current_project = name
          -- Create empty project file
          local project_file = get_project_file(name)
          local file = io.open(project_file, "a")
          if file then file:close() end
          callback(name)
        end
      end)
    else
      vim.g.code_notes_current_project = choice
      callback(choice)
    end
  end)
end

-- Main add note function
function M.add_note()
  local file_path = vim.fn.expand("%:p")
  local line_num = vim.fn.line(".")
  local git_hash = get_git_hash()
  
  select_project(function(project)
    add_note(project, file_path, line_num, git_hash)
  end)
end

-- Select and jump to section
function M.select_section()
  select_project(function(project)
    local sections = get_sections(project)
    if #sections == 0 then
      vim.notify("No sections found in " .. project, vim.log.levels.WARN)
      return
    end
    
    require("snacks").picker.pick({
      live = true,
      finder = function(opts, ctx)
        local pattern = ctx.filter.search:lower()
        local items = {}
        
        for _, section in ipairs(sections) do
          local title, link = section.line:match("^## %[(.-)%]%((.+)%)")
          if title and link then
            local file_path, line = link:match("file://(.+)#L(%d+)")
            if file_path and line then
              local content = section.content or ""
              local searchable = (title .. " " .. content):lower()
              
              if pattern == "" or searchable:find(pattern, 1, true) then
                table.insert(items, {
                  text = title,
                  file = file_path,
                  pos = { tonumber(line), 1 },
                  note_content = content
                })
              end
            end
          end
        end
        
        return items
      end,
      preview = function(ctx)
        ctx.preview:reset()
        if ctx.item.note_content and ctx.item.note_content ~= "" then
          local lines = vim.split(ctx.item.note_content, "\n")
          ctx.preview:set_lines(lines)
          ctx.preview:highlight({ ft = "markdown" })
          ctx.preview:wo({ wrap = true })
          
          -- Highlight search matches
          local pattern = ctx.picker.input.filter.search:lower()
          if pattern ~= "" then
            local ns = vim.api.nvim_create_namespace("notes_search_highlight")
            for i, line in ipairs(lines) do
              local line_lower = line:lower()
              local start = 1
              while true do
                local match_start, match_end = line_lower:find(pattern, start, true)
                if not match_start then break end
                vim.api.nvim_buf_set_extmark(ctx.buf, ns, i - 1, match_start - 1, {
                  end_col = match_end,
                  hl_group = "Search"
                })
                start = match_end + 1
              end
            end
          end
        else
          ctx.preview:notify("No notes", "warn")
        end
      end,
      confirm = function(picker, item)
        picker:close()
        if item and item.file then
          vim.cmd("edit " .. vim.fn.fnameescape(item.file))
          vim.fn.cursor(item.pos)
          vim.cmd("normal! zz")
        end
      end
    })
  end)
end

-- Open project file directly
function M.open_project_file()
  select_project(function(project)
    local project_file = get_project_file(project)
    vim.cmd("edit " .. vim.fn.fnameescape(project_file))
  end)
end

-- Reset current project to force selection
function M.reset_project()
  vim.g.code_notes_current_project = nil
  vim.notify("Project reset. Next action will prompt for project selection.", vim.log.levels.INFO)
end

-- Setup function
function M.setup()
  vim.keymap.set("n", "<leader>da", M.add_note, { desc = "Add code note" })
  vim.keymap.set("n", "<leader>ds", M.select_section, { desc = "Select section" })
  vim.keymap.set("n", "<leader>dr", M.open_project_file, { desc = "Open project file" })
  vim.keymap.set("n", "<leader>dp", M.reset_project, { desc = "Reset project selection" })
end

return M
