#!/usr/bin/env python3
"""Builds tools/film/balloon_tour1.lua (job 49): the "Balloon flight" tour in Shannon's F8 filming menu. Shannon (Oct 9):
"one of those camera tour things of going up in the balloon into the storm ending with coming soon; I want to make a promo
video" - and the /promo chat command would not record with Win+Alt+R, while the F8 tours do. Two exact-string patches:
workspace.FilmMode.Tours gets {id = "balloon", kind = "balloon"} before the drone; workspace.FilmMode.FilmClient gets
runBalloon() and its dispatch. The rider stays in the basket (the flight needs them in the seat), so the character is not
carried; the camera is its own: liftoff from the grass, a slow circle in the climb, a chase through the gust, close in the
storm and the sign. BalloonGui (the words, the sign, the fade) stays on; the rest of the UI is hidden as in every tour.
Backups FilmClient_pre_balloon1 / Tours_pre_balloon1 in ServerStorage.HudBackup. Run from the repo root.
"""
import pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]
def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"
fc = (ROOT / "tools/film/src/FilmClient.lua").read_text(encoding="utf-8")
tr = (ROOT / "tools/film/src/Tours.lua").read_text(encoding="utf-8")
NF, NT = len(fc.encode()), len(tr.encode())
assert (NF, NT) == (19539, 3266), (NF, NT)   # what Studio has (the runner's export, Oct 9)
T1 = '\t{id = "drone", name = "Drone camera", kind = "drone", fov = 72},\n'
T1R = '\t{id = "balloon", name = "Balloon flight", kind = "balloon", fov = 72},   -- climb aboard after pressing it; filmed from liftoff to landing (Oct 9)\n' + T1
F1 = '-- ---------- the menu (F8) ----------\n'
F1R = r'''-- ---------- the balloon flight (Oct 9): press it, climb aboard, and the flight is filmed from liftoff to landing ----------
-- Shannon: "one of those camera tour things of going up in the balloon into the storm ending with coming soon". The rider
-- stays in the basket (the flight needs them in the seat), so the character is not carried; the camera is its own: liftoff
-- from the grass, a slow circle in the climb with the town behind, a chase through the gust, close in the storm, the sign.
-- BalloonGui (the words, the sign, the fade to black) stays on; everything else is hidden as in every tour. F8 stops the
-- filming; the flight goes on. The camera is set after BalloonClient's smoothing (render priority Camera + 1).
local function runBalloon(tour)
	if running then return end
	local BF = workspace:FindFirstChild("BalloonField")
	local yours = BF and BF:FindFirstChild("YourBalloon")
	local seat = yours and yours:FindFirstChild("FlightSeat", true)
	if not (yours and seat) then return end
	running, stopFlag = tour.id, false
	closeMenu()
	local function bn(name, d) local v = BF:GetAttribute(name) return typeof(v) == "number" and v or d end
	local function bv(name, d) local v = BF:GetAttribute(name) return typeof(v) == "Vector3" and v or d end
	local function seated() local c = player.Character; local h = c and c:FindFirstChildOfClass("Humanoid") return h ~= nil and h.SeatPart == seat end
	-- first the rider climbs aboard (the prompt needs the UI, so nothing is hidden yet)
	local waitGui = Instance.new("ScreenGui"); waitGui.Name = "FilmWait"; waitGui.ResetOnSpawn = false; waitGui.DisplayOrder = 61
	local w = Instance.new("TextLabel"); w.AnchorPoint = Vector2.new(0.5, 1); w.Position = UDim2.new(0.5, 0, 1, -40); w.Size = UDim2.fromOffset(460, 40)
	w.BackgroundColor3 = C(34, 26, 46); w.BackgroundTransparency = 0.15; w.FontFace = FONT; w.TextSize = 16; w.TextColor3 = C(255, 246, 220); w.TextWrapped = true
	w.Text = "Balloon flight: climb aboard (All aboard) - filming starts as it lifts off.  F8 cancels."; w.Parent = waitGui
	local wc = Instance.new("UICorner"); wc.CornerRadius = UDim.new(0, 10); wc.Parent = w
	waitGui.Parent = pg
	local t0 = os.clock()
	while not stopFlag and not seated() do
		if os.clock() - t0 > 240 then stopFlag = true end
		task.wait(0.1)
	end
	waitGui:Destroy()
	if stopFlag then running, stopFlag = nil, false return end
	local wasUI = uiHidden
	setUIHidden(true)
	local bg = pg:FindFirstChild("BalloonGui"); if bg then bg.Enabled = true end   -- her words, the sign and the fade are part of the film
	local dir = bv("GustDir", Vector3.new(0.45, 0, -1)); dir = Vector3.new(dir.X, 0, dir.Z).Unit
	local side = dir:Cross(Vector3.yAxis)
	local home = yours:GetPivot().Position
	local grass = home - dir * 12 - side * 22   -- the liftoff camera stands on the field, inland of the pad
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {BF, player.Character}
	local hit = workspace:Raycast(grass + Vector3.new(0, 30, 0), Vector3.new(0, -60, 0), rp)
	grass = Vector3.new(grass.X, (hit and hit.Position.Y or home.Y) + 2.5, grass.Z)
	local T = {rise = bn("RiseTime", 16), hover = bn("HoverTime", 8), gust = bn("GustTime", 18)}
	local lift, pos, lookS, lastShot, unseatAt = nil, nil, nil, nil, nil
	RunService:BindToRenderStep("FilmBalloon", Enum.RenderPriority.Camera.Value + 1, function(dt)
		if not yours.Parent then stopFlag = true return end
		local b = yours:GetPivot().Position
		if not lift and b.Y - home.Y > 0.3 then lift = os.clock() end
		local t = lift and (os.clock() - lift) or 0
		local L = b + Vector3.new(0, 6, 0)   -- the basket and the balloon above it
		local shot, want, look
		if t < 7 then shot = 1; want = grass; look = L   -- liftoff, from the grass
		elseif t < T.rise + T.hover then shot = 2; local a = math.pi + (t - 7) * 0.13; want = L + Vector3.new(math.cos(a) * 36, -2, math.sin(a) * 36); look = L   -- a slow circle, the town behind
		elseif t < T.rise + T.hover + T.gust then shot = 3; want = L - dir * 42 + side * 10 + Vector3.new(0, 10, 0); look = L + dir * 12   -- the chase out to sea
		else shot = 4; local a = (t - T.rise - T.hover - T.gust) * 0.08; want = L + (dir * math.cos(a) + side * math.sin(a)) * 18 + Vector3.new(0, 3, 0); look = L end   -- close, in the storm; the sign comes up on the screen
		if shot ~= lastShot or not pos then pos = want; lookS = look; lastShot = shot
		else pos = pos:Lerp(want, 1 - math.exp(-dt * (shot == 3 and 1.6 or 4))); lookS = lookS:Lerp(look, 1 - math.exp(-dt * 8)) end
		local cam = camera(); cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = CFrame.lookAt(pos, lookS); cam.FieldOfView = tour.fov
	end)
	while not stopFlag do
		task.wait(0.1)
		if seated() then unseatAt = nil
		else unseatAt = unseatAt or os.clock(); if os.clock() - unseatAt > 2.2 then break end end   -- set down (or out of the seat): a moment under the black, then back to normal
	end
	RunService:UnbindFromRenderStep("FilmBalloon")
	finish(wasUI)
end

-- ---------- the menu (F8) ----------
'''
F2 = '\t\t\telseif tour.kind == "drone" then runDrone(tour)\n'
F2R = F2 + '\t\t\telseif tour.kind == "balloon" then runBalloon(tour)\n'
for a in (T1,): assert tr.count(a) == 1
for a in (F1, F2): assert fc.count(a) == 1
lua = r'''-- film/balloon_tour1 (job 49): EDIT mode. "Balloon flight" in the F8 filming menu (Shannon's promo video; /promo would not
-- record). Two exact finds in workspace.FilmMode.FilmClient (@@NF@@ chars) and one in workspace.FilmMode.Tours (@@NT@@ chars);
-- both compiled before writing; originals -> ServerStorage.HudBackup.FilmClient_pre_balloon1 / Tours_pre_balloon1. Output "QQ FILM".
if game:GetService("RunService"):IsRunning() then warn("QQ FILM ABORT - Play mode") return end
local FM = workspace:FindFirstChild("FilmMode")
local fc = FM and FM:FindFirstChild("FilmClient")
local tr = FM and FM:FindFirstChild("Tours")
if not (fc and tr) then warn("QQ FILM ABORT - workspace.FilmMode.FilmClient / Tours missing") return end
if #fc.Source ~= @@NF@@ then warn(string.format("QQ FILM ABORT - FilmClient is %d chars, expected @@NF@@ (already patched, or changed); nothing changed", #fc.Source)) return end
if #tr.Source ~= @@NT@@ then warn(string.format("QQ FILM ABORT - Tours is %d chars, expected @@NT@@ (already patched, or changed); nothing changed", #tr.Source)) return end
local function patch(src, pairs_, what)
	for i, p in ipairs(pairs_) do
		local a, b = src:find(p[1], 1, true)
		if not a then warn("QQ FILM ABORT - " .. what .. " find " .. i .. " not found; nothing changed") return nil end
		if src:find(p[1], b + 1, true) then warn("QQ FILM ABORT - " .. what .. " find " .. i .. " matches more than once; nothing changed") return nil end
		src = src:sub(1, a - 1) .. p[2] .. src:sub(b + 1)
	end
	local f, err = loadstring(src)
	if not f then warn("QQ FILM ABORT - patched " .. what .. " does not compile: " .. tostring(err)) return nil end
	return src
end
local newT = patch(tr.Source, {{@@T1@@, @@T1R@@}}, "Tours"); if not newT then return end
local newF = patch(fc.Source, {{@@F1@@, @@F1R@@}, {@@F2@@, @@F2R@@}}, "FilmClient"); if not newF then return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c1 = fc:Clone(); c1.Name = "FilmClient_pre_balloon1"; c1.Enabled = false; c1.Parent = backup
local c2 = tr:Clone(); c2.Name = "Tours_pre_balloon1"; c2.Parent = backup
tr.Source = newT; fc.Source = newF
print(string.format("QQ FILM DONE: Tours %d -> %d chars, FilmClient %d -> %d chars; backups ServerStorage.HudBackup.FilmClient_pre_balloon1 / Tours_pre_balloon1", @@NT@@, #tr.Source, @@NF@@, #fc.Source))
'''
for k, v in {"NF": str(NF), "NT": str(NT), "T1": L(T1), "T1R": L(T1R), "F1": L(F1), "F1R": L(F1R), "F2": L(F2), "F2R": L(F2R)}.items(): lua = lua.replace("@@" + k + "@@", v)
assert "@@" not in lua
(ROOT / "tools/film/balloon_tour1.lua").write_text(lua, encoding="utf-8")
# the patched sources, for reading and compile checks (Studio stays the master)
(ROOT / "tools/film/src/FilmClient_balloon1.lua").write_text(fc.replace(F1, F1R).replace(F2, F2R), encoding="utf-8")
(ROOT / "tools/film/src/Tours_balloon1.lua").write_text(tr.replace(T1, T1R), encoding="utf-8")
print("balloon_tour1.lua", len(lua.encode()), "chars; FilmClient", NF, "Tours", NT)
