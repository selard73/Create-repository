-- porto/grotta_survey1 (job 31b): READ-ONLY, EDIT mode. Shannon: a pearl "somewhere in the back of the cave to find".
-- Prints the Grotta's bounding box, Polpo and the cages, and a floor grid inside it (material + height, W = water, . = no floor)
-- so the pearl's spot at the back can be chosen. Output lines "QQ GROTTA".
local G = workspace:FindFirstChild("Grotta")
if not G then warn("QQ GROTTA ABORT - no workspace.Grotta") return end
local cf, size = G:GetBoundingBox()
print(string.format("QQ GROTTA bbox centre %.0f,%.0f,%.0f size %.0f x %.0f x %.0f", cf.Position.X, cf.Position.Y, cf.Position.Z, size.X, size.Y, size.Z))
for _, d in ipairs(G:GetDescendants()) do
	local n = d.Name:lower()
	if (d:IsA("Model") or d:IsA("BasePart")) and (n:find("polpo") or n:find("octopus") or n:find("cage") or n:find("entrance") or n:find("spawn") or n:find("pearl") or n:find("treasure") or n:find("chest")) then
		local p = d:GetPivot().Position
		print(string.format("QQ GROTTA %s (%s) at %.0f,%.0f,%.0f", d:GetFullName():sub(#"Workspace.Grotta." + 1), d.ClassName, p.X, p.Y, p.Z))
	end
end
local M = workspace:FindFirstChild("MapMusic")
if M then for k, v in pairs(M:GetAttributes()) do if tostring(k):lower():find("grotta") then print("QQ GROTTA MapMusic." .. k .. " = " .. tostring(v)) end end end
local CODE = {Sand = "S", Grass = "G", Rock = "R", Slate = "T", Limestone = "L", Water = "W", Ground = "D", Mud = "M", Basalt = "B", Sandstone = "N", CrackedLava = "C", Pavement = "P"}
local params = RaycastParams.new(); params.IgnoreWater = false
local STEP = 6
local lo, hi = cf.Position - size / 2, cf.Position + size / 2
local head = "QQ GROTTA x:   "
for x = lo.X, hi.X, STEP do head ..= string.format("%5d", math.floor(x)) end
print(head)
for z = lo.Z, hi.Z, STEP do
	local row = string.format("QQ GROTTA z%5d", math.floor(z))
	for x = lo.X, hi.X, STEP do
		local hit = workspace:Raycast(Vector3.new(x, hi.Y + 5, z), Vector3.new(0, -(size.Y + 20), 0), params)
		if not hit then row ..= "    ."
		else
			local c = hit.Instance == workspace.Terrain and (CODE[hit.Material.Name] or hit.Material.Name:sub(1, 1)) or "p"
			row ..= string.format("%5s", c .. math.floor(hit.Position.Y + 0.5))
		end
	end
	print(row)
	task.wait()
end
