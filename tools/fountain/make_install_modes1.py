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

# ---- ShopServer: one item "fountainmode" with three choices (variant 1..3), one mode at a time, set on purchase ----
S = [
    ('\tzoomies    = {repeatable = true, clock = "zoomiesuntil", home = "Speed", minutes = "ZoomiesMinutes"},   -- a stretch of speed; buying again adds to it\n}\n',
     '\tzoomies    = {repeatable = true, clock = "zoomiesuntil", home = "Speed", minutes = "ZoomiesMinutes"},   -- a stretch of speed; buying again adds to it\n'
     '\t-- Oct 10 2026: the Fontana del Limone\'s modes (workspace.FountainModes), one row with three choices; the whole server\'s fountain for Minutes, one mode at a time\n'
     '\tfountainmode = {repeatable = true, modes = {"spaghetti", "frogs", "petals"}},\n'
     '}\n'),
    ('\tif item.palette then\n\t\tvariant = tonumber(variant)\n\t\tif not variant or variant < 1 or variant > item.palette or variant % 1 ~= 0 then return false, "pick a colour" end\n\tend\n',
     '\tif item.palette then\n\t\tvariant = tonumber(variant)\n\t\tif not variant or variant < 1 or variant > item.palette or variant % 1 ~= 0 then return false, "pick a colour" end\n\tend\n'
     '\t-- a fountain mode has to be one of the three (whether the fountain is free is checked again just before paying)\n'
     '\tif item.modes then\n\t\tvariant = tonumber(variant)\n\t\tif not variant or variant < 1 or variant > #item.modes or variant % 1 ~= 0 then return false, "pick one" end\n\tend\n'),
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
     '\tif item.modes and modeTaken() then return false, modeTaken() end\n\n\t-- Enforced HERE'),
    ('\t\tif item.palette and fountainTaken() then return false, fountainTaken() end   -- (nothing yields between here and taking it)\n',
     '\t\tif item.palette and fountainTaken() then return false, fountainTaken() end   -- (nothing yields between here and taking it)\n'
     '\t\tif item.modes and modeTaken() then return false, modeTaken() end\n'),
    ('\t\t\tend\n\t\tend\n\t\treturn true, price\n',
     '\t\t\tend\n\t\tend\n'
     '\t\tif item.modes then\n'
     '\t\t\t-- the Fontana del Limone runs the chosen mode for Minutes (workspace.FountainModes): ActiveMode, ActiveUntil (server time), ActiveBy\n'
     '\t\t\tlocal FM = workspace:FindFirstChild("FountainModes")\n'
     '\t\t\tlocal minutes = (FM and FM:GetAttribute("Minutes")) or 2\n'
     '\t\t\tif FM then FM:SetAttribute("ActiveBy", player.DisplayName); FM:SetAttribute("ActiveUntil", math.floor(workspace:GetServerTimeNow() + minutes * 60)); FM:SetAttribute("ActiveMode", item.modes[variant]) end\n'
     '\t\tend\n'
     '\t\treturn true, price\n'),
]
# ---- ShopClient: one row on the Porto tab with three choice buttons, the countdown while a mode runs ----
C = [
    ('\t{id = "parfum_bottle", name = "Parfum bottle", blurb = "Made with Bella from the purple sea glass. Keep it safe for the parfumerie in France.", once = true, keepsake = true},\n}\n',
     '\t{id = "parfum_bottle", name = "Parfum bottle", blurb = "Made with Bella from the purple sea glass. Keep it safe for the parfumerie in France.", once = true, keepsake = true},\n'
     '\t-- the Fontana del Limone\'s modes (Oct 10 2026): one row, three choices; the whole server\'s fountain for two minutes, one at a time\n'
     '\t{id = "fountainmode", name = "Fountain magic", blurb = "Pick one and the fountain in the square does it for two minutes - for everyone here: spaghetti with smiling meatballs, a frog resort, or a shower of petals.",\n'
     '\t\tmodes = {{id = "spaghetti", name = "Spaghetti"}, {id = "frogs", name = "Frogs"}, {id = "petals", name = "Petals"}}},\n'
     '}\n'),
    ('\tcrabtrap = {italy = true}, camera = {italy = true}, parfum_bottle = {italy = true},\n}\n',
     '\tcrabtrap = {italy = true}, camera = {italy = true}, parfum_bottle = {italy = true}, fountainmode = {italy = true},\n}\n'),
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
    ('\telse\n\tlocal btn = Instance.new("TextButton")\n',
     '\telseif item.modes then\n'
     '\t\t-- THREE CHOICES on one row (Shannon: "one line item with different choices"), each the buy button for its mode\n'
     '\t\trec.choices = {}\n'
     '\t\tlocal n = #item.modes\n'
     '\t\tfor i, mode in ipairs(item.modes) do\n'
     '\t\t\tlocal cb = Instance.new("TextButton"); cb.Name = "Choice" .. i; cb.Text = mode.name\n'
     '\t\t\tcb.AnchorPoint = Vector2.new(1, 0); cb.Position = UDim2.new(1, -12 - (n - i) * 88, 0, 106)\n'
     '\t\t\tcb.Size = UDim2.fromOffset(82, 36); cb.BackgroundColor3 = GOLD; cb.BorderSizePixel = 0; cb.AutoButtonColor = false; cb.ZIndex = 4\n'
     '\t\t\tcb.FontFace = FONT; cb.TextSize = 15; cb.TextColor3 = BTN_INK; cb.Parent = row\n'
     '\t\t\tcorner(cb, UDim.new(0, 10)); stroke(cb, RGB(150, 98, 36), 2, 0.2)\n'
     '\t\t\tcb.MouseButton1Click:Connect(function()\n'
     '\t\t\t\tif not onSale(item) then say(rec, "not in the shop yet", false) return end\n'
     '\t\t\t\tlocal m, left = modeNow()\n'
     '\t\t\t\tif m then say(rec, "the fountain is busy - free in " .. mmss(left), false) return end\n'
     '\t\t\t\tattempt(item, rec, i)\n'
     '\t\t\tend)\n'
     '\t\t\trec.choices[i] = cb\n'
     '\t\tend\n'
     '\t\tlocal pl = Instance.new("TextLabel"); pl.Name = "PriceLabel"; pl.Position = UDim2.new(0, 10, 0, 110)\n'
     '\t\tpl.Size = UDim2.fromOffset(120, 26); pl.BackgroundTransparency = 1; pl.FontFace = FONT; pl.TextSize = 14\n'
     '\t\tpl.TextColor3 = INK_DIM; pl.TextXAlignment = Enum.TextXAlignment.Left; pl.Text = ""; pl.ZIndex = 4; pl.Parent = row\n'
     '\t\trec.priceLabel = pl\n'
     '\telse\n\tlocal btn = Instance.new("TextButton")\n'),
    ('\t\telseif rec and rec.btn then\n\t\t\tlocal price = priceOf(item)\n',
     '\t\telseif rec and rec.choices then                                -- the fountain\'s modes: whose is running, and until when\n'
     '\t\t\tlocal price = priceOf(item)\n'
     '\t\t\tlocal selling = onSale(item)\n'
     '\t\t\tlocal m, left, by = modeNow()\n'
     '\t\t\tlocal runIdx = 0\n'
     '\t\t\tfor i, c in ipairs(item.modes) do if c.id == m then runIdx = i end end\n'
     '\t\t\tif m then\n'
     '\t\t\t\trec.priceLabel.Text = "free in " .. mmss(left)\n'
     '\t\t\t\tif rec.blurb then rec.blurb.Text = string.format("In use: %s\'s %s. Free again in %s.", tostring(by), MODE_NAMES[m] or m, mmss(left)) end\n'
     '\t\t\telse\n'
     '\t\t\t\trec.priceLabel.Text = selling and (type(price) == "number" and (tostring(price) .. " acorns") or "-") or "soon"\n'
     '\t\t\t\tif rec.blurb then rec.blurb.Text = item.blurb end\n'
     '\t\t\tend\n'
     '\t\t\tlocal can = selling and type(price) == "number" and have >= price and not m\n'
     '\t\t\tfor i, b in ipairs(rec.choices) do\n'
     '\t\t\t\tb.BackgroundColor3 = (i == runIdx) and RGB(112, 160, 84) or (can and GOLD or RGB(214, 202, 176))\n'
     '\t\t\t\tb.TextColor3 = (i == runIdx) and RGB(255, 255, 255) or (can and BTN_INK or INK_DIM)\n'
     '\t\t\tend\n'
     '\t\telseif rec and rec.btn then\n\t\t\tlocal price = priceOf(item)\n'),
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
-- the store: the job 59 texts are the base. A store already carrying these modes (three rows from the first version, or this
-- one) is put back to the base from the backups first, then patched afresh, so a re-run always gives the current rows.
local shopDone = cl.Source:find('id = "fountainmode"', 1, true) ~= nil and sv.Source:find("item.modes", 1, true) ~= nil
local restored = false
local baseS, baseC = sv.Source, cl.Source   -- the texts the patch starts from; written back only at the end, after every abort point
if sv.Source:find("modeTaken", 1, true) then
	local b1, b2 = backup:FindFirstChild("ShopServer_pre_modes1"), backup:FindFirstChild("ShopClient_pre_modes1")
	if not (b1 and b2 and #b1.Source == @@NS@@ and #b2.Source == @@NC@@) then warn("QQ FMODE ABORT - the store carries an earlier modes patch and HudBackup has no clean ShopServer_pre_modes1 / ShopClient_pre_modes1 to go back to; nothing changed") return end
	baseS, baseC = b1.Source, b2.Source; restored = true; shopDone = false
end
if #baseS ~= @@NS@@ then warn(string.format("QQ FMODE ABORT - ShopServer is %d chars, expected @@NS@@ (not the job 59 export); nothing changed", #baseS)) return end
if #baseC ~= @@NC@@ then warn(string.format("QQ FMODE ABORT - ShopClient is %d chars, expected @@NC@@ (not the job 59 export); nothing changed", #baseC)) return end
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
F:SetAttribute("Minutes", 2); F:SetAttribute("Reach", 150)   -- two minutes (Shannon: "different from the French one")
F:SetAttribute("FrogSoundId", 73626983091367); F:SetAttribute("BounceSoundId", 0)
F:SetAttribute("PetalsPerSecond", 34); F:SetAttribute("PetalMax", 240); F:SetAttribute("PetalSpread", 38); F:SetAttribute("PetalSpeedMin", 5); F:SetAttribute("PetalSpeedMax", 8.5); F:SetAttribute("PetalFall", 5); F:SetAttribute("PetalDrag", 1.2); F:SetAttribute("PetalRest", 2.6); F:SetAttribute("CarpetCount", 90)
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
	if m:IsA("Model") and (m.Name:lower() == "frog" or m.Name:lower() == "flowers" or m.Name:lower() == "petals" or m:FindFirstChild("EyeL", true) or m:FindFirstChild("Lotus_Petals", true) or m:FindFirstChild("Petal_A", true)) then
		if m:FindFirstChild("Body", true) and m:FindFirstChild("EyeL", true) and not assets:FindFirstChild("Frog") then
			tidy(m); m.Name = "Frog"; m.PrimaryPart = m:FindFirstChild("Body", true); m.Parent = assets; table.insert(got, "Frog")
		elseif m:FindFirstChild("Petal_A", true) and not assets:FindFirstChild("Petal_A", true) then
			tidy(m); m.Name = "Petals"; m.Parent = assets; table.insert(got, "Petals")
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
	Flower_C_Petals = Color3.fromRGB(158, 87, 219), Flower_C_Centre = Color3.fromRGB(255, 204, 38), Petal_A = Color3.fromRGB(255, 110, 150), Petal_B = Color3.fromRGB(255, 110, 150), Petal_C = Color3.fromRGB(255, 110, 150)}
local coloured = 0
for _, d in ipairs(assets:GetDescendants()) do if d:IsA("BasePart") and COLOURS[d.Name] and d.TextureID == "" then d.Color = COLOURS[d.Name]; d.Material = Enum.Material.SmoothPlastic; coloured += 1 end end
local have = {}
for _, n in ipairs({"Frog", "LilyPad", "Lotus", "Flowers", "Petals"}) do if assets:FindFirstChild(n) then table.insert(have, n) end end
-- the store
Shop:SetAttribute("Price_fountainmode", Shop:GetAttribute("Price_fountainmode") or 25); Shop:SetAttribute("Sell_fountainmode", true)
for _, w in ipairs({"spaghetti", "frogs", "petals"}) do Shop:SetAttribute("Price_" .. w, nil); Shop:SetAttribute("Sell_" .. w, nil) end   -- (the first version's three rows)
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
	local newS = patch(baseS, @@S@@, "ShopServer")
	local newC = newS and patch(baseC, @@C@@, "ShopClient")
	if not (newS and newC) then return end
	if not backup:FindFirstChild("ShopServer_pre_modes1") then local b1 = sv:Clone(); b1.Name = "ShopServer_pre_modes1"; b1.Enabled = false; b1.Parent = backup end
	if not backup:FindFirstChild("ShopClient_pre_modes1") then local b2 = cl:Clone(); b2.Name = "ShopClient_pre_modes1"; b2.Enabled = false; b2.Parent = backup end
	sv.Source = newS; cl.Source = newC
	shopNote = string.format("ShopServer %d -> %d, ShopClient %d -> %d chars%s; backups HudBackup.ShopServer_pre_modes1 / ShopClient_pre_modes1 (the job 59 texts)", @@NS@@, #newS, @@NC@@, #newC, restored and " (the earlier three-row patch undone first)" or "")
end
game:GetService("ChangeHistoryService"):SetWaypoint("Fountain modes installed")
print(string.format("QQ FMODE DONE: workspace.FountainModes (client %d chars; rim y %s at r %.1f, paving y %.1f); assets in ReplicatedStorage.FountainModeAssets: %s (moved in now: %s; %d flower parts coloured); %s", #cs.Source, tostring(rimY and string.format("%.2f", rimY) or "not measured, default"), rimR, groundY, #have > 0 and table.concat(have, ", ") or "NONE - import frog.fbx and flowers.fbx and run again", #got > 0 and table.concat(got, ", ") or "none", coloured, shopNote))
'''
for k, v in {"NS": str(NS), "NC": str(NC), "CLIENT": L(client), "S": tbl(S), "C": tbl(C)}.items(): lua = lua.replace("@@" + k + "@@", v)
assert "@@" not in lua
(ROOT / "tools/fountain/install_modes1.lua").write_text(lua, encoding="utf-8")
print("install_modes1.lua", len(lua.encode()), "chars; client", len(client.encode()), "; ShopServer", NS, "->", len(ps.encode()), "; ShopClient", NC, "->", len(pc.encode()))
