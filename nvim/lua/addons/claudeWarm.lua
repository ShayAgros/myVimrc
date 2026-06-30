-- Pre-warm claude terminal in a hidden buffer on startup.
-- When the user hits \ac for the first time, the terminal is already
-- initialized and just needs to be shown (instant instead of ~5s cold start).
local M = {}

function M.setup()
    vim.defer_fn(function()
        local ok, claude = pcall(require, "claude-code")
        if not ok or not claude.config or not claude.config.command then return end

        -- Don't warm if already has an instance
        local git = require("claude-code.git")
        local git_root = git.get_git_root()
        local instance_id = git_root or vim.fn.getcwd()
        if not claude.config.git or not claude.config.git.multi_instance then
            instance_id = "global"
        end
        if claude.claude_code.instances[instance_id] then return end

        -- Create a hidden terminal buffer with claude running
        local bufnr = vim.api.nvim_create_buf(false, true) -- unlisted, scratch
        vim.api.nvim_set_option_value("bufhidden", "hide", { buf = bufnr })

        -- Build the command
        local cmd = claude.config.command
        if claude.config.git and claude.config.git.use_git_root and git_root then
            cmd = "cd " .. vim.fn.shellescape(git_root) .. " && " .. cmd
        end

        -- Open in a temporary window (termopen needs a window), then hide it
        local orig_win = vim.api.nvim_get_current_win()
        vim.cmd("botright 1split")
        local temp_win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(temp_win, bufnr)
        vim.fn.termopen(cmd)
        vim.api.nvim_set_option_value("bufhidden", "hide", { buf = bufnr })

        -- Name the buffer so the plugin recognizes it
        local buf_name = "claude-code"
        if claude.config.git and claude.config.git.multi_instance then
            buf_name = "claude-code-" .. instance_id:gsub("[^%w%-_]", "-")
        end
        pcall(vim.api.nvim_buf_set_name, bufnr, buf_name)

        -- Register with the plugin's instance tracking
        claude.claude_code.instances[instance_id] = bufnr
        claude.claude_code.current_instance = instance_id

        -- Mark as claude-code terminal for the plugin's detection
        _G.claude_code_terminal_buffers = _G.claude_code_terminal_buffers or {}
        _G.claude_code_terminal_buffers[bufnr] = true

        -- Close the temp window, return to original
        vim.api.nvim_win_close(temp_win, true)
        if vim.api.nvim_win_is_valid(orig_win) then
            vim.api.nvim_set_current_win(orig_win)
        end
    end, 2000) -- 2 second delay to not block startup
end

return M
