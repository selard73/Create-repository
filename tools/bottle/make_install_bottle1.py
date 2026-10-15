#!/usr/bin/env python3
"""Builds tools/bottle/install_bottle1.lua (job 118): the MESSAGE IN A BOTTLE game on the Porto beach. Shannon: Oct 6 (fill-in-the-blank
notes sent TO someone at sea; next day a reply that answers what you picked; random silly bottles wash up too) and Oct 15 ("preset
better with the choose fill in the blank"; acorns: finds pay, "I thought we were charging acorns to send"; "build it as soon as we can").
The installer (Studio EDIT; re-runnable; the old folder to HudBackup):
 1. scans the main Porto beach (x 215..340, z -690..-800) with rays: open sand (the first thing hit is terrain Sand/Ground, no part),
    water points, and each sand point's distance to the nearest water;
 2. the STAND goes on open sand 10..18 studs from the water, nothing within 7 studs, level within 1.5, the candidate nearest the
    harbour spawn; its back to the sea (seaward = towards the nearest water);
 3. WASH SPOTS: open sand within 5 studs of the water, at least 12 apart, up to 10; the reply spot = the wash spot nearest the stand;
 4. builds workspace.Bottles {BottleEvent, BottleText (module), BottleServer, BottleClient (RunContext Client), Stand (Model,
    Persistent: counter, posts, striped awning, crate of bottles, the sign MESSAGGI IN BOTTIGLIA / Messages in a Bottle, WritePrompt)}
    + ReplicatedStorage.BottleTemplate (glass, neck, cork, a rolled note, the Uncork prompt);
 5. attributes: SendCost 15, FindPrize 10, FindCap 5, MaxBeach 3, RespawnSeconds 75, TestDayOffset 0 (Studio only), WashSpots, ReplySpot.
Its body runs as a play-test PREVIEW too (discarded on stop). Run from the repo root."""
import pathlib
HERE = pathlib.Path(__file__).resolve().parent
SRC = {n: (HERE / "src" / (n + ".lua")).read_text(encoding="utf-8") for n in ("BottleText", "BottleServer", "BottleClient")}
# round 3: Shannon's spot for the kiosk ("on the landing behind the police officer next to the boat club"), read by runner 7 from her
# character in Studio Play: x, z, and yaw = the way she faced (the kiosk's front - counter, sign, prompt - faces that way). None = the
# round-2 automatic choice on the beach.
STAND = {"x": 473.3, "z": -970.9, "yaw": 98.6}   # runner 7, Oct 15: her root (473.34, -8.77, -970.93) on the Via della Piazza paving (top -12.0) by the Circolo Velico; her look yaw 98.2, the police squirrel's 99.1
for s in SRC.values(): assert "]===]" not in s
lua = r'''-- install_bottle1.lua (Studio EDIT; re-runnable; its body also runs as a play-test PREVIEW - discarded on stop). Job 118: the MESSAGE IN
-- A BOTTLE game on the main Porto beach. Scans the beach for open sand and the waterline, puts the stand 10..18 studs from the water
-- (its back to the sea), picks up to 10 wash-up spots, builds workspace.Bottles + ReplicatedStorage.BottleTemplate. Sources: BottleText
-- (@@L1@@), BottleServer (@@L2@@), BottleClient (@@L3@@) chars. No DataStore of ours (the save is touched only through RS.AwardItems /
-- AwardAcorns), no publish. Output "QQ BOTTLE".
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local T = workspace.Terrain
local SRC = {BottleText = [===[
@@BottleText@@]===], BottleServer = [===[
@@BottleServer@@]===], BottleClient = [===[
@@BottleClient@@]===]}
for n, s in pairs(SRC) do
	local ok, f, err = pcall(function() return loadstring(s) end)
	if ok and not f then print("QQ BOTTLE ABORT: " .. n .. " does not compile: " .. tostring(err)) return end
end
if not (RS:FindFirstChild("AwardItems") and RS:FindFirstChild("AwardAcorns")) then print("QQ BOTTLE ABORT: ReplicatedStorage.AwardItems / AwardAcorns missing") return end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before Bottles") end)
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local old = workspace:FindFirstChild("Bottles")                          -- (round 2: kept in place until the scan has passed; an ABORT leaves it working)
-- ---------- 1: the beach scan ----------
local X1, X2, Z1, Z2, STEP = 215, 340, -800, -690, 4
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.IgnoreWater = false
local skip = {}
for _, pl in ipairs(game:GetService("Players"):GetPlayers()) do if pl.Character then table.insert(skip, pl.Character) end end
if old then table.insert(skip, old) end                                     -- (a re-run: the old stand never blocks its own site)
rp.FilterDescendantsInstances = skip
local sand, water = {}, {}
for x = X1, X2, STEP do
	for z = Z1, Z2, STEP do
		local h = workspace:Raycast(Vector3.new(x, 120, z), Vector3.new(0, -260, 0), rp)
		if h and h.Instance == T then
			if h.Material == Enum.Material.Water then table.insert(water, Vector3.new(x, h.Position.Y, z))
			elseif h.Material == Enum.Material.Sand or h.Material == Enum.Material.Ground then table.insert(sand, h.Position) end
		end
	end
end
print(string.format("QQ BOTTLE scan: x %d..%d z %d..%d step %d - %d open sand points, %d water points", X1, X2, Z1, Z2, STEP, #sand, #water))
if #sand < 6 or #water < 6 then print("QQ BOTTLE ABORT: too little open sand or water in the scan box - tell the cloud thread (the beach may sit elsewhere)") return end
local function nearestWater(p)
	local best, bp = math.huge, nil
	for _, w in ipairs(water) do local d = (Vector3.new(w.X, 0, w.Z) - Vector3.new(p.X, 0, p.Z)).Magnitude; if d < best then best, bp = d, w end end
	return best, bp
end
local hByXZ = {}
for _, s in ipairs(sand) do hByXZ[math.floor(s.X + 0.5) .. "," .. math.floor(s.Z + 0.5)] = s.Y end
local function level(s)
	for _, o in ipairs({{STEP, 0}, {-STEP, 0}, {0, STEP}, {0, -STEP}}) do
		local y = hByXZ[math.floor(s.X + o[1] + 0.5) .. "," .. math.floor(s.Z + o[2] + 0.5)]
		if not y or math.abs(y - s.Y) > 1.5 then return false end
	end
	return true
end
local op = OverlapParams.new(); op.FilterType = Enum.RaycastFilterType.Exclude; op.FilterDescendantsInstances = {T, table.unpack(skip)}
local function clear(s, r)
	for _, pt in ipairs(workspace:GetPartBoundsInRadius(s + Vector3.new(0, 3, 0), r, op)) do
		if pt.Transparency < 1 or pt.CanCollide then return false, pt end
	end
	return true
end
-- ---------- 2: the stand ----------
local SPAWN = Vector3.new(232, -47, -580)
local site, siteWater, standCF
local FIXED = @@STAND@@
if FIXED then
	local h = workspace:Raycast(Vector3.new(FIXED.x, 120, FIXED.z), Vector3.new(0, -260, 0), rp)
	if not h then print("QQ BOTTLE ABORT: nothing under the chosen kiosk spot - tell the cloud thread") return end
	site = h.Position
	local d, wp = nearestWater(site); siteWater = wp
	standCF = CFrame.new(site) * CFrame.Angles(0, math.rad(FIXED.yaw), 0)          -- its front (LookVector) faces the way she faced
	local ok, by = clear(site, 4)
	print(string.format("QQ BOTTLE stand (her spot): (%.1f, %.1f, %.1f) on %s, facing yaw %.0f; %s; nearest water %.0f studs", site.X, site.Y, site.Z,
		h.Instance == T and ("terrain " .. h.Material.Name) or h.Instance:GetFullName(), FIXED.yaw, ok and "4 studs clear" or ("NOT clear: " .. by:GetFullName()), d))
end
local cands = {}
for _, s in ipairs(sand) do
	local d, wp = nearestWater(s)
	if d >= 10 and d <= 18 and level(s) then table.insert(cands, {s = s, w = wp, k = (s - SPAWN).Magnitude}) end
end
table.sort(cands, function(a, b) return a.k < b.k end)
local blocked = 0
for _, c in ipairs(FIXED and {} or cands) do
	local ok = clear(c.s, 7)
	if ok then site, siteWater = c.s, c.w break end
	blocked += 1
end
if not site and not FIXED then print(string.format("QQ BOTTLE ABORT: no open level sand 10..18 studs from the water with 7 clear studs (%d candidates, %d blocked) - tell the cloud thread", #cands, blocked)) return end
if not FIXED then
local seaward = Vector3.new(siteWater.X - site.X, 0, siteWater.Z - site.Z).Unit
standCF = CFrame.lookAt(site, site - seaward)                            -- its front (LookVector) faces inland, its back the sea
print(string.format("QQ BOTTLE stand: (%.1f, %.1f, %.1f), %.0f studs from the water, back to the sea toward (%.2f, %.2f); %d candidates, %d blocked before it",
	site.X, site.Y, site.Z, (Vector3.new(siteWater.X, 0, siteWater.Z) - Vector3.new(site.X, 0, site.Z)).Magnitude, seaward.X, seaward.Z, #cands, blocked))
end
-- ---------- 3: the wash spots ----------
local spots = {}
local shore = {}
for _, s in ipairs(sand) do local d = nearestWater(s); if d <= 5 and clear(s, 2.5) then table.insert(shore, s) end end
table.sort(shore, function(a, b) return (a - site).Magnitude < (b - site).Magnitude end)
for _, s in ipairs(shore) do
	local far = true
	for _, o in ipairs(spots) do if (Vector3.new(o[1], 0, o[3]) - Vector3.new(s.X, 0, s.Z)).Magnitude < 12 then far = false break end end
	if far then table.insert(spots, {math.floor(s.X * 10 + 0.5) / 10, math.floor(s.Y * 100 + 0.5) / 100, math.floor(s.Z * 10 + 0.5) / 10}) end
	if #spots >= 10 then break end
end
if #spots == 0 then print("QQ BOTTLE ABORT: no wash-up spots at the waterline - tell the cloud thread") return end
local list = {}
for i, s in ipairs(spots) do table.insert(list, string.format("%d (%.0f, %.1f, %.0f)", i, s[1], s[2], s[3])) end
if #spots < 2 then print("QQ BOTTLE ABORT: only one waterline spot - tell the cloud thread") return end
local replySpot
if (Vector3.new(spots[1][1], 0, spots[1][3]) - Vector3.new(site.X, 0, site.Z)).Magnitude <= 30 then
	replySpot = table.remove(spots, 1)                                     -- (round 2: the reply spot is never a wash spot - no beach bottle inside the reply bottle)
else                                                                       -- (round 3: the kiosk is up on the landing - the reply lies at its foot)
	local f = (standCF * CFrame.new(2.5, 0, -4.5)).Position
	local h = workspace:Raycast(f + Vector3.new(0, 20, 0), Vector3.new(0, -60, 0), rp)
	replySpot = {math.floor(f.X * 10 + 0.5) / 10, math.floor(((h and h.Position.Y) or site.Y) * 100 + 0.5) / 100, math.floor(f.Z * 10 + 0.5) / 10}
	print(string.format("QQ BOTTLE the reply spot: in front of the kiosk at (%.0f, %.1f, %.0f) - the waterline is more than 30 studs away", replySpot[1], replySpot[2], replySpot[3]))
end
print("QQ BOTTLE spots: " .. table.concat(list, " | ") .. "; no. 1, nearest the stand, is the REPLY spot, the other " .. #spots .. " are wash spots")
-- every check passed: now the old install goes
if old then local n = 1; while hb:FindFirstChild("Bottles_pre_" .. n) do n += 1 end; old.Name = "Bottles_pre_" .. n; old.Parent = hb; for _, s in ipairs(old:GetDescendants()) do if s:IsA("BaseScript") then s.Enabled = false end end end
local oldT = RS:FindFirstChild("BottleTemplate"); if oldT then oldT:Destroy() end
-- ---------- 4: the template ----------
local function part(parent, name, size, color, cf, mat, shape, transp)
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.Color = color; p.Material = mat or Enum.Material.SmoothPlastic
	if shape then p.Shape = shape end
	p.Transparency = transp or 0; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth; p.CFrame = cf; p.Parent = parent
	return p
end
local C = Color3.fromRGB
local tpl = Instance.new("Model"); tpl.Name = "BottleTemplate"
local glass = part(tpl, "Glass", Vector3.new(1.6, 0.72, 0.72), C(150, 205, 175), CFrame.new(), Enum.Material.Glass, Enum.PartType.Cylinder, 0.35)
glass.Reflectance = 0.2; glass.CanQuery = true
part(tpl, "Neck", Vector3.new(0.5, 0.36, 0.36), C(150, 205, 175), CFrame.new(1.0, 0, 0), Enum.Material.Glass, Enum.PartType.Cylinder, 0.35)
part(tpl, "Cork", Vector3.new(0.32, 0.3, 0.3), C(176, 132, 84), CFrame.new(1.38, 0, 0), Enum.Material.Wood, Enum.PartType.Cylinder)
part(tpl, "Note", Vector3.new(1.0, 0.3, 0.3), C(250, 240, 210), CFrame.new(-0.05, 0, 0), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
part(tpl, "Ribbon", Vector3.new(0.08, 0.32, 0.32), C(200, 60, 60), CFrame.new(-0.05, 0, 0), Enum.Material.Fabric, Enum.PartType.Cylinder)
tpl.PrimaryPart = glass
local pr = Instance.new("ProximityPrompt"); pr.Name = "UncorkPrompt"; pr.ActionText = "Uncork"; pr.ObjectText = "Message in a bottle"
pr.MaxActivationDistance = 12; pr.RequiresLineOfSight = false; pr.HoldDuration = 0; pr.Parent = glass
local sp = Instance.new("Sparkles"); sp.SparkleColor = C(255, 240, 180); sp.TimeScale = 0.6; sp.Parent = glass
tpl.Parent = RS
-- ---------- 5: the folder, the stand, the scripts ----------
local Fd = Instance.new("Folder"); Fd.Name = "Bottles"
for k, v in pairs({SendCost = 15, FindPrize = 10, FindCap = 5, MaxBeach = 1, RespawnSeconds = 90, TestDayOffset = 0}) do Fd:SetAttribute(k, v) end   -- (round 3: ONE silly bottle at a time)
Fd:SetAttribute("WashSpots", HttpService:JSONEncode(spots))
Fd:SetAttribute("ReplySpot", HttpService:JSONEncode(replySpot))
local evt = Instance.new("RemoteEvent"); evt.Name = "BottleEvent"; evt.Parent = Fd
local mod = Instance.new("ModuleScript"); mod.Name = "BottleText"; mod.Source = SRC.BottleText; mod.Parent = Fd
local St = Instance.new("Model"); St.Name = "Stand"; St.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
local WOOD, WOOD_D, CREAM, RED, BLUE = C(176, 128, 78), C(120, 82, 48), C(250, 244, 228), C(206, 72, 60), C(48, 110, 168)
local function L(x, y, z) return standCF * CFrame.new(x, y, z) end
local function solid(name, size, color, cf, mat) local p = part(St, name, size, color, cf, mat or Enum.Material.WoodPlanks); p.CanCollide = true; p.CanQuery = true; return p end
local counter = solid("Counter", Vector3.new(7, 3.4, 2.4), WOOD, L(0, 1.7, -0.8))
solid("CounterTop", Vector3.new(7.6, 0.3, 2.9), WOOD_D, L(0, 3.55, -0.8))
for _, x in ipairs({-3.4, 3.4}) do solid("Post", Vector3.new(0.4, 7.6, 0.4), WOOD_D, L(x, 3.8, 0.6), Enum.Material.Wood) end
for i = 0, 6 do part(St, "Awning", Vector3.new(1.1, 0.2, 3.6), (i % 2 == 0) and BLUE or CREAM, L(-3.3 + i * 1.1, 7.7, -0.6) * CFrame.Angles(math.rad(-14), 0, 0), Enum.Material.Fabric) end
for i = 0, 6 do part(St, "AwningFringe", Vector3.new(1.1, 0.45, 0.08), (i % 2 == 0) and BLUE or CREAM, L(-3.3 + i * 1.1, 7.0, -2.35), Enum.Material.Fabric) end
local crate = solid("Crate", Vector3.new(2.2, 1.4, 1.6), WOOD_D, L(-4.8, 0.7, -0.2))
for i = 0, 3 do
	local b = tpl:Clone(); for _, d in ipairs(b:GetDescendants()) do if d:IsA("ProximityPrompt") or d:IsA("Sparkles") then d:Destroy() end end
	b:PivotTo(L(-5.5 + i * 0.48, 1.9, -0.2) * CFrame.Angles(0, 0, math.rad(80 + (i % 2) * 8))); b.Name = "CrateBottle"; b.Parent = St
end
for i = 0, 2 do
	local b = tpl:Clone(); for _, d in ipairs(b:GetDescendants()) do if d:IsA("ProximityPrompt") or d:IsA("Sparkles") then d:Destroy() end end
	b:PivotTo(L(-1.6 + i * 1.4, 4.1, -0.6) * CFrame.Angles(0, math.rad(20 * i), math.rad(90))); b.Name = "CounterBottle"; b.Parent = St
end
local board = solid("SignBoard", Vector3.new(6.6, 1.5, 0.2), CREAM, L(0, 6.3, 0.62), Enum.Material.SmoothPlastic)
local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Front; sg.CanvasSize = Vector2.new(660, 150); sg.LightInfluence = 0.5; sg.Parent = board
local function sgText(text, y, h, colour) local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.Position = UDim2.fromScale(0, y); t.Size = UDim2.fromScale(1, h); t.Text = text; t.TextScaled = true; t.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"); t.TextColor3 = colour; t.Parent = sg end
sgText("MESSAGGI IN BOTTIGLIA", 0.06, 0.52, BLUE); sgText("Messages in a Bottle", 0.6, 0.34, WOOD_D)
do local back = sg:Clone(); back.Face = Enum.NormalId.Back; back.Parent = board end   -- (round 2: lettered on the sea side too)
local wp = Instance.new("ProximityPrompt"); wp.Name = "WritePrompt"; wp.ActionText = "Write a message"; wp.ObjectText = "Messages in a Bottle"
wp.MaxActivationDistance = 10; wp.RequiresLineOfSight = false; wp.HoldDuration = 0; wp.Parent = counter
St.PrimaryPart = counter
St.WorldPivot = standCF
St.Parent = Fd
local s1 = Instance.new("Script"); s1.Name = "BottleServer"; s1.RunContext = Enum.RunContext.Server; s1.Source = SRC.BottleServer; s1.Parent = Fd
local s2 = Instance.new("Script"); s2.Name = "BottleClient"; s2.RunContext = Enum.RunContext.Client; s2.Source = SRC.BottleClient; s2.Parent = Fd
Fd.Parent = workspace
-- (round 2) the gifts popup waits while a bottle panel is open; the interaction counter skips the bottle bookkeeping items
local function patchOne(label, sc, find, repl, mark)
	if not (sc and sc:IsA("LuaSourceContainer")) then print("QQ BOTTLE " .. label .. ": not found; skipped") return end
	local o = sc.Source
	if o:find(mark, 1, true) then print("QQ BOTTLE " .. label .. ": already patched") return end
	local a, b = o:find(find, 1, true)
	if not a or o:find(find, b + 1, true) then print("QQ BOTTLE " .. label .. ": anchor not found once; skipped (harmless - tell the cloud thread)") return end
	local n = o:sub(1, a - 1) .. repl .. o:sub(b + 1)
	local ok, f, err = pcall(function() return loadstring(n) end)
	if ok and not f then print("QQ BOTTLE " .. label .. ": would not compile; skipped") return end
	local bn = sc.Name .. "_pre_bottle1"; if not hb:FindFirstChild(bn) then local c = sc:Clone(); c.Name = bn; c.Enabled = false; c.Parent = hb end
	sc.Source = n
	print(string.format("QQ BOTTLE %s: %d -> %d chars; backup HudBackup.%s", label, #o, #n, bn))
end
local G = workspace:FindFirstChild("Gifts")
patchOne("GiftsClient", G and G:FindFirstChild("GiftsClient"),
	[==[album = true, boat = true}]==], [==[album = true, boat = true, bottle = true}   -- BOTTLE1_20261015: the bottle panel is modal too]==], "BOTTLE1_20261015")
local IA = workspace:FindFirstChild("Interact")
patchOne("InteractServer", IA and IA:FindFirstChild("InteractServer"),
	[==[local SKIP_PREFIX = {"daily_", "passport_", "champion", "thanks_"}]==], [==[local SKIP_PREFIX = {"daily_", "passport_", "champion", "thanks_", "bottle_"}   -- BOTTLE1_20261015: the bottle game's bookkeeping]==], "BOTTLE1_20261015")
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after Bottles") end)
print(string.format("QQ BOTTLE DONE: workspace.Bottles (BottleServer %d, BottleClient %d, BottleText %d chars); the stand at (%.0f, %.1f, %.0f); %d wash spots + the reply spot; send 15, find 10 (5 a day)%s",
	#s1.Source, #s2.Source, #mod.Source, site.X, site.Y, site.Z, #spots, old and ("; the old folder is HudBackup." .. old.Name) or ""))
'''
for n, s in SRC.items():
    assert lua.count("@@" + n + "@@") == 1
    lua = lua.replace("@@" + n + "@@", s)
st = "nil" if STAND is None else "{x = %s, z = %s, yaw = %s}" % (STAND["x"], STAND["z"], STAND["yaw"])
assert lua.count("@@STAND@@") == 1
lua = lua.replace("@@STAND@@", st)
lua = lua.replace("@@L1@@", str(len(SRC["BottleText"]))).replace("@@L2@@", str(len(SRC["BottleServer"]))).replace("@@L3@@", str(len(SRC["BottleClient"])))
assert "@@" not in lua
(HERE / "install_bottle1.lua").write_text(lua, encoding="utf-8")
print("install_bottle1.lua", len(lua.encode()), "bytes")
