-- japan_geo4b.lua (job 106 round 4b): Studio EDIT. Bakes runner 7's tuned horizon look into the installed model: Shade 1.2 and
-- Reflectance 0.1 on JapanMap["Horizon sea"] (HorizonSeaClient applies them on every client), and the same on the parts for Edit.
-- Re-runnable. Output "QQ GEO4B".
if game:GetService("RunService"):IsRunning() then print("QQ GEO4B ABORT - Play mode") return end
local J = workspace:FindFirstChild("JapanMap")
local M = J and J:FindFirstChild("Horizon sea") or workspace:FindFirstChild("Horizon sea")
if not (M and M:IsA("Model")) then print("QQ GEO4B ABORT - no Horizon sea model (run japan_geo4.lua first)") return end
local SHADE, REFL = 1.2, 0.1
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before JapanGeo4b") end)
M:SetAttribute("Shade", SHADE); M:SetAttribute("Reflectance", REFL)
local w = Color3.fromRGB(24, 112, 151)
local c = Color3.new(math.clamp(w.R * SHADE, 0, 1), math.clamp(w.G * SHADE, 0, 1), math.clamp(w.B * SHADE, 0, 1))
local n = 0
for _, p in ipairs(M:GetChildren()) do if p:IsA("BasePart") then p.Color = c; p.Reflectance = REFL; n += 1 end end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after JapanGeo4b") end)
print(string.format("QQ GEO4B DONE: %s - Shade %.2f, Reflectance %.2f on the model and its %d planes", M:GetFullName(), SHADE, REFL, n))
