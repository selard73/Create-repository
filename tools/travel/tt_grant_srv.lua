-- tt_grant_srv v1 (PLAY, Server tab): TEST ONLY. Gives the first player Item_porto = 1 through AwardItems (attributes only; with
-- API access off SquirrelSetup cannot save), then reports the travel state. Never run outside a play test.
local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
if not p then print("QQ TG no player"); return end
local award = game:GetService("ReplicatedStorage"):FindFirstChild("AwardItems")
if (p:GetAttribute("Item_porto") or 0) < 1 then award:Fire(p, "porto", 1) end
task.wait(0.3)
local T = workspace:FindFirstChild("Travel")
local n = 0
if T then for _, d in ipairs(T:GetDescendants()) do if d:IsA("ProximityPrompt") then n += 1 end end end
local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
print(string.format("QQ TG %s Item_porto=%s Item_frenchrank=%s Area=%s SavedArea=%s SaveLoaded=%s prompts=%d at %s", p.Name,
	tostring(p:GetAttribute("Item_porto")), tostring(p:GetAttribute("Item_frenchrank")), tostring(p:GetAttribute("Area")),
	tostring(p:GetAttribute("SavedArea")), tostring(p:GetAttribute("SaveLoaded")), n, root and string.format("(%.1f,%.1f,%.1f)", root.Position.X, root.Position.Y, root.Position.Z) or "?"))
print("QQ TG DONE")
