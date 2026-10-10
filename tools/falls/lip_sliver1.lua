-- lip_sliver1.lua (Studio EDIT mode; re-runnable). Job 86: the sliver at the lip's right corner.
-- After job 85 (two clumps, no terrain water left in sight) Shannon asked for "the sliver too": a thin blue line between
-- LipRockW's underside (y -7.3) and LipClump_1's top (about y -7.05) at the sheet's west edge, x 167-168 (runner 4's picture
-- lip-j85-preview-c4.jpg). No terrain water is there; it is the pale LipPlate (colour 212,236,240, x from 167.4) seen
-- through that gap. One more small clump of the same rock sits in the gap, and the plate's west end gets the sheet's white
-- so a hairline of it reads as foam, not water. Undo: delete LipRocks.LipClump_3; LipPlate.Color from its ColorWas attribute.
local SG = workspace:FindFirstChild("SouthGorge"); local LR = SG and SG:FindFirstChild("LipRocks")
local tpl = LR and LR:FindFirstChild("LipRockW")
if not tpl then print("QQ SLIVER ABORT: SouthGorge.LipRocks.LipRockW not found") return end
local old = LR:FindFirstChild("LipClump_3"); if old then old:Destroy() end
local c = tpl:Clone(); c.Name = "LipClump_3"
for _, d in ipairs(c:GetDescendants()) do if d:IsA("LuaSourceContainer") then d:Destroy() end end
c.Size = tpl.Size * 0.38                                   -- about (4.4, 2.7, 3.3)
c.CFrame = CFrame.new(167.4, -7.1, -550.4) * CFrame.Angles(0.25, 2.1, -0.2)   -- in the gap, a touch in front of the plate
c.Anchored = true; c.CanCollide = false; c.CanQuery = true; c.CanTouch = false; c.Parent = LR
local FB = SG:FindFirstChild("FallsB"); local plate = FB and FB:FindFirstChild("LipPlate")
local plateNote = "no LipPlate"
if plate then
	if plate:GetAttribute("ColorWas") == nil then plate:SetAttribute("ColorWas", plate.Color) end
	plate.Color = Color3.fromRGB(246, 250, 252)
	plateNote = string.format("LipPlate colour %s (was %s)", tostring(plate.Color), tostring(plate:GetAttribute("ColorWas")))
end
print(string.format("QQ SLIVER DONE: LipClump_3 at %s size %s; %s", tostring(c.Position), tostring(c.Size), plateNote))
