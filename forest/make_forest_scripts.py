"""Builds ForestBuilder.rbxmx: a Folder "ForestBuilder" holding one server Script.
On Play (or Run) it finds the imported kit models by name, scatters clones over an area with variation,
tints every piece by its name (Trunk / Foliage / ...), records hiding spots, and (optionally) moves the
squirrel models into those hiding spots. Everything it builds goes into workspace.Forest.

Attributes on the folder (set them in Properties before pressing Play):
  CenterX, CenterZ  centre of the forest area          Width, Depth  size in studs
  Trees             how many trees                      Understory    bushes/logs/stumps/rocks/mushrooms count
  Seed              change for a different layout       Clearings     how many open patches
  HideSquirrels     true = move squirrel models into hiding spots
  KeepExisting      true = don't delete a previous workspace.Forest first

To keep the result: while Play is running, in Explorer right-click workspace.Forest > Copy, press Stop, then
right-click Workspace > Paste Into. Then set the ForestBuilder folder's Enabled attribute to false.
Run: python make_forest_scripts.py
"""
from pathlib import Path
import xml.dom.minidom as m
OUT = Path(__file__).parent / "ForestBuilder.rbxmx"

BUILD = r'''
-- ForestBuilder: scatters the imported forest kit and hides the squirrels in it.
-- Runs at Play (Build script) or in edit mode from the command bar:  require(workspace.ForestBuilder.BuildModule)()
return function()
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local folder = script.Parent
local function attr(name, default)
	local v = folder:GetAttribute(name)
	if v == nil then folder:SetAttribute(name, default); return default end
	return v
end
if attr("Enabled", true) == false then print("ForestBuilder: disabled") return end
local CX, CZ = attr("CenterX", 0), attr("CenterZ", -120)
local W, D = attr("Width", 220), attr("Depth", 160)
local TREES, UNDER = attr("Trees", 90), attr("Understory", 45)
local SEED, CLEARINGS = attr("Seed", 7), attr("Clearings", 3)
local HIDE = attr("HideSquirrels", true)
local KEEP = attr("KeepExisting", false)
local rng = Random.new(SEED)

-- kit lookup: any Model (or MeshPart) in the Workspace whose name starts with a kit name
local KIT = {"pine_tall", "pine_mid", "pine_squat", "round_tree", "stump", "log_fallen", "log_hollow",
	"bush_big", "bush_small", "rock_big", "rock_cluster", "mushrooms"}
-- forest_kit.obj imports as one model of pieces named "<kit>__<piece>": regroup those into one Model per kit name
do
	local groups = {}
	for _, p in ipairs(workspace:GetDescendants()) do
		if p:IsA("MeshPart") and not p:FindFirstAncestor("Forest") then
			local kit, piece = p.Name:match("^(.-)__(.+)$")
			if kit and piece then
				local g = groups[kit]
				if not g then
					g = Instance.new("Model"); g.Name = kit
					g.Parent = workspace:FindFirstChild("ForestKit") or (function()
						local f = Instance.new("Folder"); f.Name = "ForestKit"; f.Parent = workspace; return f end)()
					groups[kit] = g
				end
				p.Name = piece; p.Parent = g
			end
		end
	end
	for kit, g in pairs(groups) do
		local a = g:FindFirstChildWhichIsA("BasePart")
		g.PrimaryPart = a
		if not a then g:Destroy() end
	end
	-- remove the now-empty import model(s)
	for _, m in ipairs(workspace:GetChildren()) do
		if m:IsA("Model") and m.Name:lower():find("forest_kit") and not m:FindFirstChildWhichIsA("BasePart", true) then m:Destroy() end
	end
end
local templates = {}
for _, inst in ipairs(workspace:GetDescendants()) do
	if (inst:IsA("Model") or inst:IsA("MeshPart")) and not inst:FindFirstAncestor("Forest") then
		local nm = string.lower(inst.Name)
		for _, k in ipairs(KIT) do
			if nm == k or nm:sub(1, #k + 1) == k .. "_" or nm:sub(1, #k + 1) == k .. " " then
				if not templates[k] and not (inst:IsA("MeshPart") and inst.Parent:IsA("Model") and templates[k] == inst.Parent) then
					-- prefer the Model that holds the pieces over its individual MeshParts
					if inst:IsA("MeshPart") and inst.Parent:IsA("Model") and string.lower(inst.Parent.Name):sub(1, #k) == k then
						templates[k] = inst.Parent
					else
						templates[k] = inst
					end
				end
			end
		end
	end
end
local missing = {}
for _, k in ipairs(KIT) do if not templates[k] then table.insert(missing, k) end end
if #missing > 0 then warn("ForestBuilder: kit pieces not found (import the .obj files, Merge Meshes OFF): " .. table.concat(missing, ", ")) end
local have = 0
for _ in pairs(templates) do have += 1 end
if have == 0 then warn("ForestBuilder: nothing to build with") return end

-- Palette attribute: "gray" (world without colour, default) or "color" (a coloured forest)
local PALETTE = attr("Palette", "gray")
local TINT
if PALETTE == "color" then
	TINT = {
		Foliage = Color3.fromRGB(86, 158, 96), Canopy = Color3.fromRGB(112, 176, 84), Leaf = Color3.fromRGB(98, 164, 90),
		Trunk = Color3.fromRGB(112, 82, 58), Wood = Color3.fromRGB(128, 94, 66), Rings = Color3.fromRGB(196, 168, 128),
		Rock = Color3.fromRGB(146, 150, 162), Cap = Color3.fromRGB(214, 62, 58), Stem = Color3.fromRGB(240, 232, 214),
		Spots = Color3.fromRGB(250, 248, 240),
	}
else
	TINT = {
		Foliage = Color3.fromRGB(219, 222, 226), Canopy = Color3.fromRGB(214, 219, 224), Leaf = Color3.fromRGB(204, 209, 214),
		Trunk = Color3.fromRGB(117, 115, 112), Wood = Color3.fromRGB(133, 128, 122), Rings = Color3.fromRGB(179, 173, 168),
		Rock = Color3.fromRGB(158, 161, 166), Cap = Color3.fromRGB(199, 194, 194), Stem = Color3.fromRGB(235, 232, 230),
		Spots = Color3.fromRGB(245, 245, 245),
	}
end
-- foliage on the pine variants gets a little variation so the forest isn't one flat tone
local function vary(c, k) return Color3.new(math.clamp(c.R * k, 0, 1), math.clamp(c.G * k, 0, 1), math.clamp(c.B * k, 0, 1)) end
local function tint(model)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true; p.Material = Enum.Material.SmoothPlastic; p.CastShadow = true
			for key, col in pairs(TINT) do
				if p.Name:sub(1, #key) == key then p.Color = col end
			end
			if p.Name == "default" or p.Name == "Mesh" then p.Color = Color3.fromRGB(200, 202, 206) end
		end
	end
	if model:IsA("BasePart") then
		model.Anchored = true; model.Material = Enum.Material.SmoothPlastic
	end
end
for _, t in pairs(templates) do
	tint(t)
	-- hide the originals off to the side, still there for future rebuilds
	if t:IsA("Model") then
		for _, p in ipairs(t:GetDescendants()) do if p:IsA("BasePart") then p.Transparency = 1; p.CanCollide = false; p.CanQuery = false end end
	else
		t.Transparency = 1; t.CanCollide = false; t.CanQuery = false
	end
end

-- ground: raycast down, ignoring the forest itself
local forest = workspace:FindFirstChild("Forest")
if forest and not KEEP then forest:Destroy(); forest = nil end
forest = forest or Instance.new("Folder"); forest.Name = "Forest"; forest.Parent = workspace
local spots = Instance.new("Folder"); spots.Name = "HidingSpots"; spots.Parent = forest
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
local ignore = {forest}
for _, t in pairs(templates) do table.insert(ignore, t) end
for _, m2 in ipairs(CollectionService:GetTagged("Squirrel")) do table.insert(ignore, m2) end
rp.FilterDescendantsInstances = ignore
local GROUND_FALLBACK = attr("GroundY", 0)
local function groundAt(x, z)
	local r = workspace:Raycast(Vector3.new(x, 500, z), Vector3.new(0, -1000, 0), rp)
	if r then return r.Position.Y, r.Normal end
	return GROUND_FALLBACK, Vector3.yAxis
end

local function bottomOffset(model)
	local cf, size = model:GetBoundingBox()
	return model:GetPivot().Position.Y - (cf.Position.Y - size.Y / 2), size
end

local placed = {}     -- {x, z, r}
local function tooClose(x, z, r)
	for _, p in ipairs(placed) do
		local d = math.sqrt((p[1] - x) ^ 2 + (p[3] - z) ^ 2)
		if d < (p[2] + r) then return true end
	end
	return false
end
local clearings = {}
for i = 1, CLEARINGS do
	table.insert(clearings, {CX + rng:NextNumber(-0.4, 0.4) * W, CZ + rng:NextNumber(-0.4, 0.4) * D, rng:NextNumber(14, 24)})
end
local function inClearing(x, z, pad)
	for _, c in ipairs(clearings) do
		if math.sqrt((c[1] - x) ^ 2 + (c[2] - z) ^ 2) < c[3] + (pad or 0) then return true end
	end
	return false
end

local function place(kitName, x, z, scale, yaw, tiltDeg, spotKinds)
	local t = templates[kitName]
	if not t then return end
	local c = t:Clone()
	c.Name = kitName
	for _, p in ipairs(c:GetDescendants()) do
		if p:IsA("BasePart") then p.Transparency = 0; p.CanCollide = true; p.CanQuery = true end
	end
	if c:IsA("BasePart") then c.Transparency = 0; c.CanCollide = true; c.CanQuery = true end
	local model = c
	if c:IsA("BasePart") then model = Instance.new("Model"); model.Name = kitName; c.Parent = model; model.PrimaryPart = c end
	model.Parent = forest
	if scale ~= 1 then model:ScaleTo(scale) end
	local gy, n = groundAt(x, z)
	local tilt = CFrame.Angles(math.rad(rng:NextNumber(-tiltDeg, tiltDeg)), 0, math.rad(rng:NextNumber(-tiltDeg, tiltDeg)))
	model:PivotTo(CFrame.new(x, gy, z) * CFrame.Angles(0, yaw, 0) * tilt)
	local bb, size = model:GetBoundingBox()
	-- slide it so the bounding box is centred on (x, z) and its bottom sits 0.15 into the ground
	model:PivotTo(model:GetPivot() + Vector3.new(x - bb.Position.X, gy - (bb.Position.Y - size.Y / 2) - 0.15, z - bb.Position.Z))
	if PALETTE == "color" then
		local k = rng:NextNumber(0.85, 1.15)
		for _, p in ipairs(model:GetDescendants()) do
			if p:IsA("BasePart") and (p.Name:sub(1, 7) == "Foliage" or p.Name:sub(1, 6) == "Canopy" or p.Name:sub(1, 4) == "Leaf") then p.Color = vary(p.Color, k) end
			if p:IsA("BasePart") and p.Name:sub(1, 4) == "Rock" then
				-- lower stones darker, upper stones lighter, so a stack reads as separate rocks not one box
				local n = tonumber(p.Name:match("%d+")) or 1
				p.Color = vary(p.Color, rng:NextNumber(0.72, 0.9) + n * 0.12)
			end
		end
	end
	local r = math.max(size.X, size.Z) / 2
	table.insert(placed, {x, r, z})
	-- hiding spots relative to this prop
	for _, kind in ipairs(spotKinds or {}) do
		local a = Instance.new("Attachment"); a.Name = kind; a.Parent = spots
		local base = CFrame.new(x, gy, z) * CFrame.Angles(0, yaw, 0)
		if kind == "InsideLog" then a.WorldCFrame = base * CFrame.new(0, 0.6 * scale - 0.15 + 0.03, 0)   -- on the log's inner floor (wall is 0.6 thick)
		elseif kind == "OnStump" then a.WorldCFrame = CFrame.new(x, gy + size.Y - 0.25, z) * CFrame.Angles(0, yaw, 0)
		elseif kind == "BehindRock" then a.WorldCFrame = base * CFrame.new(0, 0, r + 0.8)
		elseif kind == "UnderBush" then a.WorldCFrame = base * CFrame.new(rng:NextNumber(-0.6, 0.6), 0, rng:NextNumber(-0.6, 0.6))
		elseif kind == "BesideLog" then a.WorldCFrame = base * CFrame.new(rng:NextNumber(-2, 2), 0, 1.9)
		elseif kind == "AtTrunk" then
			local ang = rng:NextNumber(0, 6.28)
			a.WorldCFrame = CFrame.new(x + math.cos(ang) * (r * 0.28 + 1.2), gy, z + math.sin(ang) * (r * 0.28 + 1.2)) * CFrame.Angles(0, -ang + math.pi / 2, 0)
		elseif kind == "InTree" then
			local ang = rng:NextNumber(0, 6.28)
			a.WorldCFrame = CFrame.new(x + math.cos(ang) * r * 0.55, gy + size.Y * 0.42, z + math.sin(ang) * r * 0.55) * CFrame.Angles(0, -ang + math.pi / 2, 0)
		end
	end
	return model
end

local function randomPoint(pad)
	for _ = 1, 40 do
		local x, z = CX + rng:NextNumber(-0.5, 0.5) * W, CZ + rng:NextNumber(-0.5, 0.5) * D
		if not inClearing(x, z, pad) then return x, z end
	end
	return CX + rng:NextNumber(-0.5, 0.5) * W, CZ + rng:NextNumber(-0.5, 0.5) * D
end

-- 1. trees: denser at the edges, tall pines dominate, a few round trees and squat pines mixed in
local treeKinds = {}
for _, k in ipairs({"pine_tall", "pine_tall", "pine_tall", "pine_mid", "pine_mid", "pine_squat", "round_tree"}) do
	if templates[k] then table.insert(treeKinds, k) end
end
local trees = 0
local tries = 0
while trees < TREES and tries < TREES * 30 and #treeKinds > 0 do
	tries += 1
	local x, z = randomPoint(4)
	local kind = treeKinds[rng:NextInteger(1, #treeKinds)]
	local scale = rng:NextNumber(0.8, 1.3)
	local spacing = (kind == "round_tree" and 7 or 5.5) * scale
	if not tooClose(x, z, spacing) then
		place(kind, x, z, scale, rng:NextNumber(0, 6.28), 2.5, {"AtTrunk", (kind == "round_tree" or kind == "pine_squat") and "InTree" or nil})
		trees += 1
	end
end

-- 2. understory: logs and stumps and rocks in the open, bushes near trunks and at clearing edges, mushrooms by logs
local understory = {
	{"bush_big", 3, {"UnderBush"}, 0.9, 1.35}, {"bush_small", 3, {"UnderBush"}, 0.9, 1.4},
	{"log_fallen", 2, {"BesideLog"}, 0.9, 1.25}, {"log_hollow", 2, {"InsideLog"}, 1.0, 1.2},
	{"stump", 2, {"OnStump"}, 0.85, 1.3}, {"rock_big", 1, {"BehindRock"}, 0.9, 1.4}, {"rock_cluster", 2, {"BehindRock"}, 0.9, 1.4},
	{"mushrooms", 2, {}, 0.8, 1.3},
}
local bag = {}
for _, u in ipairs(understory) do
	if templates[u[1]] then for _ = 1, u[2] do table.insert(bag, u) end end
end
local under = 0
tries = 0
while under < UNDER and tries < UNDER * 30 and #bag > 0 do
	tries += 1
	local u = bag[rng:NextInteger(1, #bag)]
	local x, z
	if u[1] == "bush_big" or u[1] == "bush_small" then
		-- next to a tree
		local t = placed[rng:NextInteger(1, #placed)]
		local ang = rng:NextNumber(0, 6.28)
		x, z = t[1] + math.cos(ang) * (t[2] * 0.5 + 2.5), t[3] + math.sin(ang) * (t[2] * 0.5 + 2.5)
	else
		x, z = randomPoint(-6)     -- may sit at clearing edges
	end
	local scale = rng:NextNumber(u[4], u[5])
	local spacing = (u[1]:sub(1, 3) == "log" and 5 or 2.5) * scale
	if not tooClose(x, z, spacing) then
		place(u[1], x, z, scale, rng:NextNumber(0, 6.28), u[1]:sub(1, 4) == "rock" and 0 or 1.5, u[3])
		under += 1
	end
end
print(string.format("ForestBuilder: %d trees, %d understory props, %d hiding spots", trees, under, #spots:GetChildren()))

-- 3. hide the squirrels (after SquirrelSetup has scaled and paired them, if it is in the place)
if HIDE then
	local ss = workspace:FindFirstChild("SquirrelScripts", true) or game:GetService("ServerScriptService"):FindFirstChild("SquirrelScripts", true)
	if ss and RunService:IsRunning() then
		local waited = 0
		while ss:GetAttribute("Total") == nil and waited < 10 do task.wait(0.25); waited += 0.25 end
	end
	local squirrels = {}
	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("MeshPart") and inst:FindFirstChild("Tail2", true) and inst:FindFirstChild("Root", true) then
			local nm = string.lower(inst.Name .. " " .. (inst.Parent and inst.Parent.Name or ""))
			if not nm:find("gray") then table.insert(squirrels, inst:FindFirstAncestorOfClass("Model") or inst) end
		end
	end
	local list = spots:GetChildren()
	-- best spots first: inside logs, on stumps, behind rocks, under bushes, in trees, beside logs, at trunks
	local rank = {InsideLog = 1, OnStump = 2, BehindRock = 3, UnderBush = 4, InTree = 5, BesideLog = 6, AtTrunk = 7}
	for _, a in ipairs(list) do a:SetAttribute("r", rng:NextNumber()) end     -- fixed random key: a valid ordering
	table.sort(list, function(a, b)
		local ra, rb = rank[a.Name] or 9, rank[b.Name] or 9
		if ra ~= rb then return ra < rb end
		return a:GetAttribute("r") < b:GetAttribute("r")
	end)
	for i, sq in ipairs(squirrels) do
		local spot = list[i]
		if not spot then break end
		local wc = spot.WorldCFrame
		local gy = wc.Position.Y
		if spot.Name ~= "InTree" and spot.Name ~= "OnStump" and spot.Name ~= "InsideLog" then gy = select(1, groundAt(wc.Position.X, wc.Position.Z)) end
		local rot0 = sq:GetPivot().Rotation
		sq:PivotTo(CFrame.new(wc.Position.X, gy, wc.Position.Z) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0) * rot0)
		local cf, size = sq:GetBoundingBox()
		sq:PivotTo(sq:GetPivot() + Vector3.new(wc.Position.X - cf.Position.X, gy - (cf.Position.Y - size.Y / 2), wc.Position.Z - cf.Position.Z))
		spot:SetAttribute("Squirrel", sq.Name)
	end
	print(string.format("ForestBuilder: hid %d squirrels", math.min(#squirrels, #list)))
end
folder:SetAttribute("Done", true)
end
'''

