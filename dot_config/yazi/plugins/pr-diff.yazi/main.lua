--- @since 26.1.22

local WINDOWS = ya.target_family() == "windows"

local function trim(value)
	return (value:gsub("%s+$", ""))
end

---@param cwd Url
---@return string?
local function root(cwd)
	local is_worktree = function(url)
		local file, head = io.open(tostring(url)), nil
		if file then
			head = file:read(8)
			file:close()
		end
		return head == "gitdir: "
	end

	repeat
		local next = cwd:join(".git")
		local cha = fs.cha(next)
		if cha and (cha.is_dir or is_worktree(next)) then
			return tostring(cwd)
		end
		cwd = cwd.parent
	until not cwd
end

local get_cwd = ya.sync(function()
	return cx.active.current.cwd
end)

local set_state = ya.sync(function(st, repo, pr, paths)
	---@cast st State
	st.repo = repo
	st.pr = pr
	st.paths = paths or {}
	ui.render()
end)

local clear_state = ya.sync(function(st)
	---@cast st State
	st.repo = nil
	st.pr = nil
	st.paths = {}
	ui.render()
end)

local function notify(content, level)
	ya.notify {
		title = "pr-diff",
		content = content,
		level = level or "info",
		timeout = 5,
	}
end

---@param repo string
---@param pr string
---@return table<string, true>?, string?
local function fetch_paths(repo, pr)
	local output, err = Command("gh")
		:cwd(repo)
		:arg({ "pr", "diff", "--name-only", pr })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()
	if not output then
		return nil, string.format("failed to spawn `gh`: %s", tostring(err))
	end
	if not output.status.success then
		local msg = trim(output.stderr or "")
		if msg == "" then
			msg = string.format("`gh` exited with code %s", tostring(output.status.code))
		end
		return nil, msg
	end

	local set = {}
	for line in output.stdout:gmatch("[^\r\n]+") do
		local path = WINDOWS and line:gsub("/", "\\") or line
		set[path] = true
	end
	return set, nil
end

local function count(set)
	local n = 0
	for _ in pairs(set) do
		n = n + 1
	end
	return n
end

---@param st State
---@param opts table?
local function setup(st, opts)
	st.repo = nil
	st.pr = nil
	st.paths = {}

	opts = opts or {}
	opts.order = opts.order or 1400

	local t = th.pr_diff or {}
	local style = t.changed or ui.Style():fg("blue")
	local sign = t.changed_sign or opts.sign or "±"

	Linemode:children_add(function(self)
		if not self._file.in_current then
			return ""
		end
		if not st.repo or not st.paths then
			return ""
		end

		local full = tostring(self._file.url)
		if full:sub(1, #st.repo) ~= st.repo then
			return ""
		end
		local rel = full:sub(#st.repo + 2)
		if rel == "" then
			return ""
		end

		local matched = st.paths[rel] == true
		if not matched and self._file.cha and self._file.cha.is_dir then
			local prefix = rel .. "/"
			for p, _ in pairs(st.paths) do
				if p:sub(1, #prefix) == prefix then
					matched = true
					break
				end
			end
		end

		if not matched then
			return ""
		end

		if self._file.is_hovered then
			return ui.Line { " ", sign }
		else
			return ui.Line { " ", ui.Span(sign):style(style) }
		end
	end, opts.order)
end

---@param job { args: table }
local function entry(_, job)
	local pr = (job.args and job.args[1]) and tostring(job.args[1]) or nil

	if not pr then
		local value, event = ya.input {
			pos = { "top-center", y = 3, w = 40 },
			title = "PR number (empty to clear):",
		}
		if event ~= 1 then
			return -- canceled / error
		end
		value = value and trim(value) or ""
		if value == "" then
			clear_state()
			notify("cleared")
			return
		end
		pr = value
	end

	local cwd = get_cwd()
	local repo = root(cwd)
	if not repo then
		notify("not inside a git repository", "warn")
		return
	end

	local paths, err = fetch_paths(repo, pr)
	if err then
		notify(err, "error")
		return
	end
	set_state(repo, pr, paths)
	notify(string.format("PR #%s: %d file(s) marked", pr, count(paths)))
end

return { setup = setup, entry = entry }
