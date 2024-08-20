-- Check if the current file belongs to a git directory
local api = vim.api

local function escape(s)
    return (s:gsub('[%-%.%+%[%]%(%)%$%^%%%?%*]','%%%1'))
end

local function get_git_dir()
    local file_name = api.nvim_buf_get_name(0)

    -- This should check whether we're in a real
    -- file and not a temo buffer
    local f = io.open(file_name, "r")
    if f then
        f:close()
    else
        return
    end

	local file_dir = file_name:match("(.*/)")

    local command_ctx = vim.system(
        {
            "git",
            "rev-parse",
            "--sq",
            "--show-toplevel"
        },
        {
            cwd = file_dir,
        }):wait()

    local git_dir, _ = command_ctx.stdout:gsub("[\n\r]", "")
    return command_ctx.code == 0 and git_dir or ""
end

local function get_current_remote_hash()
	local file_name = api.nvim_buf_get_name(0)
	local file_dir = string.match(file_name, "(.*/)")

    local command_ctx = vim.system(
        {
            "git",
            "rev-parse",
            "--short",
            "refs/remotes/origin/HEAD",
        },
        {
            cwd = file_dir,
        }):wait()

    local remote_hash, _ = string.gsub(command_ctx.stdout, "[\n\r]", "")
    return command_ctx.code == 0 and remote_hash or ""
end

