#!/usr/bin/env python3
"""Builds tools/porto/seaglass9.lua (job 52, replaces job 51): Shannon's phone feedback on Bella's game after jobs 48/50:
the panel's right edge had "zero space" (and Studio still builds the panel centre-anchored, so Position (1, -4) hung half
of it off until job 50's clamp pulled it back): the layout now anchors it by its right edge, 14 px in. Her speech bubble
sat too low: its anchor is a third of the way down the screen. The reveal "behind her character, low and small": on a
phone it also comes up big on the screen, on top of everything, spinning in a little window for five seconds, then fades
(a ViewportFrame; the world reveal and its sound stay). Three exact finds in workspace.SeaGlass.SeaGlassClient after job 50
(about 15822 chars); original -> ServerStorage.HudBackup.SeaGlassClient_pre_seaglass9. Run from the repo root.
"""
import pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]
def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"
F1 = '\tpanel.Position = UDim2.new(1, phone() and -4 or -14, 0.5, 0)   -- a phone: hard against the right edge (Oct 9)\n'
R1 = ('\tpanel.AnchorPoint = Vector2.new(1, 0.5)   -- anchored by its right edge (the construction line still said the centre; half of it hung off a phone - Oct 9)\n'
      '\tpanel.Position = UDim2.new(1, -14, 0.5, 0)   -- 14 px off the right edge on every screen (Shannon\'s phone: "zero space")\n')
F1_SRC8 = '\tpanel.AnchorPoint = Vector2.new(1, 0.5)   -- anchored by its right edge (the construction line still said the centre; half of it hung off a phone - Oct 9)\n' + F1   # the repo src after make_seaglass8
F2 = '\t\t\t\tlocal ray = c:ScreenPointToRay(v.X * 0.17, v.Y * 0.5)   -- the bubble\'s middle: a sixth of the way in, mid-height\n'
R2 = '\t\t\t\tlocal ray = c:ScreenPointToRay(v.X * 0.17, v.Y * 0.3)   -- the bubble\'s middle: a sixth of the way in, a third of the way down (it sat too low at half - Shannon)\n'
F3 = 'local Debris = game:GetService("Debris")\nlocal function reveal(id)\n\tlocal ok, m = pcall(R.build, id)\n\tif not ok or not m then return end\n'
R3 = r'''local Debris = game:GetService("Debris")
-- a phone: the reveal also comes up big on the screen, on top of everything, spinning in a little window, then fades
-- (Shannon: "behind her character, low and small"; "on top of everything ... big and prominent for a moment")
local function screenReveal(src)
	local v = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local size = math.floor(math.min(v.Y * 0.64, v.X * 0.42))
	local vp = Instance.new("ViewportFrame"); vp.Name = "Reveal"; vp.AnchorPoint = Vector2.new(0.5, 0.5); vp.Position = UDim2.fromScale(0.5, 0.5); vp.Size = UDim2.fromOffset(size * 0.6, size * 0.6)
	vp.BackgroundColor3 = BROWN; vp.BackgroundTransparency = 1; vp.ImageTransparency = 1; vp.ZIndex = 30
	vp.Ambient = Color3.fromRGB(190, 180, 160); vp.LightColor = Color3.fromRGB(255, 240, 210); vp.LightDirection = Vector3.new(-0.6, -1, -0.4)
	corner(vp, 18); local st = stroke(vp, GOLD, 3)
	local cam = Instance.new("Camera"); cam.FieldOfView = 40; cam.Parent = vp; vp.CurrentCamera = cam
	src.Parent = vp
	local cf, sz = src:GetBoundingBox()
	local centre, d = cf.Position, math.max(sz.X, sz.Y, sz.Z, 0.5) * 0.5 / math.tan(math.rad(20)) * 1.3
	cam.CFrame = CFrame.lookAt(centre + Vector3.new(0, d * 0.35, d), centre)
	vp.Parent = gui
	TweenService:Create(vp, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(size, size)}):Play()
	TweenService:Create(vp, TweenInfo.new(0.3), {ImageTransparency = 0, BackgroundTransparency = 0.3}):Play()
	local t0, LIFE = os.clock(), 5.0
	local conn; conn = game:GetService("RunService").RenderStepped:Connect(function()
		local t = os.clock() - t0
		if t > LIFE or not vp.Parent then conn:Disconnect(); return end
		local a = t * 1.4
		cam.CFrame = CFrame.lookAt(centre + Vector3.new(math.sin(a) * d, d * 0.35, math.cos(a) * d), centre)
	end)
	task.delay(LIFE - 0.9, function()
		if not vp.Parent then return end
		TweenService:Create(vp, TweenInfo.new(0.9), {ImageTransparency = 1, BackgroundTransparency = 1}):Play()
		TweenService:Create(st, TweenInfo.new(0.9), {Transparency = 1}):Play()
	end)
	Debris:AddItem(vp, LIFE + 0.1)
end
local function reveal(id)
	local ok, m = pcall(R.build, id)
	if not ok or not m then return end
	if phone() then pcall(screenReveal, m:Clone()) end   -- a phone: big and on top; the world one below carries on (and its sound)
'''
PAIRS = [(F1, R1), (F2, R2), (F3, R3)]
N = 15822   # Studio after job 50 (the runner's count)
src = ROOT / "tools/porto/src/SeaGlassClient.lua"; t = src.read_text(encoding="utf-8")
if F1_SRC8 in t: t = t.replace(F1_SRC8, F1)   # back to the job 50 form first (make_seaglass8 had added the anchor line)
if "screenReveal" not in t:
    for a, b in PAIRS: assert t.count(a) == 1, a[:60]; t = t.replace(a, b)
    src.write_text(t, encoding="utf-8")
