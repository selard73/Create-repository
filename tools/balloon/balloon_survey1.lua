-- balloon/balloon_survey1 (job 22): READ-ONLY, EDIT mode. Shannon, Oct 9: the empty far shore across the harbour becomes
-- the hot air balloon field (ambient balloons; the player's own balloon after all 44 Porto squirrels, the way to the next
-- map). Before running, Shannon points the Studio camera at the middle of the spot (or selects a part there).
-- Prints the centre, a 13 x 13 grid (10 studs apart) of ground height + material, and every model built in the area.
-- Codes: S sand, G grass, L leafy grass, R rock, D ground, M mud, N sandstone, T slate, W water (height = surface),
-- P = a part (not terrain) is on top, ? = nothing below. Output lines start with "QQ BAL".
local sel = game:GetService("Selection"):Get()[1]
local centre
if sel and sel:IsA("PVInstance") then
	centre = sel:GetPivot().Position
	print("QQ BAL centre from the selection: " .. sel:GetFullName())
else
	local cam = workspace.CurrentCamera
	local hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 3000)
	if not hit then warn("QQ BAL ABORT - the camera is not looking at anything; aim it at the spot or select a part there") return end
	centre = hit.Position
	print(string.format("QQ BAL centre from the camera (at %.0f,%.0f,%.0f)", cam.CFrame.Position.X, cam.CFrame.Position.Y, cam.CFrame.Position.Z))
end
print(string.format("QQ BAL centre %.1f, %.1f, %.1f", centre.X, centre.Y, centre.Z))
local CODE = {Sand = "S", Grass = "G", LeafyGrass = "L", Rock = "R", Ground = "D", Mud = "M", Sandstone = "N", Slate = "T", Water = "W"}
local params = RaycastParams.new(); params.IgnoreWater = false
local STEP, N = 10, 6
local head = "QQ BAL x:     "
for i = -N, N do head ..= string.format("%6d", math.floor(centre.X + i * STEP)) end
print(head)
for j = -N, N do
	local z = centre.Z + j * STEP
	local row = string.format("QQ BAL z %5d:", math.floor(z))
	for i = -N, N do
		local x = centre.X + i * STEP
		local hit = workspace:Raycast(Vector3.new(x, centre.Y + 300, z), Vector3.new(0, -800, 0), params)
		if not hit then row ..= "     ?"
		else
			local c = hit.Instance == workspace.Terrain and (CODE[hit.Material.Name] or hit.Material.Name:sub(1, 2)) or "P"
			row ..= string.format("%6s", c .. math.floor(hit.Position.Y + 0.5))
		end
	end
	print(row)
end
-- what is built in the area (top-level models under workspace and under workspace.PortoNocciola)
local half = STEP * N + 5
local seen = 0
local function check(m)
	if not (m:IsA("Model") or m:IsA("BasePart")) then return end
	local ok, cf, size = pcall(function() if m:IsA("Model") then return m:GetBoundingBox() end return m.CFrame, m.Size end)
	if not ok or not cf then return end
	local p = cf.Position
	if math.abs(p.X - centre.X) - size.X / 2 < half and math.abs(p.Z - centre.Z) - size.Z / 2 < half and size.Magnitude < 2000 then
		seen += 1
		if seen <= 25 then print(string.format("QQ BAL built: %s | centre %.0f,%.0f,%.0f | size %.0fx%.0fx%.0f", m:GetFullName(), p.X, p.Y, p.Z, size.X, size.Y, size.Z)) end
	end
end
for _, m in ipairs(workspace:GetChildren()) do if m ~= workspace.Terrain and m.Name ~= "PortoNocciola" then check(m) end end
local porto = workspace:FindFirstChild("PortoNocciola")
if porto then for _, m in ipairs(porto:GetChildren()) do check(m) end end
print(string.format("QQ BAL %d models/parts overlap the %d x %d area", seen, half * 2, half * 2))
