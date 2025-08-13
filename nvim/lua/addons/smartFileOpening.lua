-- Function to transform the URL to local path
local function transform_code_amazon_url(url)
    -- Pattern to match code.amazon.com URLs
    local pattern = "code%.amazon%.com/packages/([^/]+)/blobs/[^/]+/%-%-/(.+)"

    -- Try to match the pattern
    local package_name, file_path = string.match(url, pattern)
    if not package_name or not file_path then
        return nil
    end

    linenr_start, _ = string.find(file_path, "#L[0-9]+$")
    if linenr_start then
        line_nr = string.sub(file_path, linenr_start)
        file_path = string.sub(file_path, 1, linenr_start - 1)
    else
        line_nr = 1
    end

    if package_name and file_path then
        -- Construct the local file path
        local local_path = string.format("src/%s/%s", package_name, file_path)
        return local_path, tonumber(line_number)
    end
    return nil
end

vim.api.nvim_create_autocmd("BufReadCmd", {
  pattern = "code.amazon.com/*",
  callback = function(args)
    local url = args.match
    local local_path, line_number = transform_code_amazon_url(url)
    
    if local_path then
      -- Read the local file into the current buffer
      vim.cmd("read " .. local_path)
      -- Remove the extra empty line at the top
      vim.cmd("1delete")
      -- Set the buffer as unmodified
      -- vim.cmd("set nomodified")
      -- Set the buffer name to the local path
      vim.cmd("file " .. local_path)
      
      -- Jump to the specific line if line number is present
      if line_number then
        vim.schedule(function()
          vim.cmd(":" .. line_number)
        end)
      end
    end
    return true
  end
})
