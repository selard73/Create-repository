#!/usr/bin/env python3
"""Builds tools/fountain/install_modes1.lua (job 61): the Fontana del Limone's bought modes (Shannon, Oct 10 2026) -
spaghetti with smiling meatballs, the Frog Resort, the petal fountain. ONE Studio script (EDIT mode):
  1. workspace.FountainModes (Folder; attributes Minutes 10, Reach 150, FrogSoundId, PetalTexture, the measured RimY/RimR/
     GroundY, ActiveMode/ActiveUntil/ActiveBy empty) with FountainModeClient from tools/fountain/src.
  2. ReplicatedStorage.FountainModeAssets: the models Shannon imported (File > Import 3D of frog.fbx and flowers.fbx) are
     moved in and tidied (anchored, no collisions): Frog (+ Sunglasses/SunHat/SwimRing), LilyPad, Lotus, Flowers.
     Missing imports only warn; the modes run without them (the resort has no frogs until the frog is in).
  3. The Acorn Store: Price_spaghetti/frogs/petals (25) and Sell_* on workspace.Shop; exact-string patches of ShopServer
     (9261 chars) and ShopClient (35014 chars, the job 59 export): three items on the Porto tab, bought like the French
     fountain colour (one mode at a time for the whole server, a countdown while one runs). Backups ShopServer_pre_modes1
     and ShopClient_pre_modes1 in ServerStorage.HudBackup. Refuses if the store texts are not the exported ones.
Output lines "QQ FMODE". Run from the repo root: python3 tools/fountain/make_install_modes1.py
"""
import pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]
def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"
client = (ROOT / "tools/fountain/src/FountainModeClient.lua").read_text(encoding="utf-8")
server_src = (ROOT / "tools/shop/src/ShopServer.lua").read_text(encoding="utf-8")
shopc_src = (ROOT / "tools/shop/src/ShopClient.lua").read_text(encoding="utf-8")
NS, NC = len(server_src.encode()), len(shopc_src.encode())
assert (NS, NC) == (9261, 35014), (NS, NC)

