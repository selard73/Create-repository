-- t28_srv.lua v3 (PLAY, SERVER view): ride the basket lift - the Chateau open (Studio only; v1 forgot, and the gate sent
-- the test character back to the Rue the moment it landed), on the terrace behind the basket, then the Studio debug start; follows the rider and the basket every second until the basket is back at the top
local RS = game:GetService("RunService")
if not RS:IsServer() or not RS:IsRunning() then warn("QQ T28 ABORT - Play, server view") return end
local p = game.Players:GetPlayers()[1]
local Registry = require(workspace.SquirrelScripts.SquirrelRegistry)
local total = {}
for _, e in ipairs(Registry.squirrels) do total[e.map] = (total[e.map] or 0) + 1 end
p:SetAttribute("Found_forest", total.forest); p:SetAttribute("Found_village", total.village)
local L = workspace.BasketLift
local rest = L.Basket:GetPivot()
local at = rest.Position + Vector3.new(0.5, 3.2, -5.5)
p.Character:PivotTo(CFrame.lookAt(at, at + Vector3.new(0, 0, 1)))
task.wait(0.8)
L.LiftDebugStart:Fire(p)
warn("QQ T28 v3 - ride started")
local t0 = os.clock()
for i = 1, 24 do
	task.wait(1)
	local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	local b = L.Basket:GetPivot().Position
	print(string.format("QQ T28 v3 t%.0f rider (%.1f, %.1f, %.1f) | basket y %.1f anchored %s | busy %s", os.clock() - t0,
		hrp and hrp.Position.X or 0, hrp and hrp.Position.Y or -1, hrp and hrp.Position.Z or 0, b.Y, tostring(L.Basket.Floor.Anchored), tostring(L:GetAttribute("Busy"))))
	if not L:GetAttribute("Busy") and i > 3 then break end
end
warn("QQ T28 v3 - done, busy " .. tostring(L:GetAttribute("Busy")) .. ", prompt " .. tostring(L.Basket.Floor.RideDown.Enabled)
	.. ", basket at top " .. tostring((L.Basket:GetPivot().Position - rest.Position).Magnitude < 0.05) .. ", floor solid " .. tostring(L.Basket.Floor.CanCollide))
