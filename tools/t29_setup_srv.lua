-- t29_setup_srv.lua v1 (PLAY, SERVER view): Shannon's test of the rainbow glider and the basket lift - gates open, the
-- glider already hers and 1500 acorns (Studio only, never saved), standing on the summit terrace between the launch arch
-- and the basket lift's hoist, facing the valley
local RS = game:GetService("RunService")
if not RS:IsServer() or not RS:IsRunning() then warn("QQ T29 ABORT - Play, server view") return end
local p = game.Players:GetPlayers()[1]
local Registry = require(workspace.SquirrelScripts.SquirrelRegistry)
local total = {}
for _, e in ipairs(Registry.squirrels) do total[e.map] = (total[e.map] or 0) + 1 end
p:SetAttribute("Found_forest", total.forest); p:SetAttribute("Found_village", total.village)
p:SetAttribute("Item_glider", 1)
p:SetAttribute("Acorns", 1500)
local rest = workspace.BasketLift.Basket:GetPivot().Position
local at = Vector3.new(rest.X + 1.5, rest.Y + 3.2, rest.Z - 5.6)
p.Character:PivotTo(CFrame.lookAt(at, at + Vector3.new(0, 0, 1)))
warn(string.format("QQ T29 v1 - on the summit at (%.1f, %.1f, %.1f) | acorns %s | glider %s", at.X, at.Y, at.Z,
	tostring(p:GetAttribute("Acorns")), tostring(p:GetAttribute("Item_glider"))))
