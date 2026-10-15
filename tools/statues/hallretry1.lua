-- statues/hallretry1 (job 107b): EDIT mode. The French Hall of Fame no longer leaves an empty frame when a statue's build fails once
-- (Shannon, Oct 15 2026: "the statue in the monument for star is completely gone"). Two exact-string patches: workspace.HallOfFame
-- .HallServer tries MakeStatue twice; .HallClient asks up to three times. Anchors counted first; compiled where loadstring runs;
-- backups HudBackup.<Name>_pre_hallretry1. Output "QQ HALL".
if game:GetService("RunService"):IsRunning() then print("QQ HALL ABORT - Play mode") return end
local SS = game:GetService("ServerStorage")
local H = workspace:FindFirstChild("HallOfFame")
if not H then print("QQ HALL ABORT - no workspace.HallOfFame") return end
local JOBS = {{name = "HallServer", f = [===[
	local ok, fig, acorn = pcall(function()
		return makeStatue:Invoke({uid = e.uid, name = e.name, no = e.no, day = e.day}, {x = low.X, top = low.Y, z = low.Z, parent = stage, name = "Figure", scale = F:GetAttribute("Scale") or 1.25, look = LOOK})
	end)
]===], r = [===[
	local ok, fig, acorn
	for attempt = 1, 2 do   -- HALLRETRY1_20261015: a hiccup fetching the avatar is tried once more before the frame is left empty
		ok, fig, acorn = pcall(function()
			return makeStatue:Invoke({uid = e.uid, name = e.name, no = e.no, day = e.day}, {x = low.X, top = low.Y, z = low.Z, parent = stage, name = "Figure", scale = F:GetAttribute("Scale") or 1.25, look = LOOK})
		end)
		if ok and fig then break end
		if attempt == 1 then warn("HallServer: statue No. " .. tostring(no) .. " failed once (" .. tostring(fig) .. "); trying again"); task.wait(2) end
	end
]===]}, {name = "HallClient", f = [===[
		local ok, name = pcall(function() return fn:InvokeServer(e.no) end)
		if mine ~= want then return end                                  -- (scrolled on while it was being made)
		local src = ok and name and store:WaitForChild(name, 15)
]===], r = [===[
		local ok, name, src
		for attempt = 1, 3 do   -- HALLRETRY1_20261015: a statue that failed to build is asked for again, not left as an empty frame
			ok, name = pcall(function() return fn:InvokeServer(e.no) end)
			if mine ~= want then return end                                  -- (scrolled on while it was being made)
			src = ok and name and store:WaitForChild(name, 15)
			if src then break end
			if mine ~= want then return end
			task.wait(4)
		end
]===]}}
local work = {}
for _, j in ipairs(JOBS) do
	local s = H:FindFirstChild(j.name)
	if not (s and s:IsA("LuaSourceContainer")) then print("QQ HALL ABORT - missing HallOfFame." .. j.name) return end
	local o = s.Source
	if o:find("HALLRETRY1", 1, true) then print("QQ HALL " .. j.name .. " already patched (" .. #o .. ")")
	else
		local a, b = o:find(j.f, 1, true)
		if not a then print("QQ HALL ABORT - " .. j.name .. " anchor not found (" .. #o .. " chars); nothing changed") return end
		if o:find(j.f, b + 1, true) then print("QQ HALL ABORT - " .. j.name .. " anchor matches more than once; nothing changed") return end
		local n = o:sub(1, a - 1) .. j.r .. o:sub(b + 1)
		local ok, fn, err = pcall(function() return loadstring(n) end)
		if ok and not fn then print("QQ HALL ABORT - patched " .. j.name .. " does not compile: " .. tostring(err) .. "; nothing changed") return end
		table.insert(work, {s = s, o = o, n = n, name = j.name})
	end
end
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
for _, w in ipairs(work) do
	if not hb:FindFirstChild(w.name .. "_pre_hallretry1") then local c = w.s:Clone(); if c then c.Name = w.name .. "_pre_hallretry1"; if c:IsA("BaseScript") then c.Enabled = false end; c.Parent = hb end end
end
for _, w in ipairs(work) do w.s.Source = w.n; print(string.format("QQ HALL %s %d -> %d chars (backup HudBackup.%s_pre_hallretry1)", w.name, #w.o, #w.n, w.name)) end
print("QQ HALL DONE: " .. #work .. " patched")
