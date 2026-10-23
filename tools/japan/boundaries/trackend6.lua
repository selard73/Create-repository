-- trackend6.lua (Oct 23 2026): the Blender buffer stop (gen_buffer_stop.py -> japan_buffer_stop.fbx, imported by her) replaces
-- the part-built stops at both ends of the Japan railway. Her: "you need to make this in blender rather than using roblox
-- shapes, they always come out wrong" + "now it's missing a track part too" (one rail short at the end).
--  1. The import (5 meshes BS_Steel / BS_Red / BS_White / BS_Head / BS_Sleeper) is adopted into ServerStorage.JapanGardenKit as
--     "BufferStop" (the kit may come in turned 180 about y like the others: the heads must face +x in the design; detect by
--     the BS_Head mesh being on the +x side of BS_Red and turn back if not).
--  2. At each end: the old "Buffer stop W/E" model's parts go (the ballast extension + taper stay); the rails both end at the
--     SAME x (the old rail end, 5440 / 6560); a clone of the kit stands with its posts 1.0 past the rail end, heads facing the
--     track, its sleepers' tops at ballast top + 0.3; Studio materials per mesh name.
-- Guard: Railway attribute TrackEnd6. "QQ TRACKEND6".
local SS = game:GetService("ServerStorage")
local R = workspace.JapanMap.Railway
local KIT = SS.JapanGardenKit
if R:GetAttribute("TrackEnd6") then return "QQ TRACKEND6 already done" end
local out = {}
local function say(s) table.insert(out, "QQ TRACKEND6 " .. s) end
-- 1. the kit
local kit = KIT:FindFirstChild("BufferStop")
if not kit then
	local imp
	for _, top in ipairs(workspace:GetChildren()) do
		if top:IsA("Model") and top.Name ~= "JapanMap" then
			for _, d in ipairs(top:GetDescendants()) do if d:IsA("BasePart") and d.Name:find("^BS_") then imp = top break end end
			if imp then break end
		end
	end
	if not imp then return "QQ TRACKEND6 ABORT: no japan_buffer_stop import in workspace (import japan_buffer_stop.fbx first)" end
	kit = Instance.new("Model"); kit.Name = "BufferStop"
	for _, d in ipairs(imp:GetDescendants()) do
		if d:IsA("BasePart") then d.Name = d.Name:gsub("%.%d+$", ""); d.Anchored = true; d.CanCollide = false; d.CanQuery = false; d.Parent = kit end
	end
	if #imp:GetDescendants() == 0 then imp:Destroy() end
	local head, red = kit:FindFirstChild("BS_Head"), kit:FindFirstChild("BS_Red")
	if not (head and red) then return "QQ TRACKEND6 ABORT: the import lacks BS_Head / BS_Red" end
	if head.Position.X < red.Position.X then kit:PivotTo(kit:GetPivot() * CFrame.Angles(0, math.pi, 0)); say("kit turned back 180 (heads now +x)") end
	kit.Parent = KIT
	say("kit adopted into JapanGardenKit.BufferStop")
end
local C = Color3.fromRGB
local LOOK = {BS_Steel = {Enum.Material.Metal, C(44, 46, 50)}, BS_Red = {Enum.Material.SmoothPlastic, C(196, 40, 30)}, BS_White = {Enum.Material.SmoothPlastic, C(240, 236, 228)}, BS_Head = {Enum.Material.Metal, C(70, 72, 76)}, BS_Sleeper = {Enum.Material.Wood, C(103, 72, 48)}}
local BALLAST_TOP, ZC = 1.10, 181.0
local rails = {}
for _, c in ipairs(R:GetChildren()) do if c:IsA("BasePart") and c.Name == "Steel rail" then table.insert(rails, c) end end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before trackend6") end)
for _, e in ipairs({{"W", 5440, 1}, {"E", 6560, -1}}) do
	local name, xEnd, dir = e[1], e[2], e[3]
	local m = R:FindFirstChild("Buffer stop " .. name)
	if m then for _, c in ipairs(m:GetChildren()) do if c.Name ~= "Ballast extension" and c.Name ~= "Ballast end" then c:Destroy() end end
	else m = Instance.new("Model"); m.Name = "Buffer stop " .. name; m.Parent = R end
	-- both rails end at xEnd exactly
	for _, r in ipairs(rails) do
		local far = r.Position.X + dir * r.Size.X / 2
		r.Size = Vector3.new(math.abs(far - xEnd), r.Size.Y, r.Size.Z); r.CFrame = CFrame.new((far + xEnd) / 2, r.Position.Y, r.Position.Z) * r.CFrame.Rotation
	end
	-- the stop: a clone, dressed, placed. Design frame: posts at x 0, heads toward +x, sleeper bottoms at y 0 (ballast top).
	local s = kit:Clone(); s.Name = "Stop"
	for _, p in ipairs(s:GetDescendants()) do
		if p:IsA("BasePart") then
			local d = LOOK[p.Name] or LOOK.BS_Steel
			p.Material, p.Color = d[1], d[2]; p.Anchored = true; p.CanCollide = true; p.CanQuery = true; p.CanTouch = false; p.CastShadow = true
			if p:IsA("MeshPart") then p.DoubleSided = false end
		end
	end
	-- the design origin in the import: the posts' centre x = BS_Red's x minus 0.7 (the red face spans 0.5..0.9 past the post),
	-- y = the sleepers' bottom, z = the model's centre
	local red, sl = s.BS_Red, s.BS_Sleeper
	local cf, sz = s:GetBoundingBox()
	local origin = Vector3.new(red.Position.X - 0.7, sl.Position.Y - sl.Size.Y / 2, cf.Position.Z)
	s.WorldPivot = CFrame.new(origin)
	local target = CFrame.new(xEnd - dir * 1.0, BALLAST_TOP, ZC) * (dir > 0 and CFrame.new() or CFrame.Angles(0, math.pi, 0))   -- heads toward the track
	s:PivotTo(target)
	s.Parent = m
	-- the ballast extension / taper as the compact version: ballast to 1 past the strut feet (3.8 behind the posts), taper 3
	local feetX = (xEnd - dir * 1.0) - dir * 2.8
	local extEnd = feetX - dir * 1.0
	local ext = m:FindFirstChild("Ballast extension")
	if not ext then ext = Instance.new("Part"); ext.Name = "Ballast extension"; ext.Material = Enum.Material.Pebble; ext.Color = C(104, 112, 118); ext.Anchored = true; ext.CanCollide = true; ext.Parent = m end
	ext.Size = Vector3.new(math.abs(extEnd - xEnd), 1.1, 15); ext.CFrame = CFrame.new((xEnd + extEnd) / 2, 0.55, ZC)
	local w = m:FindFirstChild("Ballast end")
	if not w then w = Instance.new("WedgePart"); w.Name = "Ballast end"; w.Material = Enum.Material.Pebble; w.Color = C(104, 112, 118); w.Anchored = true; w.CanCollide = true; w.Parent = m end
	w.Size = Vector3.new(15, 1.1, 3); w.CFrame = CFrame.lookAt(Vector3.new(extEnd - dir * 1.5, 0.55, ZC), Vector3.new(extEnd - dir * 2.5, 0.55, ZC))
	say(string.format("%s: mesh stop at x %.1f (heads toward %s), rails end at %.0f, ballast to %.1f", name, xEnd - dir * 1.0, dir > 0 and "+x" or "-x", xEnd, extEnd))
end
R:SetAttribute("TrackEnd6", "2026-10-23")
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after trackend6") end)
say("DONE - EDIT INSTALLED; NOT PUBLISHED")
return table.concat(out, "\n")
