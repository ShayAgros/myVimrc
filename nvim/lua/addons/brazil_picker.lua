local M = {}

local brazil_root = vim.fn.expand("~/workspace/brazil")

local function open_subdir_picker(ws_name)
  local src_dir = brazil_root .. "/" .. ws_name .. "/src"
  Snacks.picker.pick({
    title = "Brazil Packages: " .. ws_name,
    finder = function(_, ctx)
      return require("snacks.picker.source.proc").proc(ctx:opts({
        cmd = "ls",
        args = { "--color=never", "-t" },
        cwd = src_dir,
        transform = function(item)
          item.file = src_dir .. "/" .. item.text
          item.dir = true
        end,
      }), ctx)
    end,
    format = "file",
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.cmd.edit(src_dir .. "/" .. item.text)
      end
    end,
    actions = {
      pick_files = function(picker, item)
        if not item then return end
        picker:close()
        Snacks.picker.files({ pattern = "file:!build/ ", cwd = src_dir .. "/" .. item.text })
      end,
    },
    win = {
      input = {
        keys = {
          ["<C-j>"] = { "pick_files", mode = { "n", "i" } },
        },
      },
    },
  })
end

--- Open a Snacks picker listing brazil workspace directories (sorted by mtime).
--- Enter opens dired in the selected directory.
--- Ctrl-j drills into src/ subdirectories first, then opens dired.
function M.pick()
  Snacks.picker.pick({
    title = "Brazil Workspaces",
    finder = function(_, ctx)
      return require("snacks.picker.source.proc").proc(ctx:opts({
        cmd = "ls",
        args = { "--color=never", "-t" },
        cwd = brazil_root,
        transform = function(item)
          item.file = brazil_root .. "/" .. item.text
          item.dir = true
        end,
      }), ctx)
    end,
    format = "file",
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.cmd.edit(brazil_root .. "/" .. item.text)
      end
    end,
    actions = {
      browse_src = function(picker, item)
        if not item then return end
        picker:close()
        open_subdir_picker(item.text)
      end,
    },
    win = {
      input = {
        keys = {
          ["<C-j>"] = { "browse_src", mode = { "n", "i" }, desc = "Browse src/ packages" },
        },
      },
    },
  })
end

return M
