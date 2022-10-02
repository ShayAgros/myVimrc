-- Identify project and configure it accordingly

local api = vim.api

M = {}

local function escape(s)
    return (s:gsub('[%-%.%+%[%]%(%)%$%^%%%?%*]','%%%1'))
end

M._get_git_dir = function()

	local file_name = api.nvim_buf_get_name(0)
	local file_dir = file_name:match("(.*/)")

	local git_dir = vim.fn.system("git -C " .. file_dir.. " rev-parse --sq --show-toplevel 2> /dev/null")
	return vim.v.shell_error == 0, git_dir:gsub("[\n\r]", "")
end

M.Copy_gerrit_link = function(self)
	local success, git_proj_path = self._get_git_dir()
	if not success then
		print("Couldn't identify git dir")
		do return end
	end

	local git_proj_name = vim.fn.fnamemodify(git_proj_path, ":t")
	local origin_hash = vim.fn.system("git -C " .. git_proj_path .. " rev-parse refs/remotes/origin/HEAD"):gsub("[\n\r]", "")
	if vim.v.shell_error ~= 0 then
		print("Couldn't execute the command:", "git -C " .. git_proj_path .. " rev-parse refs/remotes/origin/HEAD")
		do return end
	end

	local gerrit_base_url = "https://gerrit.anpa.corp.amazon.com:9080/plugins/gitiles/"
	local gerrit_url = gerrit_base_url .. git_proj_name .. "/+"

	local file_path = api.nvim_buf_get_name(0):gsub(escape(git_proj_path) .. "/", "")
	local line_nr = vim.fn.line('.')
	vim.fn.setreg("+", gerrit_url .. "/" .. origin_hash  .. "/" .. file_path .. "#" .. line_nr)
end

M.CopyAmazonCodeLink = function(self)
	local success, git_proj_path = self._get_git_dir()
	if not success then
		print("Couldn't identify git dir")
		do return end
	end

	local git_proj_name = vim.fn.fnamemodify(git_proj_path, ":t")
	local origin_hash = vim.fn.system("git -C " .. git_proj_path .. " rev-parse refs/remotes/origin/HEAD"):gsub("[\n\r]", "")
	if vim.v.shell_error ~= 0 then
		print("Couldn't execute the command:", "git -C " .. git_proj_path .. " rev-parse refs/remotes/origin/HEAD")
		do return end
	end

	local amazon_base_url = "https://code.amazon.com/packages/"
	local amazon_code_utl = amazon_base_url .. git_proj_name .. "/blobs"

	local file_path = api.nvim_buf_get_name(0):gsub(escape(git_proj_path) .. "/", "")
	local line_nr = vim.fn.line('.')
	vim.fn.setreg("+", amazon_code_utl .. "/" .. origin_hash  .. "/--/" .. file_path .. "#L" .. line_nr)
end

--- Identify what project is being used and configure it accordingly. If the
-- project isn't known, then don't configure anything
M.configure_c_project = function(self)
	local success, git_proj_path = self._get_git_dir()
	if not success then
		print("Couldn't identify git dir")
		do return end
	end

	local amazon_gerrit_repos = {["ena-drivers"] = true, ["ena-com"] = true, ["ena"] = true}
	local git_proj_name = vim.fn.fnamemodify(git_proj_path, ":t")

	-- defaults
	vim.b.dispatch = "gcc % -o " .. vim.fn.expand("%:r")
	vim.opt_local.shiftwidth = 8
	vim.opt_local.tabstop = 8
	vim.opt_local.expandtab = false

	-- CRT project
	local map_ops = {noremap = true, silent = true}
	if git_proj_name:find("aws%-c%-%w") ~= nil then
		vim.opt_local.shiftwidth = 4
		vim.opt_local.tabstop = 4
		vim.opt_local.expandtab = true

		-- vim dispatch plugin
		vim.b.dispatch = "make -C aws-c-io/build"
		api.nvim_buf_set_keymap(0, "n", "<space>cl", '<cmd>lua require("project_settings"):CopyAmazonCodeLink()<cr>', map_ops)
		api.nvim_buf_set_keymap(0, "n", "<space>cs", '<cmd>call jobstart(\'tmux split-window -d -p 20 "cd aws-c-io ; ~/workspace/scripts/send_changed_files.sh -i 1"\')<cr>', map_ops)
	elseif amazon_gerrit_repos[git_proj_name] ~= nil then

		vim.b.dispatch = "make"
		api.nvim_buf_set_keymap(0, "n", "<space>cl", '<cmd>lua require("project_settings"):Copy_gerrit_link()<cr>', map_ops)
		api.nvim_buf_set_keymap(0, "n", "<space>cs", '<cmd>call jobstart(\'tmux split-window -d -p 20 "~/workspace/scripts/send_changed_files.sh -i 1"\')<cr>', map_ops)
	elseif git_proj_name:lower():find("libdx") then
		api.nvim_buf_set_keymap(0, "n", "<space>cl", '<cmd>lua require("project_settings"):CopyAmazonCodeLink()<cr>', map_ops)
	end

end

return M
--print(M:_get_git_dir())
--print(M:configure_c_project())
