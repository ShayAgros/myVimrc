-- Utilities functions used around in my scripts

local utils = {}

-- Search for a parent directory containing a .git directory.
-- Returns nil if none was found
function utils.get_git_dir(path)
  local function is_root_dir(path)
    return path == "/"
  end

  for _ = 1, 100 do
    if is_root_dir(path) then
      break
    end

    path = vim.loop.fs_realpath(path .. "/..")

    if not path then
      break
    end

    if vim.loop.fs_realpath(path .. "/.git") then
      return path
    end
  end

  return nil
end

return utils
