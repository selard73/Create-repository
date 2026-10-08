-- t27_srv.lua v7 (PLAY, SERVER view): a hands-off glider flight to test the landing - the glider should stay where it
-- came down: gates open, glider owned (Studio only, never saved), on the ramp, take off by the Studio debug start
local RS = game:GetService("RunService")
if not RS:IsServer() or not RS:IsRunning() then warn("QQ T27 ABORT - Play, server view") return end
local p = game.Players:GetPlayers()[1]
local Registry = require(workspace.SquirrelScripts.SquirrelRegistry)
local total = {}
for _, e in ipairs(Registry.squirrels) do total[e.map] = (total[e.map] or 0) + 1 end
p:SetAttribute("Found_forest", total.forest); p:SetAttribute("Found_village", total.village)
p:SetAttribute("Item_glider", 1)
local G = workspace.HangGlider
G:SetAttribute("LingerSeconds", 20)                  -- (as live)
local back = Vector3.new(G:GetAttribute("RampX"), G:GetAttribute("RampY") + 3.4, G:GetAttribute("RampZ"))
local dir = Vector3.new(G:GetAttribute("RampDirX"), 0, G:GetAttribute("RampDirZ"))
local at = back - dir * 1.5
p.Character:PivotTo(CFrame.lookAt(at, at + dir))
local prev = G.Landed:FindFirstChild(tostring(p.UserId)); if prev then prev:Destroy() end   -- (the last test's)
task.wait(0.6)
G.GliderDebugStart:Fire(p)
warn("QQ T27 v7 - took off")
local landed = G:WaitForChild("Landed")
local m = landed:WaitForChild(tostring(p.UserId), 60)
if not m then warn("QQ T27 v7 - no landed glider after 60 s") return end
task.wait((m:GetAttribute("T1") or 0) + (m:GetAttribute("T2") or 0) + 0.4)
local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
local piv = m:GetPivot()
local n, anchored = 0, 0
for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then n += 1; if d.Anchored then anchored += 1 end end end
warn(string.format("QQ T27 v7 - landed glider at (%.1f, %.1f, %.1f) look (%.2f, %.2f, %.2f), pilot at (%.1f, %.1f, %.1f), %.1f apart | T1 %.2f T2 %.2f drop %s | %d parts, %d anchored",
	piv.X, piv.Y, piv.Z, piv.LookVector.X, piv.LookVector.Y, piv.LookVector.Z, hrp.Position.X, hrp.Position.Y, hrp.Position.Z,
	(piv.Position - hrp.Position).Magnitude, m:GetAttribute("T1"), m:GetAttribute("T2"), tostring(m:GetAttribute("Drop")), n, anchored))
