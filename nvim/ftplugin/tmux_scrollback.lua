-- ftplugin/tmux_scrollback.lua

-- Function to jump to the last prompt in the file (with content)
local function jump_to_last_prompt()
    -- Move to the end of the file
    vim.cmd('normal! G')

    -- Search backwards for prompts that have content after them
    -- Format 1: [path] return_code ⭆ command
    -- Format 2: ➜ dirname git:(branch) command or ➜ dirname command
    local prompt_pattern = '\\(\\[.*\\] \\d\\+ ⭆\\|➜ \\S\\+\\( git:(\\S\\+)\\)\\?\\) \\S'
    vim.fn.search(prompt_pattern, 'bW')
    print("executed")
end

-- Jump to last prompt when the buffer is displayed in a window
vim.api.nvim_create_autocmd('BufWinEnter', {
    pattern = '*.tmux_scrollback',
    callback = function()
        if vim.bo.filetype == 'tmux_scrollback' then
            -- Use vim.defer_fn to ensure the buffer is fully loaded
            vim.defer_fn(jump_to_last_prompt, 10)
        end
    end
})

-- Map K to jump to previous prompt with content (backward search)
vim.keymap.set('n', 'K', function()
    -- Search backwards for prompts that have content after them
    -- Format 1: [path] return_code ⭆ command
    -- Format 2: ➜ dirname git:(branch) command or ➜ dirname command
    local prompt_pattern = '\\(\\[.*\\] \\d\\+ ⭆\\|➜ \\S\\+\\( git:(\\S\\+)\\)\\?\\) \\S'
    vim.fn.search(prompt_pattern, 'bW')
end, { buffer = true, desc = 'Jump to previous prompt with content' })

-- Map J to jump to next prompt with content (forward search)
vim.keymap.set('n', 'J', function()
    -- Search forwards for prompts that have content after them
    -- Format 1: [path] return_code ⭆ command
    -- Format 2: ➜ dirname git:(branch) command or ➜ dirname command
    local prompt_pattern = '\\(\\[.*\\] \\d\\+ ⭆\\|➜ \\S\\+\\( git:(\\S\\+)\\)\\?\\) \\S'
    vim.fn.search(prompt_pattern, 'W')
end, { buffer = true, desc = 'Jump to next prompt with content' })
