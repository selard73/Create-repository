-- gorge_place3: CHANGES THE PLACE (replacing the rock after the mesh fix, Sep 30 evening): removes the 18 old rock
-- pieces from workspace.SouthGorge.Rock, then places the freshly imported ones (workspace.rock_roblox) exactly, scenery
-- only (anchored, no collision, Plastic like the Sandstone Climb). Checks every piece's size against the new file first;
-- nothing is removed or moved unless all 18 match. The aqueduct and trees are not touched.
local ROCK = {{"SouthRock_E01", 207.0599, 12.8310, -247.5000, 38.48, 41.66, 39.00},{"SouthRock_E02", 204.9419, 15.6296, -286.5000, 44.77, 47.26, 39.00},{"SouthRock_E03", 172.8335, 18.4575, -325.5000, 57.50, 52.92, 39.00},{"SouthRock_E04", 150.6592, 18.4176, -364.5000, 30.74, 52.84, 39.00},{"SouthRock_E05", 151.3786, 16.9719, -403.5000, 26.14, 49.94, 39.00},{"SouthRock_E06", 174.3309, 15.7499, -442.5000, 58.94, 47.50, 39.00},{"SouthRock_E07", 209.9260, 18.1447, -481.5000, 49.75, 52.29, 39.00},{"SouthRock_E08", 218.4667, 18.1447, -520.5000, 38.32, 52.29, 39.00},{"SouthRock_E09", 191.8250, 16.5497, -552.7500, 50.03, 49.10, 25.50},{"SouthRock_W01", 165.7340, 12.8310, -247.5000, 29.13, 41.66, 39.00},{"SouthRock_W02", 155.6674, 17.7055, -286.5000, 48.89, 51.41, 39.00},{"SouthRock_W03", 122.5911, 17.7441, -325.5000, 62.52, 51.49, 39.00},{"SouthRock_W04", 86.9696, 16.3000, -364.5000, 51.89, 48.60, 39.00},{"SouthRock_W05", 91.8671, 16.3000, -403.5000, 62.39, 48.60, 39.00},{"SouthRock_W06", 132.1134, 19.0919, -442.5000, 57.49, 54.18, 39.00},{"SouthRock_W07", 163.7071, 19.1117, -481.5000, 47.76, 54.22, 39.00},{"SouthRock_W08", 174.4949, 18.1447, -520.5000, 27.89, 52.29, 39.00},{"SouthRock_W09", 168.6639, 16.5497, -552.7500, 21.52, 49.10, 25.50}}
local src = workspace:FindFirstChild("rock_roblox")
assert(src, "imported rock_roblox model not found - run Import 3D first")
local bad = {}
for _, e in ipairs(ROCK) do
	local p = src:FindFirstChild(e[1], true)
	if not p then table.insert(bad, e[1] .. " missing")
	elseif (p.Size - Vector3.new(e[5], e[6], e[7])).Magnitude > 0.2 then table.insert(bad, string.format("%s size %s vs %.2f,%.2f,%.2f", e[1], tostring(p.Size), e[5], e[6], e[7])) end
end
if #bad > 0 then print("QQ P3 STOP (nothing changed):", table.concat(bad, " | ")) return end
local G = workspace:FindFirstChild("SouthGorge"); assert(G, "SouthGorge missing")
local fR = G:FindFirstChild("Rock") or Instance.new("Folder"); fR.Name = "Rock"; fR.Parent = G
local removed = 0
for _, old in ipairs(fR:GetChildren()) do old:Destroy(); removed += 1 end
for _, e in ipairs(ROCK) do
	local p = src:FindFirstChild(e[1], true)
	p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false; p.CastShadow = true
	pcall(function() p.CollisionFidelity = Enum.CollisionFidelity.Box end)
	p.Material = Enum.Material.Plastic
	p.CFrame = CFrame.new(e[2], e[3], e[4])
	p.Parent = fR
end
if #src:GetChildren() == 0 then src:Destroy() end
G:SetAttribute("RockVersion", "v2 Sep 30 (same rows per column - no stray triangles)")
print(string.format("QQ P3 removed %d old pieces, placed %d new; import model removed: %s", removed, #fR:GetChildren(), tostring(workspace:FindFirstChild("rock_roblox") == nil)))
print("QQ P3 DONE")