RUNNER = r'''
-- Build (server): rebuilds the forest when the game starts, unless the folder's Enabled attribute is false.
-- To build the forest permanently into the place instead, run this in the command bar while NOT playing:
--     require(workspace.ForestBuilder.BuildModule)()
-- then set the folder's Enabled attribute to false so Play keeps what you have.
require(script.Parent.BuildModule)()
'''

def script_item(name, source, run_context, ref):
    return f'''
  <Item class="Script" referent="{ref}">
    <Properties>
      <string name="Name">{name}</string>
      <token name="RunContext">{run_context}</token>
      <bool name="Enabled">true</bool>
      <ProtectedString name="Source"><![CDATA[{source}]]></ProtectedString>
    </Properties>
  </Item>'''

def module_item(name, source, ref):
    return f'''
  <Item class="ModuleScript" referent="{ref}">
    <Properties>
      <string name="Name">{name}</string>
      <ProtectedString name="Source"><![CDATA[{source}]]></ProtectedString>
    </Properties>
  </Item>'''

xml = f'''<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">
  <Item class="Folder" referent="RBX0">
    <Properties><string name="Name">ForestBuilder</string></Properties>{module_item("BuildModule", BUILD, "RBX1")}{script_item("Build", RUNNER, 1, "RBX2")}
  </Item>
</roblox>
'''
m.parseString(xml)
OUT.write_text(xml, encoding="utf-8")
print("wrote", OUT)
