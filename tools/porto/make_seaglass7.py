#!/usr/bin/env python3
"""Builds tools/porto/seaglass7.lua (job 50): Bella's panel was cut off at the right edge on Shannon's phone ("its too far
right getting cut off", screenshot Oct 9). The panel carried the phone UIScale itself, so its real on-screen size and the
anchoring did not agree. Now the panel's face (title, X, finds, recipe rows) lives in an inner frame that carries the scale,
and the panel keeps a plain pixel size (the scaled size), anchored at the right; a frame later it is nudged left if its
right edge is still past the screen. One exact find (the layout function after job 48) in workspace.SeaGlass.SeaGlassClient;
original -> ServerStorage.HudBackup.SeaGlassClient_pre_seaglass7. Run from the repo root: python3 tools/porto/make_seaglass7.py
"""
import pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]
def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"
F1 = '''local function layout()
	local v = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local h = ROW_Y + #R.recipes * ROW_H + 24
	local sc = panel:FindFirstChild("PhoneScale") or Instance.new("UIScale"); sc.Name = "PhoneScale"; sc.Parent = panel
	local s = math.clamp((v.Y - 130) / h, 0.6, 1); sc.Scale = s -- a phone keeps the top HUD bar and the jump button clear
	panel.Size = UDim2.fromOffset(math.min(380, (v.X - 24) / s), math.min(h, (v.Y - 16) / s))
	panel.Position = UDim2.new(1, phone() and -4 or -14, 0.5, 0)   -- a phone: hard against the right edge (Oct 9)
end
'''
R1 = '''-- the panel's face scales as one piece inside it; the panel itself keeps a plain pixel size, so its right edge is where it
-- is anchored (with the scale on the panel a phone cut it off at the right - Shannon, Oct 9)
local inner = Instance.new("Frame"); inner.Name = "Inner"; inner.BackgroundTransparency = 1; inner.ZIndex = 8; inner.Parent = panel
for _, c in ipairs(panel:GetChildren()) do if c ~= inner and c:IsA("GuiObject") then c.Parent = inner end end
local function layout()
	local v = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local h = ROW_Y + #R.recipes * ROW_H + 24
	local sc = inner:FindFirstChild("PhoneScale") or Instance.new("UIScale"); sc.Name = "PhoneScale"; sc.Parent = inner
	local s = math.clamp((v.Y - 130) / h, 0.6, 1); sc.Scale = s -- a phone keeps the top HUD bar and the jump button clear
	local w, hh = math.min(380, (v.X - 24) / s), math.min(h, (v.Y - 16) / s)
	inner.Size = UDim2.fromOffset(w, hh)
	panel.Size = UDim2.fromOffset(w * s, hh * s)
	panel.Position = UDim2.new(1, phone() and -4 or -14, 0.5, 0)   -- a phone: hard against the right edge (Oct 9)
	task.defer(function()   -- and never past it, whatever the screen does
		local over = panel.AbsolutePosition.X + panel.AbsoluteSize.X - (v.X - 2)
		if over > 0 then panel.Position = panel.Position - UDim2.fromOffset(over, 0) end
	end)
end
'''
N = 15059   # Studio after job 48 (the runner's count)
src = ROOT / "tools/porto/src/SeaGlassClient.lua"; t = src.read_text(encoding="utf-8")
if F1 in t: assert t.count(F1) == 1; t = t.replace(F1, R1); src.write_text(t, encoding="utf-8")
else: assert R1 in t
lua = r'''-- porto/seaglass7 (job 50): EDIT mode. Bella's panel stays inside the screen on a phone (it was cut off at the right).
-- One exact find in workspace.SeaGlass.SeaGlassClient (after job 48, about @@N@@ chars); compiled before writing;
-- original -> ServerStorage.HudBackup.SeaGlassClient_pre_seaglass7. Output "QQ SG7".
if game:GetService("RunService"):IsRunning() then warn("QQ SG7 ABORT - Play mode") return end
local G = workspace:FindFirstChild("SeaGlass")
local s = G and G:FindFirstChild("SeaGlassClient")
if not s then warn("QQ SG7 ABORT - missing workspace.SeaGlass.SeaGlassClient") return end
if math.abs(#s.Source - @@N@@) > 60 then warn(string.format("QQ SG7 ABORT - SeaGlassClient is %d chars, expected about @@N@@ (job 48 not run yet, or changed); nothing changed", #s.Source)) return end
local o = s.Source
local before = #o
local a, b = o:find(@@F1@@, 1, true)
if not a then warn("QQ SG7 ABORT - the layout function was not found as expected (already patched?); nothing changed. Source is " .. before .. " chars") return end
if o:find(@@F1@@, b + 1, true) then warn("QQ SG7 ABORT - the find matches more than once; nothing changed") return end
o = o:sub(1, a - 1) .. @@R1@@ .. o:sub(b + 1)
local f, err = loadstring(o)
if not f then warn("QQ SG7 ABORT - patched source does not compile: " .. tostring(err)) return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "SeaGlassClient_pre_seaglass7"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ SG7 DONE: SeaGlassClient %d -> %d chars; backup ServerStorage.HudBackup.SeaGlassClient_pre_seaglass7", before, #s.Source))
'''
for k, v in {"N": str(N), "F1": L(F1), "R1": L(R1)}.items(): lua = lua.replace("@@" + k + "@@", v)
assert "@@" not in lua
(ROOT / "tools/porto/seaglass7.lua").write_text(lua, encoding="utf-8")
print("seaglass7.lua", len(lua.encode()), "chars; expects SeaGlassClient about", N, "-> src now", len(t.encode()))