# ---- ShopServer: the three items, the "one mode at a time" check, and setting the mode on purchase ----
S = [
    ('\tzoomies    = {repeatable = true, clock = "zoomiesuntil", home = "Speed", minutes = "ZoomiesMinutes"},   -- a stretch of speed; buying again adds to it\n}\n',
     '\tzoomies    = {repeatable = true, clock = "zoomiesuntil", home = "Speed", minutes = "ZoomiesMinutes"},   -- a stretch of speed; buying again adds to it\n'
     '\t-- Oct 10 2026: the Fontana del Limone\'s modes (workspace.FountainModes): the whole server\'s fountain for Minutes, one mode at a time\n'
     '\tspaghetti  = {repeatable = true, mode = "spaghetti"},\n'
     '\tfrogs      = {repeatable = true, mode = "frogs"},\n'
     '\tpetals     = {repeatable = true, mode = "petals"},\n'
     '}\n'),
    ('\tif item.palette and fountainTaken() then return false, fountainTaken() end\n\n\t-- Enforced HERE',
     '\tif item.palette and fountainTaken() then return false, fountainTaken() end\n'
     '\t-- the Fontana del Limone likewise runs one bought mode at a time (workspace.FountainModes)\n'
     '\tlocal function modeTaken()\n'
     '\t\tlocal FM = workspace:FindFirstChild("FountainModes")\n'
     '\t\tlocal untilT = FM and FM:GetAttribute("ActiveUntil") or 0\n'
     '\t\tlocal left = untilT - workspace:GetServerTimeNow()\n'
     '\t\tif FM and (FM:GetAttribute("ActiveMode") or "") ~= "" and left > 0 then\n'
     '\t\t\tleft = math.ceil(left)\n'
     '\t\t\treturn string.format("the fountain is busy - free in %d:%02d", math.floor(left / 60), left % 60)\n'
     '\t\tend\n'
     '\t\treturn nil\n'
     '\tend\n'
     '\tif item.mode and modeTaken() then return false, modeTaken() end\n\n\t-- Enforced HERE'),
    ('\t\tif item.palette and fountainTaken() then return false, fountainTaken() end   -- (nothing yields between here and taking it)\n',
     '\t\tif item.palette and fountainTaken() then return false, fountainTaken() end   -- (nothing yields between here and taking it)\n'
     '\t\tif item.mode and modeTaken() then return false, modeTaken() end\n'),
    ('\t\t\tend\n\t\tend\n\t\treturn true, price\n',
     '\t\t\tend\n\t\tend\n'
     '\t\tif item.mode then\n'
     '\t\t\t-- the Fontana del Limone runs this mode for Minutes (workspace.FountainModes): ActiveMode, ActiveUntil (server time), ActiveBy\n'
     '\t\t\tlocal FM = workspace:FindFirstChild("FountainModes")\n'
     '\t\t\tlocal minutes = (FM and FM:GetAttribute("Minutes")) or 10\n'
     '\t\t\tif FM then FM:SetAttribute("ActiveBy", player.DisplayName); FM:SetAttribute("ActiveUntil", math.floor(workspace:GetServerTimeNow() + minutes * 60)); FM:SetAttribute("ActiveMode", item.mode) end\n'
     '\t\tend\n'
     '\t\treturn true, price\n'),
]
# ---- ShopClient: the rows on the Porto tab, the countdown while a mode runs ----
C = [
    ('\t{id = "parfum_bottle", name = "Parfum bottle", blurb = "Made with Bella from the purple sea glass. Keep it safe for the parfumerie in France.", once = true, keepsake = true},\n}\n',
     '\t{id = "parfum_bottle", name = "Parfum bottle", blurb = "Made with Bella from the purple sea glass. Keep it safe for the parfumerie in France.", once = true, keepsake = true},\n'
     '\t-- the Fontana del Limone\'s modes (Oct 10 2026): the whole server\'s fountain for ten minutes, one at a time\n'
     '\t{id = "spaghetti", name = "Spaghetti fountain", blurb = "Noodles pour where the water does and smiling meatballs bounce out - ten minutes, for everyone here.", mode = "spaghetti"},\n'
     '\t{id = "frogs",     name = "Frog resort",        blurb = "The frogs move in: lily pads, a parasol, a deck chair, string lights and a lot of croaking - ten minutes, for everyone here.", mode = "frogs"},\n'
     '\t{id = "petals",    name = "Petal fountain",     blurb = "Every jet a stream of flower petals and a carpet of them on the water - ten minutes, for everyone here.", mode = "petals"},\n'
     '}\n'),
    ('\tcrabtrap = {italy = true}, camera = {italy = true}, parfum_bottle = {italy = true},\n}\n',
     '\tcrabtrap = {italy = true}, camera = {italy = true}, parfum_bottle = {italy = true}, spaghetti = {italy = true}, frogs = {italy = true}, petals = {italy = true},\n}\n'),
    ('local function mmss(s) return string.format("%d:%02d", math.floor(s / 60), s % 60) end\n',
     '-- the Fontana del Limone\'s modes are the server\'s too (workspace.FountainModes): one at a time, with a countdown\n'
     'local MODE_NAMES = {spaghetti = "spaghetti fountain", frogs = "frog resort", petals = "petal fountain"}\n'
     'local function modeNow()\n'
     '\tlocal FM = workspace:FindFirstChild("FountainModes")\n'
     '\tlocal m = FM and FM:GetAttribute("ActiveMode") or ""\n'
     '\tlocal untilT = FM and FM:GetAttribute("ActiveUntil") or 0\n'
     '\tlocal left = untilT - workspace:GetServerTimeNow()\n'
     '\tif m ~= "" and left > 0 then return m, math.ceil(left), (FM:GetAttribute("ActiveBy") or "someone") end\n'
     '\treturn nil, 0, nil\n'
     'end\n'
     'local function mmss(s) return string.format("%d:%02d", math.floor(s / 60), s % 60) end\n'),
    ('\t\tif not onSale(item) then say(rec, "not in the shop yet", false) return end\n\t\tattempt(item, rec)\n\tend)\n',
     '\t\tif not onSale(item) then say(rec, "not in the shop yet", false) return end\n'
     '\t\tif item.mode then local m, left = modeNow(); if m then say(rec, "the fountain is busy - free in " .. mmss(left), false) return end end\n'
     '\t\tattempt(item, rec)\n\tend)\n'),
    ('\t\t\telse\n\t\t\t\tlabel = tostring(price) .. " acorns"\n\t\t\tend\n',
     '\t\t\telse\n\t\t\t\tlabel = tostring(price) .. " acorns"\n\t\t\tend\n'
     '\t\t\tif item.mode then                                            -- a fountain mode: whose is running, and until when\n'
     '\t\t\t\tlocal m, left, by = modeNow()\n'
     '\t\t\t\tif m then label = "free in " .. mmss(left); if rec.blurb then rec.blurb.Text = string.format("In use: %s\'s %s. Free again in %s.", tostring(by), MODE_NAMES[m] or m, mmss(left)) end\n'
     '\t\t\t\telseif rec.blurb then rec.blurb.Text = item.blurb end\n'
     '\t\t\tend\n'),
    ('\t\t\tlocal affordable = selling and not (item.once and owned) and (item.robux or (type(price) == "number" and have >= price))\n',
     '\t\t\tlocal affordable = selling and not (item.once and owned) and (item.robux or (type(price) == "number" and have >= price))\n'
     '\t\t\tif item.mode and modeNow() then affordable = false end\n'),
    ('\tif FCw then for _, a in ipairs({"ActiveColour", "ActiveUntil", "ActiveBy"}) do FCw:GetAttributeChangedSignal(a):Connect(refresh) end end\n',
     '\tif FCw then for _, a in ipairs({"ActiveColour", "ActiveUntil", "ActiveBy"}) do FCw:GetAttributeChangedSignal(a):Connect(refresh) end end\n'
     '\tlocal FMw = workspace:FindFirstChild("FountainModes")\n'
     '\tif FMw then for _, a in ipairs({"ActiveMode", "ActiveUntil", "ActiveBy"}) do FMw:GetAttributeChangedSignal(a):Connect(refresh) end end\n'),
    ('\t\t\tlocal running = fountainNow() > 0\n', '\t\t\tlocal running = fountainNow() > 0 or modeNow() ~= nil\n'),
]
ps, pc = server_src, shopc_src
for a, b in S: assert ps.count(a) == 1, ("server", a[:60]); ps = ps.replace(a, b)
for a, b in C: assert pc.count(a) == 1, ("client", a[:60]); pc = pc.replace(a, b)
(ROOT / "tools/shop/src/ShopServer_modes1.lua").write_text(ps, encoding="utf-8")
(ROOT / "tools/shop/src/ShopClient_modes1.lua").write_text(pc, encoding="utf-8")

