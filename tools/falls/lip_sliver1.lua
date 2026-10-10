-- lip_sliver1.lua (Studio EDIT mode; re-runnable). Job 86: the sliver at the lip's right corner.
-- After job 85 (two clumps, no terrain water left in sight) Shannon asked for "the sliver too": a thin blue line between
-- LipRockW's underside (y -7.3) and LipClump_1's top (about y -7.05) at the sheet's west edge, x 167-168 (runner 4's picture
-- lip-j85-preview-c4.jpg). Runner 5's rays (play test): it IS the river's terrain water, standing 0.2-0.5 in front of the
-- plate's face at x 168.3..169.2, y -6..-7, inside the sheet's x range (job 85's stand-in hid it from the count). One more
-- small clump of the same rock sits over that spot. Undo: delete LipRocks.LipClump_3. (The plate is left alone.)
local SG = workspace:FindFirstChild("SouthGorge"); local LR = SG and SG:FindFirstChild("LipRocks")
local tpl = LR and LR:FindFirstChild("LipRockW")
if not tpl then print("QQ SLIVER ABORT: SouthGorge.LipRocks.LipRockW not found") return end
local old = LR:FindFirstChild("LipClump_3"); if old then old:Destroy() end
local c = tpl:Clone(); c.Name = "LipClump_3"
for _, d in ipairs(c:GetDescendants()) do if d:IsA("LuaSourceContainer") then d:Destroy() end end
c.Size = tpl.Size * 0.46                                   -- about (5.3, 3.3, 4.0)
c.CFrame = CFrame.new(168.2, -7.0, -550.3) * CFrame.Angles(0.25, 2.1, -0.2)   -- over the water at x 168.3..169.2, a touch in front of it
c.Anchored = true; c.CanCollide = false; c.CanQuery = true; c.CanTouch = false; c.Parent = LR
print(string.format("QQ SLIVER DONE: LipClump_3 at %s size %s", tostring(c.Position), tostring(c.Size)))
