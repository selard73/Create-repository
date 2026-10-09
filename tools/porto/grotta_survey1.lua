-- porto/grotta_survey1 v2 (job 31b): READ-ONLY, EDIT mode. Shannon: a pearl "somewhere in the back of the cave to find".
-- workspace.Grotta is a Folder (PolpoServer/Client, Glow, Cages, CameraStops, PolpoBrontolone). Prints the parts' box,
-- Polpo, the cages, the camera stops (the way in), then a floor grid cast DOWN FROM INSIDE the cave (start a little above
-- the cages' height) so the roof does not get in the way: material + floor height, W = water, . = nothing within 60 studs.
local G = workspace:FindFirstChild("Grotta")
if not G then warn("QQ GROTTA ABORT - no workspace.Grotta") return end
local lo, hi = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9)
local ys = {}
for _, d in ipairs(G:GetDescendants()) do
	if d:IsA("BasePart") then lo = lo:Min(d.Position - d.Size / 2); hi = hi:Max(d.Position + d.Size / 2) end
end
print(string.format("QQ GROTTA parts box x %.0f..%.0f y %.0f..%.0f z %.0f..%.0f", lo.X, hi.X, lo.Y, hi.Y, lo.Z, hi.Z))
for _, name in ipairs({"PolpoBrontolone", "Cages", "CameraStops", "Glow"}) do
	local f = G:FindFirstChild(name)
	if f then
		if f:IsA("PVInstance") then local p = f:GetPivot().Position; print(string.format("QQ GROTTA %s pivot %.0f,%.0f,%.0f", name, p.X, p.Y, p.Z)) end
		for _, c in ipairs(f:GetChildren()) do
			if c:IsA("PVInstance") then local p = c:GetPivot().Position; print(string.format("QQ GROTTA %s.%s (%s) at %.0f,%.0f,%.0f", name, c.Name, c.ClassName, p.X, p.Y, p.Z)); table.insert(ys, p.Y) end
		end
	end
end
local M = workspace:FindFirstChild("MapMusic")
if M then for k, v in pairs(M:GetAttributes()) do if tostring(k):lower():find("grotta") then print("QQ GROTTA MapMusic." .. k .. " = " .. tostring(v)) end end end
local startY = (#ys > 0 and math.min(table.unpack(ys)) or lo.Y) + 8
local CODE = {Sand = "S", Grass = "G", Rock = "R", Slate = "T", Limestone = "L", Water = "W", Ground = "D", Mud = "M", Basalt = "B", Sandstone = "N", Pavement = "P", Salt = "A"}
local params = RaycastParams.new(); params.IgnoreWater = false
local STEP, PAD = 5, 15
local x0, x1, z0, z1 = math.floor(lo.X) - PAD, math.ceil(hi.X) + PAD, math.floor(lo.Z) - PAD, math.ceil(hi.Z) + PAD
print(string.format("QQ GROTTA floor grid from y %.0f down 60, step %d", startY, STEP))
local head = "QQ GROTTA x:   "
for x = x0, x1, STEP do head ..= string.format("%5d", x) end
print(head)
for z = z0, z1, STEP do
	local row = string.format("QQ GROTTA z%5d", z)
	for x = x0, x1, STEP do
		local hit = workspace:Raycast(Vector3.new(x, startY, z), Vector3.new(0, -60, 0), params)
		if not hit then row ..= "    ."
		else
			local c = hit.Instance == workspace.Terrain and (CODE[hit.Material.Name] or hit.Material.Name:sub(1, 1)) or "p"
			row ..= string.format("%5s", c .. math.floor(hit.Position.Y + 0.5))
		end
	end
	print(row)
	task.wait()
end
