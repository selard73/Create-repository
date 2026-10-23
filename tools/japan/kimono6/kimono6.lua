-- kimono6.lua (Oct 23 2026): Shannon on And More Kimonos (JapanMap."Outdoor market revision"."Kimono atelier"): "the store front
-- looks good, but the store in the back is too deep, the back wall should be brought forward a little and the rug on the floor
-- and the back wall should be a slightly darker color".
--  1. The back-wall group of "Festive boutique interior finish" (every part behind x 5969.5: plaster rear wall, wainscot, rails,
--     rear posts, the shoji panels, the long cedar cabinet + shelves + folded silks) comes forward D studs; the concealed rear
--     wash lights move with it (same distance from the wall).
--  2. The plaster rear wall, the wainscot and its rails now run into both side walls (z -80..-50) - they stopped 1 stud short,
--     which would show the empty space left behind the moved wall.
--  3. The tatami runner (the rug) starts just in front of the cabinet (its front edge kept; the low table stays centred on it),
--     its dark edging cut to match.
--  4. Colours x0.86: the runner, the plaster rear wall and the shoji paper panels.
-- Backup: HudBackup.KimonoInterior_pre_kimono6 (a copy of the whole interior finish). AndMoreKimonosVersion 5 -> 6. "QQ KIMONO6".
local SS = game:GetService("ServerStorage")
local at = workspace.JapanMap["Outdoor market revision"]:FindFirstChild("Kimono atelier")
local hb = SS:FindFirstChild("HudBackup")
local f = at and at:FindFirstChild("Festive boutique interior finish")
if not (f and hb) then return "QQ KIMONO6 ABORT: interior or HudBackup missing" end
if at:GetAttribute("AndMoreKimonosVersion") ~= 5 then return "QQ KIMONO6 ABORT: AndMoreKimonosVersion is " .. tostring(at:GetAttribute("AndMoreKimonosVersion")) .. ", expected 5" end
local D, DARK = 4.0, 0.86
local out = {}
local function say(s) table.insert(out, "QQ KIMONO6 " .. s) end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before kimono6") end)
local keep = f:Clone(); keep.Name = "KimonoInterior_pre_kimono6"; keep.Parent = hb
say("backup: HudBackup.KimonoInterior_pre_kimono6 (" .. #keep:GetDescendants() .. " things)")
-- 1. the back-wall group forward
local moved = 0
for _, p in ipairs(f:GetDescendants()) do
	if p:IsA("BasePart") and (p.Position.X < 5969.5 or p.Name == "Concealed warm rear wash") then
		p.CFrame = p.CFrame + Vector3.new(D, 0, 0); moved += 1
	end
end
say(moved .. " back-wall parts (and the rear wash lights) forward " .. D .. " studs")
-- 2. wall to wall
local Z0, Z1 = -80.0, -50.0                                -- the side walls' middles (their inner faces at -79.8 / -50.2)
for _, n in ipairs({"Warm plaster rear wall", "Cedar rear wainscot", "Wainscot cap rail", "Lower rear timber rail", "Upper rear timber rail"}) do
	local p = f:FindFirstChild(n)
	assert(p, "no " .. n)
	p.Size = Vector3.new(p.Size.X, p.Size.Y, Z1 - Z0)
	p.CFrame = CFrame.new(p.Position.X, p.Position.Y, (Z0 + Z1) / 2) * p.CFrame.Rotation
end
say("rear wall, wainscot and rails now run into both side walls (z -80 to -50)")
-- 3. the runner from the cabinet's front
local cab = 0
for _, p in ipairs(f:GetDescendants()) do
	if p:IsA("BasePart") and (p.Name:find("Cabinet") or p.Name:find("cabinet") or p.Name:find("Small brass cabinet pull")) then
		cab = math.max(cab, p.Position.X + math.abs(p.CFrame.RightVector.X) * p.Size.X / 2 + math.abs(p.CFrame.LookVector.X) * p.Size.Z / 2)
	end
end
local run = f["Central tatami runner"]
local front = run.Position.X + run.Size.X / 2
local backX = cab + 0.3
local len = front - backX
assert(len > 3, "the runner would be too short")
run.Size = Vector3.new(len, run.Size.Y, run.Size.Z); run.CFrame = CFrame.new((front + backX) / 2, run.Position.Y, run.Position.Z) * run.CFrame.Rotation
for _, e in ipairs(f:GetChildren()) do
	if e:IsA("BasePart") and e.Name == "Tatami dark edging" then
		e.Size = Vector3.new(len, e.Size.Y, e.Size.Z); e.CFrame = CFrame.new((front + backX) / 2, e.Position.Y, e.Position.Z) * e.CFrame.Rotation
	end
end
say(string.format("tatami runner now x %.2f to %.2f (%.1f long; the cabinet's front at %.2f, the low table at 5975.1-5977.9)", backX, front, len, cab))
-- 4. a little darker
local function darker(p)
	if p:GetAttribute("Kimono6WasColor") == nil then p:SetAttribute("Kimono6WasColor", p.Color) end
	local c = p:GetAttribute("Kimono6WasColor")
	p.Color = Color3.new(c.R * DARK, c.G * DARK, c.B * DARK)
end
local nd = 0
for _, p in ipairs(f:GetDescendants()) do
	if p:IsA("BasePart") and (p.Name == "Central tatami runner" or p.Name == "Warm plaster rear wall" or p.Name == "Upper shoji paper panel") then darker(p); nd += 1 end
end
say(nd .. " parts a little darker (x" .. DARK .. "): the runner, the plaster rear wall, the shoji paper")
at:SetAttribute("AndMoreKimonosVersion", 6)
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after kimono6") end)
say("DONE - EDIT INSTALLED; NOT PUBLISHED")
return table.concat(out, "\n")
