#!/usr/bin/env python3
"""Builds tools/tools_src/phone_tools1.lua (job 71): the slingshot and the binoculars on a phone, and the hoop note in Porto.
Shannon (Oct 10, her phone in the square): no HOLD TO SHOOT button, the binoculars did "NOTHING"; the slingshot "gives me a
note about a basketball hoop, which does not apply in the Italy map". Cause (runner 3): the tools decide touch mode once at
start with UIS.TouchEnabled and not UIS.MouseEnabled, and MouseEnabled can read true on a touch phone, so both ran in mouse
mode (no button; a tap fires Activated and Deactivated together, so the zoom cancels at once). Four exact-string patches of
the job 70 exports: SlingClient (16373) - touch by UIS.PreferredInput, switching to touch when a finger arrives, the HOLD
button at the bottom middle clear of Roblox's capture bar, away from every hoop the acorn goes where you look (a point
shot at the spot in the middle of the screen) and the note says so; BinocularsClient (7981) - the same touch test, live;
DailyClient (14785) and QuestionClient (28363) - their phone layout test by PreferredInput. workspace.Hoop gets HoopRange
150. Backups <Name>_pre_phone1 in ServerStorage.HudBackup. Run from the repo root: python3 tools/tools_src/make_phone_tools1.py
"""
import pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/tools_src"
def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"
TOUCHNOW = ('local function touchNow()   -- a phone? PreferredInput knows (MouseEnabled can read true on a touch phone - Shannon, Oct 10: no HOLD button, binoculars dead)\n'
            '\tlocal ok, pi = pcall(function() return UIS.PreferredInput end)\n'
            '\tif ok and pi ~= nil then return pi == Enum.PreferredInput.Touch end\n'
            '\treturn UIS.TouchEnabled and not UIS.MouseEnabled\n'
            'end\n')
