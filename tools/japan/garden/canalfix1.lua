-- canalfix1.lua (runner 7, Oct 16 2026, solo): Shannon's canal notes after publishing.
-- 1. "the steps going down into the canal ... I think they're backwards": every WaterSteps model (and its _low copy) turned half
--    round about its own box centre - the high tread at the wall, stepping down into the water.
-- 2. "the embankment kind of cuts into the bridge": the bridges' red side beams passed through the canal walls near the ends (beam
--    underside 0.75-1.2 against a wall top of 1.67 / coping 2.12). Every TaikoBridge raised RAISE studs; its two landings stretched up
--    so their top meets the higher deck end (bottom stays on the lawn).
-- 3. "there's a tree sitting right in front of the bridge": the vermilion maple at (6125, -205) by the garden bridge's east end moved
--    to (6138, -186), clear of the stepping-stone path and the lanterns.
-- Re-runnable (attributes CanalFix1 mark what was done). Output "QQ CANALFIX1".
local RAISE = 1.6
local TREE_FROM, TREE_TO = Vector3.new(6125.1, 0, -205.0), Vector3.new(6138, 0, -186)
local J = workspace:FindFirstChild("JapanMap")
local G = J and J:FindFirstChild("MomijiGarden")
if not G then print("QQ CANALFIX1 ABORT: JapanMap.MomijiGarden missing") return end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before canalfix1") end)
local turned, raised, landings, moved = 0, 0, 0, 0
for _, m in ipairs(G:GetDescendants()) do
	if m:IsA("Model") and m.Name:match("^WaterSteps") and not m:GetAttribute("CanalFix1") then
		local cf = m:GetBoundingBox()
		local c = Vector3.new(cf.X, 0, cf.Z)
		local rot = CFrame.new(c) * CFrame.Angles(0, math.pi, 0) * CFrame.new(-c)
		for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then p.CFrame = rot * p.CFrame end end
		m:SetAttribute("CanalFix1", "turned"); turned += 1
	end
end
for _, m in ipairs(G:GetDescendants()) do
	if m:IsA("Model") and m.Name:match("^TaikoBridge") and not m:GetAttribute("CanalFix1") then
		for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then p.CFrame = p.CFrame + Vector3.new(0, RAISE, 0) end end
		m:SetAttribute("CanalFix1", "raised " .. RAISE); raised += 1
	elseif m:IsA("Model") and m.Name:match("^Landing[WE]%d") and not m:GetAttribute("CanalFix1") then
		local cf, s = m:GetBoundingBox()
		local bottom, top = cf.Y - s.Y / 2, cf.Y + s.Y / 2
		local f = (top + RAISE - bottom) / (top - bottom)
		for _, p in ipairs(m:GetDescendants()) do
			if p:IsA("BasePart") then
				local up = p.CFrame.UpVector
				local axisY = math.abs(up.Y) > 0.9 and "Y" or (math.abs(p.CFrame.RightVector.Y) > 0.9 and "X" or "Z")
				local sz = p.Size
				p.Size = Vector3.new(sz.X * (axisY == "X" and f or 1), sz.Y * (axisY == "Y" and f or 1), sz.Z * (axisY == "Z" and f or 1))
				local pos = p.Position
				p.CFrame = p.CFrame + Vector3.new(0, bottom + (pos.Y - bottom) * f - pos.Y, 0)
			end
		end
		m:SetAttribute("CanalFix1", "stretched to " .. string.format("%.2f", top + RAISE)); landings += 1
	end
end
local groves = J:FindFirstChild("Blender maple and blossom groves")
if groves then
	for _, d in ipairs(groves:GetChildren()) do
		if d:IsA("BasePart") and not d:GetAttribute("CanalFix1") and (Vector3.new(d.Position.X, 0, d.Position.Z) - TREE_FROM).Magnitude < 1.5 then
			d:SetAttribute("CanalFix1", "moved from " .. tostring(d.Position)); d.CFrame = d.CFrame + (TREE_TO - TREE_FROM); moved += 1
		end
	end
end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after canalfix1") end)
print(string.format("QQ CANALFIX1 DONE: %d water stairs turned round, %d bridges raised %.1f, %d landings stretched, %d maple parts moved to (%.0f, %.0f)",
	turned, raised, RAISE, landings, moved, TREE_TO.X, TREE_TO.Z))
