-- One-time repair for a UFO whose saucer and pad drifted apart. Select the UFO model, paste, Enter.
-- Moves the saucer, beam and sparkles so they sit centred above the pad again, and the pad
-- accessories (ring, lamps, consoles) back onto the pad base. Then run ufo_setup.lua once more.
local model = workspace:FindFirstChild("UFO") or game.Selection:Get()[1]
assert(model and model:IsA("Model"), "Select the UFO model first")
local padBase = model:FindFirstChild("PadBase"); local hull = model:FindFirstChild("UfoHull")
assert(padBase and hull, "model needs PadBase and UfoHull")
local padTop = padBase.Position.Y + padBase.Size.Y / 2
-- saucer group: everything not named Pad*, moved by one delta so it stays intact
local targetHull = Vector3.new(padBase.Position.X, padTop - 1.7 + 17.0, padBase.Position.Z)
local delta = targetHull - hull.Position
local n = 0
for _, p in ipairs(model:GetDescendants()) do
	if p:IsA("BasePart") and not p.Name:find("Pad") then p.CFrame = p.CFrame + delta; n += 1 end
end
-- pad accessories: move by the disc's offset so they sit on the base again
local disc = model:FindFirstChild("NeonLime_PadDisc")
if disc then
	local d2 = Vector3.new(padBase.Position.X, padTop + 0.035, padBase.Position.Z) - disc.Position
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p.Name:find("Pad") and p ~= padBase then p.CFrame = p.CFrame + d2; n += 1 end
	end
end
-- re-record home positions so the game snaps to THIS layout, not an older one
for _, p in ipairs(model:GetDescendants()) do
	if p:IsA("BasePart") and p ~= padBase then p:SetAttribute("HomeOffset", padBase.CFrame:ToObjectSpace(p.CFrame)) end
end
print("UFO reassembled over the pad:", n, "pieces moved, home positions re-recorded.")
