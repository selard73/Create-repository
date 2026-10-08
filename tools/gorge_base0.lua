-- gorge_base0: READ-ONLY. Everything about the Baseplate before the cut (so the cut copy can keep it all), plus who
-- refers to it by name in scripts.
local CS = game:GetService("CollectionService")
local bp = workspace:FindFirstChild("Baseplate")
if not bp then print("QQ B0 no workspace.Baseplate"); return end
local props = {"ClassName", "Size", "Position", "Orientation", "Material", "Color", "Transparency", "Reflectance", "CanCollide", "CanQuery", "CanTouch",
	"Anchored", "Locked", "CastShadow", "UsePartColor", "CollisionFidelity", "RenderFidelity", "TriangleCount", "Massless", "CollisionGroup"}
local out = {}
for _, k in ipairs(props) do
	local ok, v = pcall(function() return bp[k] end)
	table.insert(out, k .. "=" .. (ok and tostring(v) or "?"))
end
print("QQ B0 props: " .. table.concat(out, " | "))
local kids = {}
for _, c in ipairs(bp:GetChildren()) do table.insert(kids, c.ClassName .. ":" .. c.Name) end
print("QQ B0 children (" .. #kids .. "): " .. table.concat(kids, ", "))
local attrs = {}
for k, v in pairs(bp:GetAttributes()) do table.insert(attrs, k .. "=" .. tostring(v)) end
print("QQ B0 attributes: " .. table.concat(attrs, ", ") .. " | tags: " .. table.concat(CS:GetTags(bp), ", "))
-- other things called Baseplate anywhere, and scripts mentioning it
local others, refs = {}, {}
for _, d in ipairs(game:GetDescendants()) do
	if d.Name == "Baseplate" and d ~= bp then table.insert(others, d:GetFullName()) end
	if (d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript")) then
		local ok, src = pcall(function() return d.Source end)
		if ok and src and src:find("Baseplate") then table.insert(refs, d:GetFullName()) end
	end
end
print("QQ B0 other 'Baseplate' instances: " .. (#others > 0 and table.concat(others, ", ") or "none"))
print("QQ B0 scripts mentioning Baseplate (" .. #refs .. "): " .. table.concat(refs, ", "))
-- what sits on the plate south of the gorge's end (anything but terrain), to know what the cut would leave in the air
local south = {}
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("BasePart") and d ~= bp and d.Position.Z < -546.5 and not d:IsDescendantOf(workspace.SouthGorge) then
		local m = d:FindFirstAncestorOfClass("Model")
		local key = m and m:GetFullName() or d:GetFullName()
		south[key] = (south[key] or 0) + 1
	end
end
local sl = {}
for k, v in pairs(south) do table.insert(sl, k .. " x" .. v) end
table.sort(sl)
print("QQ B0 parts south of z -546.5 outside SouthGorge (" .. #sl .. " groups): " .. table.concat(sl, "; "))
print("QQ B0 DONE")
