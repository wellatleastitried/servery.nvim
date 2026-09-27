local M = {}

---Get the elapsed time since `t` as a nicely formatted string
---@param t number
---@param finish? number
---@return string
M.time_since = function(t, finish)
	finish = finish or os.time()

	local seconds = math.floor(os.difftime(finish, t))
	local hh, mm, ss = math.floor(seconds / 3600), math.floor((seconds % 3600) / 60), seconds % 60

	if hh == 0 then
		return string.format("%02.f:%02.f", mm, ss)
	else
		return string.format("%02.f:%02.f:%02.f", hh, mm, ss)
	end
end

M.mkdir = function(dir)
	if vim.fn.mkdir(dir, "p") ~= 1 then
		error("Failed to create directory " .. dir)
	end
end

---The non-dot subdirectories of `dir`.
---@param dir string absolute path
---@return string[]
M.child_dirs = function(dir)
	local out = {}
	for name, type in vim.fs.dir(dir) do
		if type == "directory" and name:sub(1, 1) ~= "." then
			out[#out + 1] = vim.fs.joinpath(dir, name)
		end
	end
	return out
end

---The git repositories in `roots`, and up to `max_depth` levels below them.
---
---A repository is a directory containing a `.git` *directory*; the `.git` file
---of a submodule or worktree doesn't count. Neither is descended into, so
---submodules and vendored repositories are never reported separately.
---@param roots string[] absolute paths
---@param max_depth integer 0 searches the roots themselves, `math.huge` their
---   whole subtree
---@return string[]
M.git_repos = function(roots, max_depth)
	local out = {}

	local function scan(dir, depth)
		local stat = vim.uv.fs_stat(vim.fs.joinpath(dir, ".git"))

		if stat and stat.type == "directory" then
			out[#out + 1] = dir
		elseif not stat and depth < max_depth then
			for _, sub in ipairs(M.child_dirs(dir)) do
				scan(sub, depth + 1)
			end
		end
	end

	for _, root in ipairs(roots) do
		scan(root, 0)
	end

	table.sort(out)
	return out
end

return M