SLING = [
    ('local touchAim = (UIS.TouchEnabled and not UIS.MouseEnabled) or workspace.Hoop:GetAttribute("ForceTouch") == true   -- a phone: hold a button, the shot aims itself; a mouse aims with the cursor\n'
     'if touchAim then tool.ManualActivationOnly = true end          -- so a tap on the screen (or a camera drag) is not a shot\n',
     TOUCHNOW +
     'local touchAim = touchNow() or workspace.Hoop:GetAttribute("ForceTouch") == true   -- a phone: hold a button, the shot aims itself; a mouse aims with the cursor\n'
     'if touchAim then tool.ManualActivationOnly = true end          -- so a tap on the screen (or a camera drag) is not a shot\n'),
    ('local hold = Instance.new("TextButton"); hold.Name = "Shoot"; hold.AnchorPoint = Vector2.new(1, 1); hold.Position = UDim2.new(1, -26, 1, -150)\n'
     'hold.Size = UDim2.fromOffset(150, 150); hold.BackgroundColor3 = C(255, 202, 62); hold.BackgroundTransparency = 0.08; hold.BorderSizePixel = 0\n',
     'local hold = Instance.new("TextButton"); hold.Name = "Shoot"; hold.AnchorPoint = Vector2.new(0.5, 1); hold.Position = UDim2.new(0.5, 0, 1, -34)   -- bottom middle: clear of Roblox\'s capture bar, the jump button and the thumbstick (Oct 10)\n'
     'hold.Size = UDim2.fromOffset(130, 130); hold.BackgroundColor3 = C(255, 202, 62); hold.BackgroundTransparency = 0.08; hold.BorderSizePixel = 0\n'),
    ('\t\tsay(touchAim and "Hold the big button to draw - longer goes further - let go to shoot. It flies at the nearest hoop."\n'
     '\t\t\tor "Put the cursor on the hoop. Hold to draw - longer goes further - let go to shoot.", false, 4.5)\n'
     '\tend\nend\n',
     '\t\tlocal root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")\n'
     '\t\tif not root or nearestHoopDist(root.Position) > (workspace.Hoop:GetAttribute("HoopRange") or 150) then\n'
     '\t\t\t-- away from every hoop (Porto): the acorn simply goes where you look (Shannon, Oct 10: the hoop note "does not apply in the Italy map")\n'
     '\t\t\tsay(touchAim and "Hold the big button to draw - longer goes further - let go and the acorn flies where you are looking."\n'
     '\t\t\t\tor "Hold to draw - longer goes further - let go to shoot where the cursor points.", false, 4.5)\n'
     '\t\telse\n'
     '\t\t\tsay(touchAim and "Hold the big button to draw - longer goes further - let go to shoot. It flies at the nearest hoop."\n'
     '\t\t\t\tor "Put the cursor on the hoop. Hold to draw - longer goes further - let go to shoot.", false, 4.5)\n'
     '\t\tend\n'
     '\tend\nend\n'),
    ('\t\tdir = (best and best.Magnitude > 0.1) and best.Unit or workspace.CurrentCamera.CFrame.LookVector\n',
     '\t\tif best and best.Magnitude > 0.1 and bestD <= (workspace.Hoop:GetAttribute("HoopRange") or 150) then dir = best.Unit\n'
     '\t\telse\n'
     '\t\t\t-- away from every hoop (Porto): where you are looking - at the spot in the middle of the screen when there is one within reach, else a lob that way (Oct 10)\n'
     '\t\t\tlocal cam = workspace.CurrentCamera\n'
     '\t\t\tdir = cam.CFrame.LookVector\n'
     '\t\t\tif not kind then\n'
     '\t\t\t\tlocal rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude\n'
     '\t\t\t\tlocal skip = {player.Character}\n'
     '\t\t\t\tlocal dl = workspace:FindFirstChild("SlingDraw_local"); if dl then table.insert(skip, dl) end\n'
     '\t\t\t\trp.FilterDescendantsInstances = skip\n'
     '\t\t\t\tlocal hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 120, rp)\n'
     '\t\t\t\tif hit then kind, point = "point", hit.Position end\n'
     '\t\t\tend\n'
     '\t\tend\n'),
    ('UIS.InputEnded:Connect(function(io)                              -- a finger that slid off the button still lets go\n'
     '\tif charging and touchAim and io.UserInputType == Enum.UserInputType.Touch then hold.BackgroundColor3 = C(255, 202, 62); endDraw() end\n'
     'end)\n',
     'UIS.InputEnded:Connect(function(io)                              -- a finger that slid off the button still lets go\n'
     '\tif charging and touchAim and io.UserInputType == Enum.UserInputType.Touch then hold.BackgroundColor3 = C(255, 202, 62); endDraw() end\n'
     'end)\n'
     'UIS.LastInputTypeChanged:Connect(function(t)                     -- a finger arriving later: the phone way from then on (Oct 10)\n'
     '\tif t == Enum.UserInputType.Touch and not touchAim and not charging then\n'
     '\t\ttouchAim = true; tool.ManualActivationOnly = true; hold.Visible = true\n'
     '\t\tif gui.Enabled then helpLine() end\n'
     '\tend\n'
     'end)\n'),
]
BINO = [
    ('local touch = UIS.TouchEnabled and not UIS.MouseEnabled       -- a phone toggles; a mouse holds\n',
     TOUCHNOW +
     'local touch = touchNow()       -- a phone toggles; a mouse holds\n'
     'UIS.LastInputTypeChanged:Connect(function(t)   -- and it follows the last thing used: a finger means toggle, a mouse means hold (Oct 10)\n'
     '\tif t == Enum.UserInputType.Touch then touch = true elseif t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.MouseMovement then touch = touchNow() end\n'
     'end)\n'),
]
PHONE_EXPR = '(function() local ok, pi = pcall(function() return UIS.PreferredInput end); if ok and pi ~= nil then return pi == Enum.PreferredInput.Touch end; return UIS.TouchEnabled and not UIS.MouseEnabled end)()'
DAILY = [('local phone = UIS.TouchEnabled and not UIS.MouseEnabled\n', 'local phone = ' + PHONE_EXPR + '   -- (PreferredInput: MouseEnabled can read true on a touch phone - Oct 10)\n')]
QUEST = [('local PHONE = UIS.TouchEnabled and not UIS.MouseEnabled\n', 'local PHONE = ' + PHONE_EXPR + '   -- (PreferredInput: MouseEnabled can read true on a touch phone - Oct 10)\n')]
TARGETS = [  # (file, Studio path pieces, expected chars, pairs, backup name)
    ("SlingClient.lua", 'game:GetService("ServerStorage"):FindFirstChild("SlingshotTool") and game:GetService("ServerStorage").SlingshotTool:FindFirstChild("SlingClient")', 16373, SLING, "SlingClient_pre_phone1"),
    ("BinocularsClient.lua", 'game:GetService("ServerStorage"):FindFirstChild("BinocularsTool") and game:GetService("ServerStorage").BinocularsTool:FindFirstChild("BinocularsClient")', 7981, BINO, "BinocularsClient_pre_phone1"),
    ("DailyClient.lua", 'workspace:FindFirstChild("Daily") and workspace.Daily:FindFirstChild("DailyClient")', 14785, DAILY, "DailyClient_pre_phone1"),
    ("QuestionClient.lua", 'workspace:FindFirstChild("DailyQuestion") and workspace.DailyQuestion:FindFirstChild("QuestionClient")', 28363, QUEST, "QuestionClient_pre_phone1"),
]
entries = []
for fname, lookup, n, pairs_, bname in TARGETS:
    t = (SRC / fname).read_text(encoding="utf-8")
    assert len(t.encode()) == n, (fname, len(t.encode()))
    for a, b in pairs_: assert t.count(a) == 1, (fname, a[:60]); t = t.replace(a, b)
    (SRC / fname.replace(".lua", "_phone1.lua")).write_text(t, encoding="utf-8")
    entries.append('\t{name = "%s", get = function() return %s end, n = %d, backup = "%s", pairs = {%s}},' % (
        fname.replace(".lua", ""), lookup, n, bname, ", ".join("{%s, %s}" % (L(a), L(b)) for a, b in pairs_)))
    print(fname, n, "->", len(t.encode()))
