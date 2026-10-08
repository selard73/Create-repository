-- tt_go_cli v1 (PLAY, Client tab): TEST ONLY. Holds the nearest travel board's prompt for this client (as a player would),
-- then reports where the character ended up 3.5 s later. No camera moves before the hold (a Scriptable camera stops prompts).
local Players = game:GetService("Players")
local p = Players.LocalPlayer
local char = p.Character
local root = char and char:FindFirstChild("HumanoidRootPart")
if not root then print("QQ TGO no character"); return end
local T = workspace:FindFirstChild("Travel")
local best, bd
for _, d in ipairs(T and T:GetDescendants() or {}) do
	if d:IsA("ProximityPrompt") and d.Name == "TravelPrompt" then
		local dist = (d.Parent.Position - root.Position).Magnitude
		if not bd or dist < bd then best, bd = d, dist end
	end
end
if not best then print("QQ TGO no travel prompt streamed in"); return end
print(string.format("QQ TGO nearest board %s dest=%s dist=%.1f enabled=%s Item_porto=%s Area=%s", best.Parent.Parent.Name, tostring(best:GetAttribute("Dest")), bd, tostring(best.Enabled), tostring(p:GetAttribute("Item_porto")), tostring(p:GetAttribute("Area"))))
if bd > 9 then
	-- walk up to the post first (teleport the client's own character, like stepping off the dais)
	root.CFrame = CFrame.new(best.Parent.Position + Vector3.new(-3, 2.5, 0), best.Parent.Position)
	task.wait(0.4)
end
best:InputHoldBegin()
task.wait(0.7)
best:InputHoldEnd()
local t0 = os.clock()
task.wait(3.5)
root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
print(string.format("QQ TGO after %.1fs at %s Area=%s NoMusic=%s", os.clock() - t0, root and string.format("(%.1f,%.1f,%.1f)", root.Position.X, root.Position.Y, root.Position.Z) or "?", tostring(p:GetAttribute("Area")), tostring(p.Character and p.Character:GetAttribute("NoMusic"))))
print("QQ TGO DONE")