local function get_origin_host(git_dir)
     -- local command_ctx = vim.system(
    local command_ctx = vim.system(
        {
            "git",
            "remote",
            "get-url",
            "origin"
        },
        {
            cwd = git_dir
        }):wait()

    if command_ctx.code ~= 0 then
        return
    end

    local remote_url = command_ctx.stdout
    if type(remote_url) ~= "string" then
        return
    end

    remote_url = string.gsub(remote_url, "[\n\r]", "")

    local host, repo

    -- Try to parse different formats

    -- ssh://shayagr@gerrit.anpa.corp.amazon.com:29418/ena-drivers
    _, _, host, repo = string.find(remote_url, "ssh://%a+@([%a%.]+)[:%d]*/([%a%p]+)")
    if host and repo then
        return host, repo
    end

    -- ssh://git.amazon.com:2222/pkg/Aws-c-io
    _, _, host, repo = string.find(remote_url, "ssh://([%a%.]+)[:%d]*/([%a%p]+)")
    if host and repo then
        return host, repo
    end

    -- https://github.com/amzn/amzn-drivers.git
    _, _, host, repo = string.find(remote_url, "https://([^/]+)/(.+)")
    if host and repo then
        return host, repo
    end

    -- git://git.kernel.org/pub/scm/linux/kernel/git/netdev/net-next.git
    _, _, host, repo = string.find(remote_url, "git://([^/]+)/(.+)")
    if host and repo then
        return host, repo
    end

    -- git@github.com:amzn/amzn-drivers.git
    _, _, host, repo = string.find(remote_url, "git@([^:]+):(.+)")
    if host and repo then
        return host, repo
    end

    return nil
end

local function copy_gerrit_link()
    local git_dir = get_git_dir()
    local remote_hash = get_current_remote_hash()

    print("function called", remote_hash, git_dir)
    if git_dir == "" or remote_hash == "" then
        return
    end

    if type(git_dir) ~= "string" or type(git_dir) ~= "string" then
        return
    end

    local gerrit_base_url = "https://gerrit.anpa.corp.amazon.com:9080/plugins/gitiles/"
	local git_proj_name = vim.fn.fnamemodify(git_dir, ":t")
	local gerrit_url = gerrit_base_url .. git_proj_name .. "/+"

	local file_path = api.nvim_buf_get_name(0)
    file_path = string.gsub(file_path, escape(git_dir) .. "/", "")
	local line_nr = vim.fn.line('.')

    print(gerrit_url .. "/" .. remote_hash  .. "/" .. file_path .. "#" .. line_nr)
	vim.fn.setreg("+", gerrit_url .. "/" .. remote_hash  .. "/" .. file_path .. "#" .. line_nr)
end

local function copy_github_link()
    local git_dir = get_git_dir()
    local remote_hash = get_current_remote_hash()

    print("function called", remote_hash, git_dir)
    if git_dir == "" or remote_hash == "" then
        return
    end

    if type(git_dir) ~= "string" or type(git_dir) ~= "string" then
        return
    end

    local _, project_name = get_origin_host(git_dir)
    if not project_name then
        return
    end

    project_name = string.gsub(project_name, "%.git", "")

    local base_url = "https://github.com/" .. project_name .. "/blob"
	local file_path = api.nvim_buf_get_name(0):gsub(escape(git_dir) .. "/", "")
	local line_nr = vim.fn.line('.')
    local url = base_url .. "/" .. remote_hash .. "/" .. file_path .. "#L" .. line_nr

    print(url)
    vim.fn.setreg("+", url)
end

local function copy_linux_repo_link()
    local git_dir = get_git_dir()
    local remote_hash = get_current_remote_hash()

    print("function called", remote_hash, git_dir)
    if git_dir == "" or remote_hash == "" then
        return
    end

    if type(git_dir) ~= "string" or type(git_dir) ~= "string" then
        return
    end

    local _, project_name = get_origin_host(git_dir)
    if not project_name then
        return
    end

	local linux_base_url = "https://git.kernel.org/"
	local linux_url = linux_base_url .. project_name .. "/tree"
	local file_path = api.nvim_buf_get_name(0):gsub(escape(git_dir) .. "/", "")
	local line_nr = vim.fn.line('.')

    local url = linux_url .. "/" .. file_path .. "?id=" .. remote_hash .. "#n" .. line_nr
    print(url)
    vim.fn.setreg("+", url)
end

local function copy_amazon_code_link()
    local git_dir = get_git_dir()
    local remote_hash = get_current_remote_hash()

    print("function called", remote_hash, git_dir)
    if git_dir == "" or remote_hash == "" then
        return
    end

    if type(git_dir) ~= "string" or type(git_dir) ~= "string" then
        return
    end

    local _, project_name = get_origin_host(git_dir)
    if not project_name then
        return
    end

	project_name = vim.fn.fnamemodify(project_name, ":t")
	local amazon_base_url = "https://code.amazon.com/packages/"
    amazon_base_url = amazon_base_url .. project_name .. "/blobs"
	local file_path = api.nvim_buf_get_name(0):gsub(escape(git_dir) .. "/", "")
	local line_nr = vim.fn.line('.')
    local url = amazon_base_url .. "/" .. remote_hash  .. "/--/" .. file_path .. "#L" .. line_nr

    print(url)
    vim.fn.setreg("+", url)
end

local function setup()
    local git_dir = get_git_dir()

    -- if we're not inside a git directory we wouldn't be
    -- able to find the remote link for a line
    if git_dir == "" then
        return
    end

    local origin_host, _ = get_origin_host(git_dir)
    if not origin_host then
        return
    end

    local url_func
    if string.find(origin_host, "github") then
        url_func = copy_github_link
        print("Found github repo")
    elseif string.find(origin_host, "gerrit.anpa") then
        url_func = copy_gerrit_link
        print("found a gerrit repo")
    elseif string.find(origin_host, "git.amazon") then
        url_func = copy_amazon_code_link
        print("found code amazon")
    elseif string.find(origin_host, "kernel.org") then
        url_func = copy_linux_repo_link
        print("found linux kernel repo")
    end

    if url_func then
        vim.keymap.set("n", "<leader>cl", url_func)
    end
end

-- Check if a new buffer can support copying line number to repository
local copy_web_link_au = vim.api.nvim_create_augroup("copy_web_linkAU", {})
vim.api.nvim_create_autocmd({ "BufReadPost" }, {
   group = copy_web_link_au,
   callback = setup,
})
