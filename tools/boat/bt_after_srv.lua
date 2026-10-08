-- bt_after v1 (PLAY, SERVER, read-only): what is left after the fall - boat models, pieces, wreckage, the player.
local B = workspace.Boat
local n = {}
for _, c in ipairs(B:GetChildren()) do n[c.Name:gsub("_%d+$", "")] = (n[c.Name:gsub("_%d+$", "")] or 0) + 1 end
local s = {}; for k, v in pairs(n) do s[#s + 1] = k .. "=" .. v end; table.sort(s)
local w = {}
for _, q in ipairs(B.Wreckage:GetChildren()) do w[#w + 1] = string.format("(%.0f, %.1f, %.0f) %s", q.Position.X, q.Position.Y, q.Position.Z, q.Anchored and "anchored" or "afloat") end
local plr = game.Players:GetPlayers()[1]
local ch = plr.Character
local hum = ch and ch:FindFirstChildOfClass("Humanoid")
local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
warn(string.format("QQ BTA Boat children: %s; wreckage: %s; player at %s state %s sit=%s chute=%s", table.concat(s, " "), table.concat(w, " | "), hrp and tostring(hrp.Position) or "?", hum and hum:GetState().Name or "?", tostring(hum and hum.Sit), tostring(ch and ch:FindFirstChild("Parachute") ~= nil)))
