#!/usr/bin/env python3
"""Builds tools/statues/hallretry1.lua (job 107b): the French Hall of Fame's empty frame (Shannon, Oct 15 2026: "the statue in the
monument for star is completely gone"; runner 7: STAR = Captin_crunch65, No. 2 - builds fine in a play test, so the LIVE build failed
once, and a failed build is neither cached nor asked for again: the client clears the frame and shows nothing until someone pages
away and back). Two exact-string patches: workspace.HallOfFame.HallServer's build() tries MakeStatue twice (2 s apart) before giving up;
HallClient asks up to three times (4 s apart) while that statue is still the one wanted. Backups HudBackup.HallServer_pre_hallretry1 /
HallClient_pre_hallretry1; marker HALLRETRY1. Self-test: the server patch on the live export (tools/statues/studio_2026-10-15/
HallServer_France.lua), the client patch on the repo's domaine/build_halloffame.lua (the runner confirms the live client). Run from the repo root."""
import pathlib, subprocess, os
ROOT = pathlib.Path(__file__).resolve().parents[2]
HERE = pathlib.Path(__file__).resolve().parent
SF = '''	local ok, fig, acorn = pcall(function()
		return makeStatue:Invoke({uid = e.uid, name = e.name, no = e.no, day = e.day}, {x = low.X, top = low.Y, z = low.Z, parent = stage, name = "Figure", scale = F:GetAttribute("Scale") or 1.25, look = LOOK})
	end)
'''
SR = '''	local ok, fig, acorn
	for attempt = 1, 2 do   -- HALLRETRY1_20261015: a hiccup fetching the avatar is tried once more before the frame is left empty
		ok, fig, acorn = pcall(function()
			return makeStatue:Invoke({uid = e.uid, name = e.name, no = e.no, day = e.day}, {x = low.X, top = low.Y, z = low.Z, parent = stage, name = "Figure", scale = F:GetAttribute("Scale") or 1.25, look = LOOK})
		end)
		if ok and fig then break end
		if attempt == 1 then warn("HallServer: statue No. " .. tostring(no) .. " failed once (" .. tostring(fig) .. "); trying again"); task.wait(2) end
	end
'''
CF = '''		local ok, name = pcall(function() return fn:InvokeServer(e.no) end)
		if mine ~= want then return end                                  -- (scrolled on while it was being made)
		local src = ok and name and store:WaitForChild(name, 15)
'''
CR = '''		local ok, name, src
		for attempt = 1, 3 do   -- HALLRETRY1_20261015: a statue that failed to build is asked for again, not left as an empty frame
			ok, name = pcall(function() return fn:InvokeServer(e.no) end)
			if mine ~= want then return end                                  -- (scrolled on while it was being made)
			src = ok and name and store:WaitForChild(name, 15)
			if src then break end
			if mine ~= want then return end
			task.wait(4)
		end
'''
def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"
srv = (HERE / "studio_2026-10-15/HallServer_France.lua").read_text(encoding="utf-8")
assert srv.count(SF) == 1 and "HALLRETRY1" not in srv
chk = HERE / "check"; chk.mkdir(exist_ok=True)
(chk / "HallServer_France_hallretry1.lua").write_text(srv.replace(SF, SR), encoding="utf-8")
cli = (HERE / "studio_2026-10-15/HallClient_France.lua").read_text(encoding="utf-8")   # the live export (4155 bytes)
assert cli.count(CF) == 1 and "HALLRETRY1" not in cli
luau = os.environ.get("LUAU_COMPILE")
if luau:
    r = subprocess.run([luau, "--null", str(chk / "HallServer_France_hallretry1.lua")], capture_output=True, text=True)
    assert "Error" not in (r.stdout + r.stderr), r.stdout + r.stderr
    # the client: compile the patched client snippet inside a stub of its surroundings
    stub = "local fn, store, want, view, e, mine, shownNo = nil, nil, 1, nil, {no = 1}, 1, nil\ntask.spawn(function()\n" + CR + "\t\tif mine ~= want then return end\n\t\tview:ClearAllChildren()\n\t\tif src then local c = src:Clone(); c.Parent = view; shownNo = e.no end\nend)\n"
    (chk / "HallClient_snippet_hallretry1.lua").write_text(stub, encoding="utf-8")
    r = subprocess.run([luau, "--null", str(chk / "HallClient_snippet_hallretry1.lua")], capture_output=True, text=True)
    assert "Error" not in (r.stdout + r.stderr), r.stdout + r.stderr
    print("self-test: the patched HallServer and the client snippet compile")
lua = r'''-- statues/hallretry1 (job 107b): EDIT mode. The French Hall of Fame no longer leaves an empty frame when a statue's build fails once
-- (Shannon, Oct 15 2026: "the statue in the monument for star is completely gone"). Two exact-string patches: workspace.HallOfFame
-- .HallServer tries MakeStatue twice; .HallClient asks up to three times. Anchors counted first; compiled where loadstring runs;
-- backups HudBackup.<Name>_pre_hallretry1. Output "QQ HALL".
if game:GetService("RunService"):IsRunning() then print("QQ HALL ABORT - Play mode") return end
local SS = game:GetService("ServerStorage")
local H = workspace:FindFirstChild("HallOfFame")
if not H then print("QQ HALL ABORT - no workspace.HallOfFame") return end
local JOBS = {{name = "HallServer", f = @@SF@@, r = @@SR@@}, {name = "HallClient", f = @@CF@@, r = @@CR@@}}
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
'''
for k, v in {"@@SF@@": L(SF), "@@SR@@": L(SR), "@@CF@@": L(CF), "@@CR@@": L(CR)}.items():
    assert lua.count(k) == 1; lua = lua.replace(k, v)
assert "@@" not in lua
(HERE / "hallretry1.lua").write_text(lua, encoding="utf-8")
print("hallretry1.lua", len(lua.encode()), "bytes")
