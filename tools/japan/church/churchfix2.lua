-- churchfix2.lua (Oct 23 2026): Shannon: churchfix1 "broke" the church windows - "before you could see through the windows and
-- they looked like stained glass, now they look like opaque, painted on windows and there is a gap in the rounded top between
-- the window and the wall". The old gold mesh is the whole pane of every window (blue + red sit on it), so churchfix1's opaque
-- gold hid the view; it is 0.1 narrower than the opening and churchfix1 slid it 0.05 sideways = sky round the arch.
-- New glass (gen_church_glass.py -> japan_church_glass_fix.fbx, imported by her): one layer per window, gold / blue / red side by
-- side (nothing stacked = nothing for the transparency sort to flip, the VR flicker), gold 0.1 into the wall all round, dark
-- lead cames over the colour joins; one mesh per colour per side wall. The import is lined up on Church_Glass_Ref (a copy of the
-- old gold mesh): new CFrame = old gold's original CFrame * Ref^-1 * part, checked by rays through the six windows and the rose.
-- The old Church_Glass_Gold / Blue / Red move to ServerStorage.HudBackup.ChurchGlass_pre_churchfix2 (churchfix1's attributes on
-- them). Guarded by JapanMap.Church attribute ChurchFix2. Output "QQ CHURCHFIX2".
local SS = game:GetService("ServerStorage")
local church = workspace.JapanMap.Church
local shell = church.Shell
local hb = SS:FindFirstChild("HudBackup")
if church:GetAttribute("ChurchFix2") then return "QQ CHURCHFIX2 already installed (" .. tostring(church:GetAttribute("ChurchFix2")) .. ")" end
local imp
for _, top in ipairs(workspace:GetChildren()) do
	if top:IsA("Model") and top:FindFirstChild("Church_Glass_Ref", true) then imp = top break end
end
if not (imp and hb) then return "QQ CHURCHFIX2 ABORT: no imported model with Church_Glass_Ref in workspace (import japan_church_glass_fix.fbx), or no HudBackup" end
local ref = imp:FindFirstChild("Church_Glass_Ref", true)
local oldGold, oldBlue, oldRed = shell:FindFirstChild("Church_Glass_Gold"), shell:FindFirstChild("Church_Glass_Blue"), shell:FindFirstChild("Church_Glass_Red")
if not (oldGold and oldBlue and oldRed) then return "QQ CHURCHFIX2 ABORT: old glass missing from the Shell" end
if (ref.Size - oldGold.Size).Magnitude > 0.02 then return "QQ CHURCHFIX2 ABORT: Ref size " .. tostring(ref.Size) .. " is not the old gold's " .. tostring(oldGold.Size) end
local G = oldGold:GetAttribute("ChurchFix1WasCFrame") or oldGold.CFrame
local out = {}
local function say(s) table.insert(out, "QQ CHURCHFIX2 " .. s) end

local parts = {}
for _, d in ipairs(imp:GetDescendants()) do if d:IsA("BasePart") then table.insert(parts, d) end end
local rel = {}
for _, p in ipairs(parts) do rel[p] = ref.CFrame:Inverse() * p.CFrame end
-- the six windows (centres) and the rose: where the Ref must answer a ray once it is placed
local function refOk()
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {ref}
	local c = G.Position
	local bad = 0
	for _, sx in ipairs({1, -1}) do
		for _, dz in ipairs({7.05, -4.95, -16.95}) do              -- the windows at z -262.8 / -274.8 / -286.8 (the gold's centre -269.85)
			local o = Vector3.new(c.X, 11, c.Z + dz)
			local h = workspace:Raycast(o, Vector3.new(sx * 20, 0, 0), rp)
			if not (h and math.abs(math.abs(h.Position.X - c.X) - 15.34) < 0.05) then bad += 1 end   -- the Ref's inner face (15.4 - 0.06)
		end
	end
	local h = workspace:Raycast(Vector3.new(c.X, 19.2, c.Z + 30), Vector3.new(0, 0, -15), rp)   -- the rose ring, from in front of the door
	if not (h and math.abs(h.Position.Z - (c.Z + 18.55)) < 0.1) then bad += 1 end
	return bad
end
local function place(mode)
	for _, p in ipairs(parts) do
		if mode == 1 then p.CFrame = G * rel[p]
		else p.CFrame = CFrame.new(G.Position - ref.CFrame.Position) * p.CFrame end      -- fallback: a pure shift, the import's own turn kept
	end
end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before churchfix2") end)
local start = {}
for _, p in ipairs(parts) do start[p] = p.CFrame end
place(1)
local bad = refOk()
if bad > 0 then
	for _, p in ipairs(parts) do p.CFrame = start[p] end
	place(2)
	local bad2 = refOk()
	if bad2 > 0 then
		for _, p in ipairs(parts) do p.CFrame = start[p] end
		return "QQ CHURCHFIX2 ABORT: the import does not line up with the old glass (" .. bad .. " / " .. bad2 .. " of 7 checks missed) - nothing changed"
	end
	say("lined up by a pure shift (the import's turn kept)")
else
	say("lined up on the old gold mesh (7 of 7 checks hit)")
end

-- the old glass out to the backup
local bk = Instance.new("Folder"); bk.Name = "ChurchGlass_pre_churchfix2"; bk.Parent = hb
for _, p in ipairs({oldGold, oldBlue, oldRed}) do p:SetAttribute("ChurchFix2From", p:GetFullName()); p.Parent = bk end
say("old Church_Glass_Gold / Blue / Red moved to HudBackup.ChurchGlass_pre_churchfix2")

-- the new pieces into the Shell
local C = Color3.fromRGB
local COLOUR = {Gold = oldGold.Color, Blue = oldBlue.Color, Red = oldRed.Color}
local n = 0
for _, p in ipairs(parts) do
	if p == ref then continue end
	p.Anchored = true; p.CastShadow = false; p.CanTouch = false
	if p:IsA("MeshPart") then p.DoubleSided = false end
	pcall(function() p.RenderFidelity = Enum.RenderFidelity.Precise end)
	local kind = p.Name:match("^Church_Glass_(%a+)_")
	if kind then
		p.Material = Enum.Material.Glass; p.Transparency = 0.3; p.Reflectance = 0; p.Color = COLOUR[kind]
		p.CanCollide = (kind ~= "Red"); p.CanQuery = true
		p.Name = "Church_Glass_" .. kind .. (p.Position.X > G.Position.X and "_PX" or "_NX")      -- named by the wall it is on
	else                                                                                   -- Church_Lead_Came
		p.Material = Enum.Material.SmoothPlastic; p.Transparency = 0; p.Color = C(43, 38, 36)
		p.CanCollide = false; p.CanQuery = false
	end
	p:SetAttribute("ChurchFix2", true)
	p.Parent = shell
	n += 1
end
ref:Destroy()
if #imp:GetDescendants() == 0 then imp:Destroy() else say("WARNING: the import model still holds " .. #imp:GetDescendants() .. " things - left in workspace") end
say(n .. " new pieces in the Shell: gold / blue / red per side wall (Glass 0.3, colours of the old glass) + the lead cames")
church:SetAttribute("ChurchFix2", "2026-10-23")
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after churchfix2") end)
say("DONE - EDIT INSTALLED; NOT PUBLISHED")
return table.concat(out, "\n")