lua = r'''-- porto/seaglass9 (job 52, in place of job 51): EDIT mode. Bella's game on a phone, round two: the panel anchored by its
-- right edge 14 px in, her words a third of the way down the screen, the reveal big on the screen on top of everything
-- (a spinning window for five seconds, then it fades). Three exact finds in workspace.SeaGlass.SeaGlassClient (after job 50,
-- about @@N@@ chars); compiled before writing; original -> ServerStorage.HudBackup.SeaGlassClient_pre_seaglass9. Output "QQ SG9".
if game:GetService("RunService"):IsRunning() then warn("QQ SG9 ABORT - Play mode") return end
local G = workspace:FindFirstChild("SeaGlass")
local s = G and G:FindFirstChild("SeaGlassClient")
if not s then warn("QQ SG9 ABORT - missing workspace.SeaGlass.SeaGlassClient") return end
if math.abs(#s.Source - @@N@@) > 60 then warn(string.format("QQ SG9 ABORT - SeaGlassClient is %d chars, expected about @@N@@ (job 50 not run, job 51 run, or changed); nothing changed", #s.Source)) return end
local o = s.Source
local before = #o
for i, p in ipairs({{@@F1@@, @@R1@@}, {@@F2@@, @@R2@@}, {@@F3@@, @@R3@@}}) do
	local a, b = o:find(p[1], 1, true)
	if not a then warn("QQ SG9 ABORT - find " .. i .. " not found (already patched?); nothing changed. Source is " .. before .. " chars") return end
	if o:find(p[1], b + 1, true) then warn("QQ SG9 ABORT - find " .. i .. " matches more than once; nothing changed") return end
	o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
end
local f, err = loadstring(o)
if not f then warn("QQ SG9 ABORT - patched source does not compile: " .. tostring(err)) return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "SeaGlassClient_pre_seaglass9"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ SG9 DONE: SeaGlassClient %d -> %d chars; backup ServerStorage.HudBackup.SeaGlassClient_pre_seaglass9", before, #s.Source))
'''
rep = {"N": str(N)}
for i, (a, b) in enumerate(PAIRS, 1): rep["F%d" % i] = L(a); rep["R%d" % i] = L(b)
for k, v in rep.items(): lua = lua.replace("@@" + k + "@@", v)
assert "@@" not in lua
(ROOT / "tools/porto/seaglass9.lua").write_text(lua, encoding="utf-8")
print("seaglass9.lua", len(lua.encode()), "chars; expects SeaGlassClient about", N, "-> src now", len(t.encode()))
