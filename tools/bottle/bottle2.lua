-- bottle2 (Oct 22 2026): the beach bottles scatter. Shannon: "the bottles on the sea shore keep spawning over and over in
-- the same place once I collect them. I thought those were suppose to be random, scattered and not so close together?" They
-- washed up at one of TEN fixed spots (WashSpots) in a 100 x 45 strip, the closest 12 studs apart, one bottle at a time.
-- Now a bottle washes up at a random spot on the SAND (Terrain Sand, nearly flat, above the sea, nothing built on it -
-- the sea glass's test) inside BeachMin..BeachMax, at least MinApart studs from every bottle on the beach and from the
-- last three spots collected; WashSpots stays only as the fallback when the sand search fails. Two bottles at a time
-- (MaxBeach 1 -> 2). Attributes on workspace.Bottles: BeachMin / BeachMax (Vector3), MinApart (40), MaxBeach (2).
-- Run in Studio EDIT. Backs BottleServer up to ServerStorage.HudBackup.BottleServer_pre_bottle2 first.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")
local F = workspace.Bottles
local bs = F.BottleServer
local function patched(script, edits)
	local src = script.Source
	assert(not src:find("(bottle2", 1, true), script.Name .. " already patched")
	for _, e in ipairs(edits) do
		local a, b = src:find(e[1], 1, true)
		assert(a, script.Name .. ": " .. e[3] .. " not found - nothing changed")
		assert(not src:find(e[1], b + 1, true), script.Name .. ": " .. e[3] .. " found twice - nothing changed")
		src = src:sub(1, a - 1) .. e[2] .. src:sub(b + 1)
	end
	return src
end
--@@EDITS_BEGIN
local EDITS = {
	{[==[local taken = {}
local function wash()]==],
	 [==[local taken = {}
-- (bottle2, Oct 22 2026; Shannon: the bottles "keep spawning over and over in the same place ... supposed to be random,
-- scattered") a bottle washes up at a random spot on the SAND inside BeachMin..BeachMax (as the sea glass does: Terrain,
-- Sand, nearly flat, above the sea, nothing built on it), at least MinApart studs from every bottle on the beach and from
-- the last three spots collected; the old WashSpots list is only the fallback when the sand search fails
local recent = {}
local function remember(pos) table.insert(recent, 1, pos); while #recent > 3 do table.remove(recent) end end
local sandParams = RaycastParams.new(); sandParams.FilterType = Enum.RaycastFilterType.Exclude; sandParams.FilterDescendantsInstances = {beachF}; sandParams.IgnoreWater = false
local overlap = OverlapParams.new(); overlap.FilterType = Enum.RaycastFilterType.Exclude; overlap.FilterDescendantsInstances = {workspace.Terrain, beachF}
local key = 0
local function pickSpot()
	key += 1
	local a, b = F:GetAttribute("BeachMin"), F:GetAttribute("BeachMax")
	local apart = tonumber(A("MinApart", 40)) or 40
	if typeof(a) == "Vector3" and typeof(b) == "Vector3" then
		for try = 1, 160 do
			if try > 100 then apart = apart * 0.5 end                   -- (a crowded beach: settle for half the spacing rather than the old list)
			local x, z = a.X + math.random() * (b.X - a.X), a.Z + math.random() * (b.Z - a.Z)
			local hit = workspace:Raycast(Vector3.new(x, b.Y + 20, z), Vector3.new(0, -(b.Y - a.Y + 40), 0), sandParams)
			if hit and hit.Instance == workspace.Terrain and hit.Material == Enum.Material.Sand and hit.Normal.Y > 0.8 and hit.Position.Y > a.Y then
				local p = hit.Position
				local ok = #workspace:GetPartBoundsInRadius(p, 2.5, overlap) == 0
				if ok then for _, m in pairs(taken) do if m and m.Parent and (m:GetPivot().Position - p).Magnitude < apart then ok = false break end end end
				if ok then for _, r in ipairs(recent) do if (r - p).Magnitude < apart then ok = false break end end end
				if ok then return {p.X, p.Y, p.Z}, key end
			end
		end
	end
	if #spots == 0 then return nil end
	local s = spots[math.random(#spots)]                              -- (fallback: the old fixed list)
	return s, key
end
local function wash()]==], "the spot picker"},
	{[==[	if #spots == 0 or not template then return end
	local free = {}
	for i = 1, #spots do if not taken[i] then table.insert(free, i) end end
	if #free == 0 then return end
	local i = free[math.random(#free)]
	local s = spots[i]]==],
	 [==[	if not template then return end
	local s, i = pickSpot()                                           -- (bottle2)
	if not s then return end]==], "the spot choice"},
	{[==[taken[i] = nil; m:Destroy()]==],
	 [==[local at = m:GetPivot().Position; taken[i] = nil; m:Destroy(); remember(at)   -- (bottle2: not here again for a while)]==], "the collect"},
}
--@@EDITS_END
local src = patched(bs, EDITS)
local b = bs:Clone(); b.Name = "BottleServer_pre_bottle2"; b.Enabled = false; b.Parent = backup
SES:UpdateSourceAsync(bs, function() return src end)
if F:GetAttribute("BeachMin") == nil then F:SetAttribute("BeachMin", Vector3.new(232, -56, -792)) end
if F:GetAttribute("BeachMax") == nil then F:SetAttribute("BeachMax", Vector3.new(348, -40, -680)) end
if F:GetAttribute("MinApart") == nil then F:SetAttribute("MinApart", 40) end
F:SetAttribute("MaxBeach", 2)
print(string.format("bottle2: BottleServer %d chars; beach box set; MinApart 40; MaxBeach 2", #bs.Source))
return "bottle2 installed"
