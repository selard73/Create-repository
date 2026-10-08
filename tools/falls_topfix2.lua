-- falls_topfix2 v2: CHANGES THE PLACE (three small corrections after falls_settle3). (0) The teal lumps at both corners in her low view are the river's own water end face, rounded by the voxel smoothing against the sandstone, seen through the translucent body now that the opaque roll is gone: the body beam is made nearly opaque (pale) over its top 8 studs, fading to its old see-through below. (1) The teal lump at the east corner in her
-- side view is Rock_20 (a forest-kit rock seated on the east bank 7.5 studs above the brink, blue-teal in the gorge's shadow)
-- and Rock_18 sits on the same bank 14 studs up: both are moved to ServerStorage.GorgeBackup.RapidsRocks_removed (not deleted)
-- so the sandstone shoulder is what shows at the corner. (2) The fall body's top was tinted teal and read as a band from the
-- side: it is pale now, like the rest of the body.
local G = workspace.SouthGorge
local SS = game:GetService("ServerStorage")
local GB = SS:FindFirstChild("GorgeBackup") or Instance.new("Folder", SS); GB.Name = "GorgeBackup"
local store = GB:FindFirstChild("RapidsRocks_removed") or Instance.new("Folder", GB); store.Name = "RapidsRocks_removed"
local moved = {}
local R = G:FindFirstChild("RapidsRocks")
if R then
	for _, p in ipairs(R:GetChildren()) do
		if p:IsA("BasePart") and p.Position.Z < -530 and p.Position.X > 200 then      -- the east bank within ~17 studs of the brink
			moved[#moved + 1] = string.format("%s (%.1f, %.1f, %.1f)", p.Name, p.Position.X, p.Position.Y, p.Position.Z)
			p.Parent = store
		end
	end
end
local back = G.FallsB.Rig:FindFirstChild("Back")
if back then
	back.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(196, 226, 232)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(182, 216, 228)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 228, 236))})
	back.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.06), NumberSequenceKeypoint.new(0.12, 0.1), NumberSequenceKeypoint.new(0.22, 0.4), NumberSequenceKeypoint.new(0.7, 0.5), NumberSequenceKeypoint.new(0.9, 0.85), NumberSequenceKeypoint.new(1, 1)})
end
print(string.format("QQ TF2 moved %d rocks: %s; body top pale and opaque (tr %.2f at the top)", #moved, table.concat(moved, "; "), back and back.Transparency.Keypoints[1].Value or -1))
print("QQ TF2 DONE")
