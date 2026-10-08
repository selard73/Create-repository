-- gorge_place4: CHANGES THE PLACE (the gorge's end: headwall + cave, Sep 30 evening): removes the four old end wall
-- pieces (W08, E08, W09, E09) from workspace.SouthGorge.Rock and places the freshly imported end pieces
-- (workspace.end_roblox): the same four regenerated, the headwall, the cave tunnel and its dark back. Sizes are checked
-- against the file first; nothing changes unless all seven match. Scenery only (anchored, no collision, Plastic).
local END = {{"CaveBack", 183.8438, 1.5000, -565.6489, 8.00, 7.00, 7.50},{"SouthRock_Cave", 183.8438, 1.5000, -565.8989, 8.00, 7.00, 7.00},{"SouthRock_E08", 220.9432, 18.1447, -520.5000, 32.43, 52.29, 39.00},{"SouthRock_E09", 212.3997, 16.5497, -543.7500, 26.14, 49.10, 7.50},{"SouthRock_End", 184.6526, 16.3594, -565.0326, 69.06, 48.72, 35.07},{"SouthRock_W08", 170.4084, 18.1447, -520.5000, 34.13, 52.29, 39.00},{"SouthRock_W09", 161.8676, 16.5497, -543.7500, 23.49, 49.10, 7.50}}
local src = workspace:FindFirstChild("end_roblox")
assert(src, "imported end_roblox model not found - run Import 3D first")
local bad = {}
for _, e in ipairs(END) do
	local p = src:FindFirstChild(e[1], true)
	if not p then table.insert(bad, e[1] .. " missing")
	elseif (p.Size - Vector3.new(e[5], e[6], e[7])).Magnitude > 0.2 then table.insert(bad, string.format("%s size %s vs %.2f,%.2f,%.2f", e[1], tostring(p.Size), e[5], e[6], e[7])) end
end
if #bad > 0 then print("QQ P4 STOP (nothing changed):", table.concat(bad, " | ")) return end
local G = workspace.SouthGorge; local fR = G.Rock
local removed = 0
for _, n in ipairs({"SouthRock_W08", "SouthRock_E08", "SouthRock_W09", "SouthRock_E09"}) do
	local old = fR:FindFirstChild(n); if old then old:Destroy(); removed += 1 end
end
for _, e in ipairs(END) do
	local p = src:FindFirstChild(e[1], true)
	p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false; p.CastShadow = true
	pcall(function() p.CollisionFidelity = Enum.CollisionFidelity.Box end)
	p.Material = Enum.Material.Plastic
	if e[1] == "CaveBack" then p.Color = Color3.fromRGB(14, 12, 11); p.Material = Enum.Material.SmoothPlastic end
	p.CFrame = CFrame.new(e[2], e[3], e[4])
	p.Parent = fR
end
if #src:GetChildren() == 0 then src:Destroy() end
G:SetAttribute("EndVersion", "headwall + cave mouth, Sep 30 2026")
print(string.format("QQ P4 removed %d old end pieces, placed %d; rock pieces now %d; import model removed: %s", removed, #END, #fR:GetChildren(), tostring(workspace:FindFirstChild("end_roblox") == nil)))
print("QQ P4 DONE")
