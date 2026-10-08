-- t31_srv.lua v1 (PLAY, SERVER view): are the squirrels solid now? - how many are, then walk the character straight at the
-- nearest one and see where it stops; then a hands-off glider flight (the settle now starts where the pilot saw it)
local RS = game:GetService("RunService")
if not RS:IsServer() or not RS:IsRunning() then warn("QQ T31 ABORT - Play, server view") return end
local CS = game:GetService("CollectionService")
local p = game.Players:GetPlayers()[1]
local Registry = require(workspace.SquirrelScripts.SquirrelRegistry)
local total = {}
for _, e in ipairs(Registry.squirrels) do total[e.map] = (total[e.map] or 0) + 1 end
p:SetAttribute("Found_forest", total.forest); p:SetAttribute("Found_village", total.village); p:SetAttribute("Item_glider", 1)
local char = p.Character
local hrp = char.HumanoidRootPart
local solid, soft, best, bd = 0, 0, nil, nil
for _, m in ipairs(CS:GetTagged("Squirrel")) do
	local all = true
	for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") and d.Name ~= "NameTagAnchor" and not d.CanCollide then all = false end end
	if all then solid += 1 else soft += 1 end
	local cf, size = m:GetBoundingBox()
	local dist = (cf.Position - hrp.Position).Magnitude
	if size.Y < 4 and (not bd or dist < bd) then best, bd = m, dist end
end
local walk = "no squirrel to walk into"
if best then
	local cf = best:GetBoundingBox()
	local target = cf.Position
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {char}
	for _, dir in ipairs({Vector3.xAxis, -Vector3.xAxis, Vector3.zAxis, -Vector3.zAxis}) do
		local from = target + dir * 8
		local hit = workspace:Raycast(from, target - from, rp)
		local g = workspace:Raycast(from + Vector3.new(0, 20, 0), Vector3.new(0, -60, 0), rp)
		if hit and hit.Instance:IsDescendantOf(best) and g then
			local at = g.Position + Vector3.new(0, 3.2, 0)
			char:PivotTo(CFrame.lookAt(at, Vector3.new(target.X, at.Y, target.Z)))
			task.wait(0.6)
			char.Humanoid:MoveTo(Vector3.new(target.X, g.Position.Y, target.Z))
			task.wait(3.5)
			local flat = ((hrp.Position - target) * Vector3.new(1, 0, 1)).Magnitude
			walk = string.format("walked at %s: stopped %.1f studs short of its middle (feet %.1f above the ground there)", best.Name, flat, hrp.Position.Y - 3.2 - g.Position.Y)
			break
		end
	end
end
warn(string.format("QQ T31 v1 - squirrels solid %d, not solid %d | %s", solid, soft, walk))
-- the flight
local G = workspace.HangGlider
local back = Vector3.new(G:GetAttribute("RampX"), G:GetAttribute("RampY") + 3.4, G:GetAttribute("RampZ"))
local dir = Vector3.new(G:GetAttribute("RampDirX"), 0, G:GetAttribute("RampDirZ"))
local at = back - dir * 1.5
char:PivotTo(CFrame.lookAt(at, at + dir))
task.wait(0.6)
G.GliderDebugStart:Fire(p)
local m = G.Landed:WaitForChild(tostring(p.UserId), 40)
if not m then warn("QQ T31 v1 - no landed glider") return end
task.wait(1.3)
local piv = m:GetPivot()
warn(string.format("QQ T31 v1 - landed glider at (%.1f, %.1f, %.1f), pilot %.1f away, streaming %s", piv.X, piv.Y, piv.Z,
	(piv.Position - hrp.Position).Magnitude, tostring(m.ModelStreamingMode)))
