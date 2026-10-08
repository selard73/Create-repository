-- Tilts the dish assembly 14 degrees more upward about its joint. Run once in the Command Bar
-- with the dish in Workspace (named SatelliteDish or dish). Run again for another 14 degrees.
local model = workspace:FindFirstChild("SatelliteDish") or workspace:FindFirstChild("dish") or game.Selection:Get()[1]
assert(model and model:IsA("Model"), "Select the SatelliteDish model first")
local joint = model:FindFirstChild("Joint"); assert(joint, "no Joint part in the model")
local yaw = math.rad(25)
local axis = Vector3.new(math.cos(yaw), 0, -math.sin(yaw))
local rot = CFrame.fromAxisAngle(axis, math.rad(-14))
local pivot = joint.Position
local names = { Dish = true, DishRim = true, Hub = true, FeedRod = true, NeonYellow_FeedTip = true, Counterweight = true }
local n = 0
for _, p in ipairs(model:GetDescendants()) do
	if p:IsA("BasePart") and (names[p.Name] or p.Name:match("^DishRib") or p.Name:match("^Strut")) then
		p.CFrame = CFrame.new(pivot) * rot * CFrame.new(-pivot) * p.CFrame
		n += 1
	end
end
print("dish tilted up:", n, "pieces rotated")