lua = r'''-- tools_src/phone_tools1 (job 71): EDIT mode. The slingshot and the binoculars on a phone (touch mode by PreferredInput,
-- switching when a finger arrives; the HOLD button at the bottom middle), the acorn goes where you look away from every
-- hoop (Porto) and the note says so; the Daily card and the Daily Question pick their phone layout the same way.
-- Four exact-string patches (the job 70 exports), each compiled before writing; originals ->
-- ServerStorage.HudBackup.<Name>_pre_phone1. workspace.Hoop gets HoopRange 150. Output lines "QQ PHONE".
if game:GetService("RunService"):IsRunning() then warn("QQ PHONE ABORT - Play mode") return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local JOBS = {
@@ENTRIES@@
}
-- everything is checked before anything is written
local plan = {}
for _, j in ipairs(JOBS) do
	local s = j.get()
	if not (s and s:IsA("LuaSourceContainer")) then warn("QQ PHONE ABORT - " .. j.name .. " not found; nothing changed") return end
	if #s.Source ~= j.n then warn(string.format("QQ PHONE ABORT - %s is %d chars, expected %d (not the job 70 export, or already patched); nothing changed", j.name, #s.Source, j.n)) return end
	local o = s.Source
	for i, p in ipairs(j.pairs) do
		local a, b = o:find(p[1], 1, true)
		if not a then warn("QQ PHONE ABORT - " .. j.name .. " find " .. i .. " not found; nothing changed") return end
		if o:find(p[1], b + 1, true) then warn("QQ PHONE ABORT - " .. j.name .. " find " .. i .. " matches more than once; nothing changed") return end
		o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
	end
	local f, err = loadstring(o)
	if not f then warn("QQ PHONE ABORT - patched " .. j.name .. " does not compile: " .. tostring(err) .. "; nothing changed") return end
	table.insert(plan, {script = s, text = o, job = j})
end
local report = {}
for _, p in ipairs(plan) do
	local old = backup:FindFirstChild(p.job.backup); if old then old:Destroy() end
	local c = p.script:Clone(); c.Name = p.job.backup; c.Enabled = false; c.Parent = backup
	p.script.Source = p.text
	table.insert(report, string.format("%s %d -> %d", p.job.name, p.job.n, #p.script.Source))
end
local H = workspace:FindFirstChild("Hoop"); if H then H:SetAttribute("HoopRange", 150) end
game:GetService("ChangeHistoryService"):SetWaypoint("Phone tools patched")
print("QQ PHONE DONE: " .. table.concat(report, "; ") .. "; backups ServerStorage.HudBackup.*_pre_phone1; Hoop.HoopRange 150")
'''
lua = lua.replace("@@ENTRIES@@", "\n".join(entries))
assert "@@" not in lua
(SRC / "phone_tools1.lua").write_text(lua, encoding="utf-8")
print("phone_tools1.lua", len(lua.encode()), "chars")
