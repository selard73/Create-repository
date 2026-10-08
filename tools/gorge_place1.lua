-- gorge_place1: CHANGES THE PLACE (Shannon's yes for step 3, Sep 30 ~17:10): moves the imported rock and aqueduct
-- pieces into workspace.SouthGorge and puts each exactly where it belongs (centres from gorge_real/gorge_data.json).
-- Scenery only: anchored, no collision, no touch, no queries. Checks every piece's size against the file first.
local ROCK = {{"SouthRock_E01", 207.0647, 12.8303, -247.5000, 38.47, 41.66, 39.00},{"SouthRock_E02", 204.9437, 15.6291, -286.5000, 44.77, 47.26, 39.00},{"SouthRock_E03", 172.8328, 18.4570, -325.5000, 57.50, 52.91, 39.00},{"SouthRock_E04", 150.6641, 18.4176, -364.5000, 30.73, 52.84, 39.00},{"SouthRock_E05", 151.3849, 16.9719, -403.5000, 26.12, 49.94, 39.00},{"SouthRock_E06", 174.3346, 15.7492, -442.5000, 58.93, 47.50, 39.00},{"SouthRock_E07", 209.9263, 18.1430, -481.5000, 49.75, 52.29, 39.00},{"SouthRock_E08", 218.4669, 18.1430, -520.5000, 38.32, 52.29, 39.00},{"SouthRock_E09", 191.8273, 16.5495, -552.7500, 50.03, 49.10, 25.50},{"SouthRock_W01", 165.7317, 12.8303, -247.5000, 29.13, 41.66, 39.00},{"SouthRock_W02", 155.6658, 17.7055, -286.5000, 48.89, 51.41, 39.00},{"SouthRock_W03", 122.5946, 17.7437, -325.5000, 62.53, 51.49, 39.00},{"SouthRock_W04", 86.9644, 16.2999, -364.5000, 51.88, 48.60, 39.00},{"SouthRock_W05", 91.8644, 16.2999, -403.5000, 62.38, 48.60, 39.00},{"SouthRock_W06", 132.1133, 19.0917, -442.5000, 57.49, 54.18, 39.00},{"SouthRock_W07", 163.7099, 19.1116, -481.5000, 47.77, 54.22, 39.00},{"SouthRock_W08", 174.4947, 18.1430, -520.5000, 27.89, 52.29, 39.00},{"SouthRock_W09", 168.6631, 16.5495, -552.7500, 21.51, 49.10, 25.50}}
local AQ = {{"AqArch", 110.0000, 20.0171, -384.0000, 54.60, 28.13, 10.60},{"AqCap", 110.0000, 42.4500, -384.0000, 107.20, 3.70, 7.20},{"AqKnob", 110.0000, 14.2000, -384.0000, 26.70, 17.00, 11.10},{"AqLedge", 110.0000, 27.0000, -384.0000, 88.00, 15.60, 10.80},{"AqStone", 110.0000, 16.8000, -382.5000, 107.20, 51.60, 13.00}}
local COL = {AqArch = Color3.fromRGB(198, 156, 100), AqLedge = Color3.fromRGB(228, 198, 148), AqCap = Color3.fromRGB(206, 186, 150), AqKnob = Color3.fromRGB(192, 150, 98)}
local srcR, srcA = workspace:FindFirstChild("rock_roblox"), workspace:FindFirstChild("aqueduct_roblox")
assert(srcR and srcA, "imported models not found")
-- size check first: nothing moves unless every piece matches its file
local bad = {}
local function check(list, src)
	for _, e in ipairs(list) do
		local p = src:FindFirstChild(e[1], true)
		if not p then table.insert(bad, e[1] .. " missing")
		elseif (p.Size - Vector3.new(e[5], e[6], e[7])).Magnitude > 0.2 then table.insert(bad, string.format("%s size %s vs %.2f,%.2f,%.2f", e[1], tostring(p.Size), e[5], e[6], e[7])) end
	end
end
check(ROCK, srcR); check(AQ, srcA)
if #bad > 0 then print("QQ P1 STOP (nothing moved):", table.concat(bad, " | ")) return end
local G = workspace:FindFirstChild("SouthGorge") or Instance.new("Folder")
G.Name = "SouthGorge"
G:SetAttribute("Built", "Sep 30 2026 - step 3 of the south gorge build (rock + aqueduct)")
G:SetAttribute("Source", "roblox-props/italy/gorge_real (gen_gorge_real.py, gorge_data.json)")
G.Parent = workspace
local function folder(name) local f = G:FindFirstChild(name) or Instance.new("Folder"); f.Name = name; f.Parent = G; return f end
local fR, fA = folder("Rock"), folder("Aqueduct")
local function place(list, src, dest)
	for _, e in ipairs(list) do
		local p = src:FindFirstChild(e[1], true)
		p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false; p.CastShadow = true
		pcall(function() p.CollisionFidelity = Enum.CollisionFidelity.Box end)
		p.Material = Enum.Material.SmoothPlastic
		if COL[e[1]] then p.Color = COL[e[1]] end
		p.CFrame = CFrame.new(e[2], e[3], e[4])
		p.Parent = dest
	end
end
place(ROCK, srcR, fR); place(AQ, srcA, fA)
local leftR, leftA = #srcR:GetChildren(), #srcA:GetChildren()
if leftR == 0 then srcR:Destroy() end
if leftA == 0 then srcA:Destroy() end
print(string.format("QQ P1 placed rock %d, aqueduct %d; import models removed: %s %s", #fR:GetChildren(), #fA:GetChildren(), tostring(leftR == 0), tostring(leftA == 0)))
print("QQ P1 DONE")
