local function notify(level, title, content)
	ya.notify {
		title = title,
		content = content,
		level = level,
		timeout = 5,
	}
end

local function trim(value)
	return (value:gsub("%s+$", ""))
end

local selected_or_hovered = ya.sync(function()
	local tab, paths = cx.active, {}
	for _, u in pairs(tab.selected) do
		paths[#paths + 1] = tostring(u)
	end
	if #paths == 0 and tab.current.hovered then
		paths[1] = tostring(tab.current.hovered.url)
	end
	return paths
end)

local function git_root(path)
	local dir = path
	local cha = fs.cha(Url(path))
	if cha and not cha.is_dir then
		dir = tostring(Url(path).parent)
	end

	local output, err = Command("git")
		:cwd(dir)
		:arg({ "rev-parse", "--show-toplevel" })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()
	if not output then
		return nil, err
	end
	if not output.status.success then
		return nil, trim(output.stderr)
	end
	return trim(output.stdout), nil
end

local function git_branch(root)
	local output, err = Command("git")
		:cwd(root)
		:arg({ "rev-parse", "--abbrev-ref", "HEAD" })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()
	if not output then
		return nil, err
	end
	if not output.status.success then
		return nil, trim(output.stderr)
	end
	local name = trim(output.stdout)
	if name == "HEAD" then
		local sha = Command("git")
			:cwd(root)
			:arg({ "rev-parse", "HEAD" })
			:stdout(Command.PIPED)
			:stderr(Command.PIPED)
			:output()
		if sha and sha.status.success then
			name = trim(sha.stdout)
		end
	end
	return name, nil
end

local function normalize_remote(url)
	url = trim(url)
	local host, path = url:match("^git@([^:]+):(.+)$")
	if host and path then
		url = "https://" .. host .. "/" .. path
	else
		host, path = url:match("^ssh://git@([^/]+)/(.+)$")
		if host and path then
			url = "https://" .. host .. "/" .. path
		end
	end
	return (url:gsub("%.git$", ""))
end

local function git_remote(root)
	local output, err = Command("git")
		:cwd(root)
		:arg({ "config", "--get", "remote.origin.url" })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()
	if not output then
		return nil, err
	end
	if not output.status.success then
		return nil, trim(output.stderr)
	end
	local value = trim(output.stdout)
	if value == "" then
		return nil, "remote.origin.url not set"
	end
	return normalize_remote(value), nil
end

local current_cwd = ya.sync(function()
	return tostring(cx.active.current.cwd)
end)

local function open_shell()
	local cwd = current_cwd()
	local permit = ui.hide and ui.hide() or ya.hide()
	local output, err_code = Command("zsh")
		:cwd(cwd)
		:stdin(Command.INHERIT)
		:stdout(Command.INHERIT)
		:stderr(Command.PIPED)
		:spawn()
	if output and not err_code then
		output, err_code = output:wait_with_output()
	end
	if err_code ~= nil then
		notify("error", "Shell", "Failed to run zsh: " .. err_code)
	elseif output and not output.status.success then
		notify("error", "Shell", "zsh exited with code " .. output.status.code)
	end
end

local function run_zsh_command()
	local function center_text(text, width)
		local lines = {}
		for line in (text .. "\n"):gmatch("([^\n]*)\n") do
			local len = #line
			if len >= width then
				lines[#lines + 1] = line
			else
				local pad = math.floor((width - len) / 2)
				lines[#lines + 1] = string.rep(" ", pad) .. line
			end
		end
		return table.concat(lines, "\n")
	end

	local value, event = ya.input {
		title = "zsh:",
		pos = { "top-center", y = 3, w = 60 },
	}
	if event ~= 1 or value == "" then
		return
	end

	local cwd = current_cwd()
	local output, err = Command("zsh")
		:cwd(cwd)
		:arg({ "-lc", value })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()

	if not output then
		return ya.confirm {
			pos = { "center", w = 90, h = 18 },
			title = ui.Span("Shell error"):style(ui.Style():fg("red"):bold()),
			body = center_text("Failed to run zsh: " .. tostring(err), 84),
		}
	end

	local stdout = trim(output.stdout or "")
	local stderr = trim(output.stderr or "")
	local merged = stdout
	if stderr ~= "" then
		merged = (merged == "" and stderr) or (merged .. "\n" .. stderr)
	end
	if #merged == 0 then
		merged = "(no output)"
	elseif #merged > 6000 then
		merged = merged:sub(1, 6000) .. "\n... (truncated)"
	end

	local ok = output.status.success
	local title = ui.Span(string.format("Shell output (exit %d)", output.status.code))
		:style(ui.Style():fg(ok and "green" or "red"):bold())
	local body = string.format("$ %s\n\n%s", value, merged)
	body = center_text(body, 84)

	ya.confirm {
		pos = { "center", w = 90, h = 24 },
		title = title,
		body = body,
	}
end

local function copy_contents()
	local paths = selected_or_hovered()
	if #paths == 0 then
		return notify("warn", "Copy contents", "No file selected")
	end

	local chunks = {}
	for _, path in ipairs(paths) do
		local cha = fs.cha(Url(path))
		if cha and cha.is_dir then
			return notify("warn", "Copy contents", "Directory selected: " .. path)
		end
		local file = io.open(path, "rb")
		if not file then
			return notify("error", "Copy contents", "Failed to open " .. path)
		end
		chunks[#chunks + 1] = file:read("*a") or ""
		file:close()
	end

	ya.clipboard(table.concat(chunks, "\n"))
	notify("info", "Copy contents", "Copied file contents")
end

local function copy_github_link()
	local paths = selected_or_hovered()
	if #paths == 0 then
		return notify("warn", "GitHub link", "No file selected")
	end

	local target = paths[1]
	local root, err = git_root(target)
	if not root then
		return notify("error", "GitHub link", "Not a git repo: " .. err)
	end

	local remote, rerr = git_remote(root)
	if not remote then
		return notify("error", "GitHub link", "Remote not found: " .. rerr)
	end

	local branch, berr = git_branch(root)
	if not branch then
		return notify("error", "GitHub link", "Branch not found: " .. berr)
	end

	local rel = target
	if rel:sub(1, #root) == root then
		rel = rel:sub(#root + 2)
	end
	if rel == "" then
		rel = "."
	end

	local kind = "blob"
	local cha = fs.cha(Url(target))
	if cha and cha.is_dir then
		kind = "tree"
	end

	local link = string.format("%s/%s/%s/%s", remote, kind, branch, rel)
	ya.clipboard(link)
	notify("info", "GitHub link", "Copied link")
end

local function git_add_selected()
	local paths = selected_or_hovered()
	if #paths == 0 then
		return notify("warn", "Git add", "No file selected")
	end

	local root, err = git_root(paths[1])
	if not root then
		return notify("error", "Git add", "Not a git repo: " .. err)
	end

	local rels = {}
	for _, path in ipairs(paths) do
		if path:sub(1, #root) == root then
			local rel = path:sub(#root + 2)
			if rel == "" then
				rel = "."
			end
			rels[#rels + 1] = rel
		end
	end
	if #rels == 0 then
		return notify("warn", "Git add", "No files inside repo root")
	end

	local staged_output, serr = Command("git")
		:cwd(root)
		:arg({ "diff", "--name-only", "--cached", "--" })
		:arg(rels)
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()
	if not staged_output then
		return notify("error", "Git stage", "Failed to run git: " .. serr)
	end
	if not staged_output.status.success then
		return notify("error", "Git stage", trim(staged_output.stderr))
	end

	local staged = {}
	for line in staged_output.stdout:gmatch("[^\r\n]+") do
		staged[#staged + 1] = line
	end

	local function is_staged(rel)
		for _, path in ipairs(staged) do
			if path == rel or path:sub(1, #rel + 1) == rel .. "/" then
				return true
			end
		end
		return false
	end

	local to_stage, to_unstage = {}, {}
	for _, rel in ipairs(rels) do
		if is_staged(rel) then
			to_unstage[#to_unstage + 1] = rel
		else
			to_stage[#to_stage + 1] = rel
		end
	end

	if #to_stage > 0 then
		local output, gerr = Command("git")
			:cwd(root)
			:arg({ "add", "--" })
			:arg(to_stage)
			:stderr(Command.PIPED)
			:output()
		if not output then
			return notify("error", "Git stage", "Failed to run git: " .. gerr)
		end
		if not output.status.success then
			return notify("error", "Git stage", trim(output.stderr))
		end
	end

	if #to_unstage > 0 then
		local output, gerr = Command("git")
			:cwd(root)
			:arg({ "restore", "--staged", "--" })
			:arg(to_unstage)
			:stderr(Command.PIPED)
			:output()
		if not output then
			return notify("error", "Git stage", "Failed to run git: " .. gerr)
		end
		if not output.status.success then
			return notify("error", "Git stage", trim(output.stderr))
		end
	end

	ya.emit("refresh", {})
	notify("info", "Git stage", string.format("staged %d, unstaged %d", #to_stage, #to_unstage))
end

return {
	entry = function(_, job)
		local action = job and job.args and job.args[1] or nil
		if action == "copy-contents" then
			return copy_contents()
		elseif action == "copy-github-link" then
			return copy_github_link()
		elseif action == "git-add" then
			return git_add_selected()
		elseif action == "open-shell" then
			return open_shell()
		elseif action == "run-zsh-command" then
			return run_zsh_command()
		end

		notify("warn", "Ops", "Unknown action")
	end,
}
