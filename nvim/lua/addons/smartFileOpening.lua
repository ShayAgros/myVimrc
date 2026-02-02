-- Function to transform the URL to local path
local function transform_code_amazon_url(url)
    -- Pattern to match code.amazon.com URLs
    local pattern = "code%.amazon%.com/packages/([^/]+)/blobs/([^/]+)/%-%-/(.+)"

    -- Try to match the pattern
    local package_name, commit_hash, file_path = string.match(url, pattern)
    if not package_name or not file_path then
        return nil
    end

    local linenr_start = string.find(file_path, "#L[0-9]+$")
    local line_nr
    if linenr_start then
        line_nr = string.sub(file_path, linenr_start + 2)
        file_path = string.sub(file_path, 1, linenr_start - 1)
    end

    if package_name and file_path then
        -- Construct the local file path
        local local_path = string.format("src/%s/%s", package_name, file_path)
        return local_path, tonumber(line_nr), commit_hash, file_path
    end
    return nil
end

-- Show git commit context in popup
local function show_git_context(commit_hash, file_path, line_nr, local_path)
    -- Find git root from the file's directory
    local file_dir = vim.fn.fnamemodify(local_path, ':p:h')
    local git_root = vim.fn.systemlist('git -C ' .. vim.fn.shellescape(file_dir) .. ' rev-parse --show-toplevel')[1]
    
    if not git_root or git_root == '' then
        vim.notify("Not in a git repository", vim.log.levels.ERROR)
        return
    end
    
    local cmd = string.format("git -C %s show %s:%s", vim.fn.shellescape(git_root), commit_hash, file_path)
    
    vim.fn.jobstart(cmd, {
        stdout_buffered = true,
        on_stdout = function(_, data)
            if not data then return end
            
            -- Keep all lines including empty ones, but remove the last empty line from jobstart
            local lines = data
            if #lines > 0 and lines[#lines] == "" then
                table.remove(lines, #lines)
            end
            
            if #lines == 0 then return end
            
            vim.schedule(function()
                -- Get current buffer line
                local current_line = vim.api.nvim_buf_get_lines(0, line_nr - 1, line_nr, false)[1]
                local commit_line = lines[line_nr]
                
                -- Compare lines
                if current_line == commit_line then
                    vim.notify(string.format("Line %d is the same as in %s", line_nr, commit_hash:sub(1, 8)), vim.log.levels.INFO)
                    return
                end
                
                -- Extract context around target line
                local start_line = math.max(1, line_nr - 3)
                local end_line = math.min(#lines, line_nr + 3)
                local context = {}
                
                for i = start_line, end_line do
                    local prefix = (i == line_nr) and "→ " or "  "
                    table.insert(context, prefix .. lines[i])
                end
                
                if #context == 0 then return end
                
                local buf = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_buf_set_lines(buf, 0, -1, false, context)
                vim.bo[buf].modifiable = false
                vim.bo[buf].filetype = vim.bo.filetype
                
                -- Position near cursor
                local cursor_pos = vim.api.nvim_win_get_cursor(0)
                local cursor_row = cursor_pos[1]
                
                local width = math.min(80, vim.o.columns - 4)
                local height = math.max(1, math.min(#context, vim.o.lines - 4))
                
                -- Try to position below cursor, or above if not enough space
                local row_offset = 1
                if cursor_row + height + 3 <= vim.o.lines then
                    row_offset = -row_offset
                end
                
                local opts = {
                    relative = 'cursor',
                    width = width,
                    height = height,
                    col = 0,
                    row = row_offset,
                    style = 'minimal',
                    border = 'rounded',
                    title = string.format(' Commit %s (Line %d) ', commit_hash:sub(1, 8), line_nr),
                    title_pos = 'center'
                }
                
                local win = vim.api.nvim_open_win(buf, false, opts)
                vim.api.nvim_win_set_cursor(win, {math.min(4, #context), 0})
                
                -- Map K to jump to popup window
                local original_buf = vim.api.nvim_get_current_buf()
                local cleaned_up = false
                
                local function cleanup()
                    if cleaned_up then return end
                    cleaned_up = true
                    pcall(vim.keymap.del, 'n', 'K', { buffer = original_buf })
                end
                
                vim.keymap.set('n', 'K', function()
                    if vim.api.nvim_win_is_valid(win) then
                        vim.api.nvim_set_current_win(win)
                    end
                end, { buffer = original_buf, desc = 'Jump to git context popup' })
                
                -- Close on any cursor movement in original buffer
                local close_autocmd
                close_autocmd = vim.api.nvim_create_autocmd({'CursorMoved', 'CursorMovedI'}, {
                    buffer = original_buf,
                    callback = function()
                        if vim.api.nvim_win_is_valid(win) then
                            vim.api.nvim_win_close(win, true)
                        end
                        cleanup()
                        vim.api.nvim_del_autocmd(close_autocmd)
                    end
                })
                
                vim.keymap.set('n', 'q', function()
                    vim.api.nvim_win_close(win, true)
                    cleanup()
                end, { buffer = buf })
            end)
        end,
        on_stderr = function(_, data)
            if data and #data > 0 and data[1] ~= "" then
                vim.schedule(function()
                    local error_msg = table.concat(vim.tbl_filter(function(line) return line ~= "" end, data), "\n")
                    if error_msg ~= "" then
                        vim.notify("Git show failed: " .. error_msg, vim.log.levels.WARN)
                    end
                end)
            end
        end
    })
end

-- Custom command to open code.amazon.com URLs
vim.api.nvim_create_user_command('CodeOpen', function(opts)
  local url = opts.args
  local local_path, line_number, commit_hash, file_path = transform_code_amazon_url(url)
  
  if local_path then
    vim.cmd('edit ' .. vim.fn.fnameescape(local_path))
    if line_number then
      vim.api.nvim_win_set_cursor(0, {line_number, 0})
      
      -- Asynchronously show git context to compare with commit version
      vim.schedule(function()
        show_git_context(commit_hash, file_path, line_number, local_path)
      end)
    end
  else
    vim.notify("Invalid code.amazon.com URL", vim.log.levels.ERROR)
  end
end, { nargs = 1 })

-- Abbreviation for convenience
vim.cmd('cabbrev co CodeOpen')