def tbl(pairs_): return "{" + ", ".join("{%s, %s}" % (L(a), L(b)) for a, b in pairs_) + "}"
lua = r'''-- fountain/install_modes1 (job 61): EDIT mode, re-runnable. The Fontana del Limone's bought modes (Shannon, Oct 10 2026):
-- spaghetti + smiling meatballs, the Frog Resort, the petal fountain. workspace.FountainModes + its client, the assets
-- Shannon imported -> ReplicatedStorage.FountainModeAssets, the Acorn Store rows (ShopServer / ShopClient patched, backups
-- ServerStorage.HudBackup.ShopServer_pre_modes1 / ShopClient_pre_modes1). Output lines "QQ FMODE".
if game:GetService("RunService"):IsRunning() then warn("QQ FMODE ABORT - Play mode") return end
local RS, SS = game:GetService("ReplicatedStorage"), game:GetService("ServerStorage")
local Shop = workspace:FindFirstChild("Shop")
local sv = Shop and Shop:FindFirstChild("ShopServer"); local cl = Shop and Shop:FindFirstChild("ShopClient")
if not (sv and cl) then warn("QQ FMODE ABORT - workspace.Shop.ShopServer / ShopClient missing") return end
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local shopDone = backup:FindFirstChild("ShopServer_pre_modes1") ~= nil and sv.Source:find("modeTaken", 1, true) ~= nil
if not shopDone then
	if #sv.Source ~= @@NS@@ then warn(string.format("QQ FMODE ABORT - ShopServer is %d chars, expected @@NS@@ (not the job 59 export); nothing changed", #sv.Source)) return end
	if #cl.Source ~= @@NC@@ then warn(string.format("QQ FMODE ABORT - ShopClient is %d chars, expected @@NC@@ (not the job 59 export); nothing changed", #cl.Source)) return end
end
-- the fountain, and its rim and the paving, measured
local fm = workspace
for seg in string.gmatch("PortoNocciola/13 Hillside town/Fontana del Limone", "[^/]+") do fm = fm and fm:FindFirstChild(seg) end
local water = fm and fm:FindFirstChild("Water", true)
if not water then warn("QQ FMODE ABORT - workspace.PortoNocciola['13 Hillside town']['Fontana del Limone'].Water not found") return end
local c = water.Position
local rimY, rimR = nil, 6.2
for _, r in ipairs({5.6, 6.0, 6.4, 6.8}) do
	for _, a in ipairs({0, 1.57, 3.14, 4.71}) do
		local hit = workspace:Raycast(c + Vector3.new(math.cos(a) * r, 8, math.sin(a) * r), Vector3.new(0, -14, 0))
		if hit and hit.Instance.Name == "Stone" and (not rimY or hit.Position.Y > rimY) then rimY, rimR = hit.Position.Y, r end
	end
end
local gHit = workspace:Raycast(c + Vector3.new(10, 8, 0), Vector3.new(0, -24, 0))
local groundY = gHit and gHit.Position.Y or (c.Y - 4)
-- the folder and the client
local old = workspace:FindFirstChild("FountainModes"); if old then old:Destroy() end
local F = Instance.new("Folder"); F.Name = "FountainModes"
F:SetAttribute("FountainPath", "PortoNocciola/13 Hillside town/Fontana del Limone")
F:SetAttribute("Minutes", 10); F:SetAttribute("Reach", 150)
F:SetAttribute("FrogSoundId", 73626983091367); F:SetAttribute("BounceSoundId", 0)
F:SetAttribute("PetalTexture", ""); F:SetAttribute("PetalSize", 0.55); F:SetAttribute("PetalRate", 0.6); F:SetAttribute("CarpetCount", 90)
F:SetAttribute("NoodleTexture", ""); F:SetAttribute("NoodleTop", 14); F:SetAttribute("NoodleRim", 20); F:SetAttribute("MeatballEvery", 1.6)
F:SetAttribute("SignText", "FROG RESORT"); F:SetAttribute("DeckAngle", 0.9)
F:SetAttribute("RimY", rimY or (c.Y - 2.15 + 1.3)); F:SetAttribute("RimR", rimR); F:SetAttribute("GroundY", groundY)
F:SetAttribute("ActiveMode", ""); F:SetAttribute("ActiveUntil", 0); F:SetAttribute("ActiveBy", "")
local cs = Instance.new("Script"); cs.Name = "FountainModeClient"; cs.RunContext = Enum.RunContext.Client; cs.Source = @@CLIENT@@; cs.Parent = F
do local f, err = loadstring(cs.Source); if not f then warn("QQ FMODE ABORT - FountainModeClient does not compile: " .. tostring(err)); F:Destroy(); return end end
F.Parent = workspace
-- the assets Shannon imported (File > Import 3D): a Model "frog" with MeshParts Body/EyeL/EyeR (+ Sunglasses, SunHat, SwimRing)
-- and a Model "flowers" with LilyPad, Lotus_Petals/Lotus_Centre, Flower_*_Petals/_Centre, Leaf
local assets = RS:FindFirstChild("FountainModeAssets") or Instance.new("Folder"); assets.Name = "FountainModeAssets"; assets.Parent = RS
local function tidy(m) for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false end end end
local got = {}
for _, m in ipairs(workspace:GetChildren()) do
	if m:IsA("Model") and (m.Name:lower() == "frog" or m.Name:lower() == "flowers" or m:FindFirstChild("EyeL", true) or m:FindFirstChild("Lotus_Petals", true)) then
		if m:FindFirstChild("Body", true) and m:FindFirstChild("EyeL", true) and not assets:FindFirstChild("Frog") then
			tidy(m); m.Name = "Frog"; m.PrimaryPart = m:FindFirstChild("Body", true); m.Parent = assets; table.insert(got, "Frog")
		elseif m:FindFirstChild("LilyPad", true) then
			tidy(m)
			local pad = m:FindFirstChild("LilyPad", true); if pad and not assets:FindFirstChild("LilyPad") then pad.Parent = assets; table.insert(got, "LilyPad") end
			local lp, lc = m:FindFirstChild("Lotus_Petals", true), m:FindFirstChild("Lotus_Centre", true)
			if lp and not assets:FindFirstChild("Lotus") then local lot = Instance.new("Model"); lot.Name = "Lotus"; lp.Parent = lot; if lc then lc.Parent = lot end; lot.PrimaryPart = lp; lot.Parent = assets; table.insert(got, "Lotus") end
			if not assets:FindFirstChild("Flowers") then m.Name = "Flowers"; m.Parent = assets; table.insert(got, "Flowers (the rest)") else m:Destroy() end
		end
	end
end
-- the flowers' flat Blender colours do not survive Import 3D (they come in grey): set by name, every run
local COLOURS = {LilyPad = Color3.fromRGB(48, 120, 48), Leaf = Color3.fromRGB(66, 153, 56), Lotus_Petals = Color3.fromRGB(250, 148, 189), Lotus_Centre = Color3.fromRGB(255, 204, 38),
	Flower_A_Petals = Color3.fromRGB(242, 102, 158), Flower_A_Centre = Color3.fromRGB(255, 204, 38), Flower_B_Petals = Color3.fromRGB(224, 41, 66), Flower_B_Centre = Color3.fromRGB(255, 204, 38),
	Flower_C_Petals = Color3.fromRGB(158, 87, 219), Flower_C_Centre = Color3.fromRGB(255, 204, 38)}
local coloured = 0
for _, d in ipairs(assets:GetDescendants()) do if d:IsA("BasePart") and COLOURS[d.Name] and d.TextureID == "" then d.Color = COLOURS[d.Name]; d.Material = Enum.Material.SmoothPlastic; coloured += 1 end end
local have = {}
for _, n in ipairs({"Frog", "LilyPad", "Lotus", "Flowers"}) do if assets:FindFirstChild(n) then table.insert(have, n) end end
-- the store
Shop:SetAttribute("Price_spaghetti", Shop:GetAttribute("Price_spaghetti") or 25); Shop:SetAttribute("Price_frogs", Shop:GetAttribute("Price_frogs") or 25); Shop:SetAttribute("Price_petals", Shop:GetAttribute("Price_petals") or 25)
Shop:SetAttribute("Sell_spaghetti", true); Shop:SetAttribute("Sell_frogs", true); Shop:SetAttribute("Sell_petals", true)
local shopNote = "store already patched (kept)"
if not shopDone then
	local function patch(src, pairs_, what)
		for i, p in ipairs(pairs_) do
			local a, b = src:find(p[1], 1, true)
			if not a then warn("QQ FMODE ABORT - " .. what .. " find " .. i .. " not found; the store is unchanged") return nil end
			if src:find(p[1], b + 1, true) then warn("QQ FMODE ABORT - " .. what .. " find " .. i .. " matches more than once; the store is unchanged") return nil end
			src = src:sub(1, a - 1) .. p[2] .. src:sub(b + 1)
		end
		local f, err = loadstring(src)
		if not f then warn("QQ FMODE ABORT - patched " .. what .. " does not compile: " .. tostring(err)) return nil end
		return src
	end
	local newS = patch(sv.Source, @@S@@, "ShopServer")
	local newC = newS and patch(cl.Source, @@C@@, "ShopClient")
	if not (newS and newC) then return end
	local b1 = sv:Clone(); b1.Name = "ShopServer_pre_modes1"; b1.Enabled = false; b1.Parent = backup
	local b2 = cl:Clone(); b2.Name = "ShopClient_pre_modes1"; b2.Enabled = false; b2.Parent = backup
	sv.Source = newS; cl.Source = newC
	shopNote = string.format("ShopServer %d -> %d, ShopClient %d -> %d chars; backups HudBackup.ShopServer_pre_modes1 / ShopClient_pre_modes1", @@NS@@, #newS, @@NC@@, #newC)
end
game:GetService("ChangeHistoryService"):SetWaypoint("Fountain modes installed")
print(string.format("QQ FMODE DONE: workspace.FountainModes (client %d chars; rim y %s at r %.1f, paving y %.1f); assets in ReplicatedStorage.FountainModeAssets: %s (moved in now: %s; %d flower parts coloured); %s", #cs.Source, tostring(rimY and string.format("%.2f", rimY) or "not measured, default"), rimR, groundY, #have > 0 and table.concat(have, ", ") or "NONE - import frog.fbx and flowers.fbx and run again", #got > 0 and table.concat(got, ", ") or "none", coloured, shopNote))
'''
for k, v in {"NS": str(NS), "NC": str(NC), "CLIENT": L(client), "S": tbl(S), "C": tbl(C)}.items(): lua = lua.replace("@@" + k + "@@", v)
assert "@@" not in lua
(ROOT / "tools/fountain/install_modes1.lua").write_text(lua, encoding="utf-8")
print("install_modes1.lua", len(lua.encode()), "chars; client", len(client.encode()), "; ShopServer", NS, "->", len(ps.encode()), "; ShopClient", NC, "->", len(pc.encode()))
