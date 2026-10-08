-- Oct 8 2026 (her yes: "new map looks great" / "yep, lets go"): the whole-world chart v2 (boundary/marketing/make_map_world2.py ->
-- italy/map/world_chart2_top.png + _bottom.png, uploaded with the MCP upload_image) goes into HudBarClient's map panel:
-- chart = a Frame with two stacked ImageLabel tiles (one Roblox image may not be taller than 1024), the world rect grows to
-- x -130..820, z -1310..30, and Porto's single "harbour coming soon" card becomes three areas (The Harbour / Via della Piazza /
-- The Groves) drawn from the Zones parts, each with its own "n / N found" from FoundIds + the registry's area.
-- Unlock on the map: harbour = Item_porto (the first landing); town + groves = the More Squirrels Coming Soon wall's rule
-- (15 Porto finds, the owner always, or the wall switched off) - to be swapped for the gate rule when the Porto gates are built.
-- Backup: ServerStorage.HudBackup.HudBarClient_before_map2_oct8
local LOG = {}
local function log(...) local t = {} for i = 1, select('#', ...) do t[#t + 1] = tostring(select(i, ...)) end LOG[#LOG + 1] = table.concat(t, ' ') end
local scr = workspace.HudBarUI.HudBarClient
local s = scr.Source
if s:find('MAP_TILES', 1, true) then return 'QM@SKIP already installed' end

local function rep(old, new, label)
	local a, b = s:find(old, 1, true)
	assert(a, 'pattern missing: ' .. label)
	assert(not s:find(old, b + 1, true), 'pattern twice: ' .. label)
	s = s:sub(1, a - 1) .. new .. s:sub(b + 1)
	log('patched', label)
end

-- 1. Porto's three areas
rep('\t{id = "porto",   x0 = 100,  x1 = 330, z0 = -700, z1 = -548, needs = "porto", name = "Porto Nocciola"},   -- Italy: opened by the first landing (Item_porto)\n}\n',
[[	-- Porto Nocciola's three areas (Oct 8 2026, world chart v2): rects {x0, z0, x1, z1} = the Zones parts of each area; the first carries the name plate
	{id = "porto_harbour", porto = "harbour", needs = "porto", name = "The Harbour", long = "Porto Nocciola · The Harbour",
	 rects = {{150, -880, 355, -540}, {150, -1300, 300, -880}}},
	{id = "porto_borgo", porto = "borgo", needs = "porto_inner", name = "Via della Piazza", long = "Porto Nocciola · Via della Piazza",
	 rects = {{355.5, -1000, 617, -540}, {617, -756, 800.5, -540}, {617, -1000, 800.5, -949}, {300, -1000, 355, -880}}},
	{id = "porto_groves", porto = "groves", needs = "porto_inner", name = "The Groves", long = "Porto Nocciola · The Groves",
	 rects = {{300, -1300, 800, -1000}, {617, -949, 800.5, -756}}},
}
for _, a in ipairs(AREAS) do if not a.rects then a.rects = {{a.x0, a.z0, a.x1, a.z1}} end end
]], 'AREAS porto -> three')

-- 2. per-area totals and finds, unlock rule
rep('local function unlocked(a) if a.needs == "porto" then return (player:GetAttribute("Item_porto") or 0) >= 1 end return (not a.needs) or (player:GetAttribute("Found_" .. a.needs) or 0) >= NEED end\n',
[[local AREA_OF = {}                                              -- Porto squirrel id -> its area (harbour / borgo / groves)
for _, e in ipairs(Registry.squirrels) do
	if e.map == "porto" and e.area then AREA_OF[e.id] = e.area; TOTAL["porto_" .. e.area] = (TOTAL["porto_" .. e.area] or 0) + 1 end
end
local function portoFound(area)                                 -- finds in one Porto area, from the FoundIds list the server publishes
	local n = 0
	for id in string.gmatch(player:GetAttribute("FoundIds") or "", "[^,]+") do if AREA_OF[id] == area then n += 1 end end
	return n
end
local function unlocked(a)
	if a.needs == "porto" then return (player:GetAttribute("Item_porto") or 0) >= 1 end
	if a.needs == "porto_inner" then                            -- the town and the groves: the More Squirrels Coming Soon wall's rule (ComingSoonServer)
		local w = workspace:FindFirstChild("ComingSoonWall")
		return (player:GetAttribute("Item_porto") or 0) >= 1 and (not w or w:GetAttribute("Enabled") == false
			or player.UserId == game.CreatorId or (player:GetAttribute("Found_porto") or 0) >= 15)
	end
	return (not a.needs) or (player:GetAttribute("Found_" .. a.needs) or 0) >= NEED
end
]], 'unlocked + portoFound')

rep([[	for _, a in ipairs(AREAS) do
		if pos.X >= a.x0 and pos.X <= a.x1 and pos.Z >= a.z0 and pos.Z <= a.z1 then return a end
	end
]], [[	for _, a in ipairs(AREAS) do
		for _, r in ipairs(a.rects) do
			if pos.X >= r[1] and pos.X <= r[3] and pos.Z >= r[2] and pos.Z <= r[4] then return a end
		end
	end
]], 'areaAt rects')

-- 3. the chart image and the world it covers
rep('local MAP_ID = 126434655912945\n',
'local MAP_ID = 126434655912945                                   -- the first world chart (France + the harbour), until Oct 8 2026\n' ..
'local MAP_TILES = {{id = 76679301986389, y0 = 0, h = 712}, {id = 121118886486203, y0 = 712, h = 711}}   -- Oct 8 2026: world chart v2 (make_map_world2.py), rows 0..711 and 712..1422\n',
'MAP_TILES')
rep('local IMG_W, IMG_H, IMG_M = 1024, 900, 26                     -- the image, and the margin its world area starts at\n',
'local IMG_W, IMG_H, IMG_M = 1024, 1423, 26                    -- the image (v2: all of Porto Nocciola), and the margin its world area starts at\n', 'IMG_H')
rep('local WX0, WX1, WZ0, WZ1 = -130, 700, -700, 30                -- the world the image covers (make_map_world.py)\n',
'local WX0, WX1, WZ0, WZ1 = -130, 820, -1310, 30               -- the world the image covers (make_map_world2.py)\n', 'WX/WZ')
rep('local chart = Instance.new("ImageLabel"); chart.Name = "Chart"; chart.BackgroundTransparency = 1; chart.Image = "rbxassetid://" .. MAP_ID\nchart.ScaleType = Enum.ScaleType.Stretch; chart.Parent = view\n',
[[-- the chart is 1024 x 1423, taller than one Roblox image may be, so it is two tiles stacked (the top one a pixel deeper, under the
-- bottom one, so no seam opens at any zoom); the tiles come first so the covers, names and the dot draw over them
local chart = Instance.new("Frame"); chart.Name = "Chart"; chart.BackgroundTransparency = 1; chart.BorderSizePixel = 0; chart.Parent = view
for i, t in ipairs(MAP_TILES) do
	local tile = Instance.new("ImageLabel"); tile.Name = "Tile" .. i; tile.BackgroundTransparency = 1; tile.BorderSizePixel = 0
	tile.Image = "rbxassetid://" .. t.id; tile.ScaleType = Enum.ScaleType.Stretch
	tile.Position = UDim2.fromScale(0, t.y0 / IMG_H); tile.Size = UDim2.fromScale(1, (t.h + (i < #MAP_TILES and 1 or 0)) / IMG_H)
	tile.Parent = chart
end
]], 'chart tiles')

-- 4. one cover per rect; the name plate on the first
local a1 = s:find('local cards = {}\n', 1, true)
local _, b1 = s:find('\tcards[a.id] = card\nend\n', 1, true)
assert(a1 and b1 and b1 > a1, 'cards block')
s = s:sub(1, a1 - 1) .. [[local cards = {}
for _, a in ipairs(AREAS) do
	local card = {open = false}
	for i, r in ipairs(a.rects) do                                -- Porto's areas are several rects; each gets a cover, the first the name plate
		local holder = Instance.new("Frame"); holder.Name = i == 1 and a.id or (a.id .. "_" .. i); holder.BackgroundTransparency = 1; holder.Parent = chart
		-- the cover that hides an area you have not reached
		local cover = Instance.new("Frame"); cover.Name = "Cover"; cover.Size = UDim2.fromScale(1, 1); cover.BackgroundColor3 = C(226, 208, 166)
		cover.BorderSizePixel = 0; cover.Parent = holder
		local cs = Instance.new("UIStroke"); cs.Color = C(150, 118, 74); cs.Thickness = 2; cs.Parent = cover
		local q = Instance.new("TextLabel"); q.Size = UDim2.fromScale(1, 1); q.BackgroundTransparency = 1; q.Font = Enum.Font.Antique
		q.TextSize = 44; q.TextColor3 = C(126, 96, 58); q.Text = "?"; q.Parent = cover
		local plate
		if i == 1 then
			-- the name plate for an area you have reached
			plate = Instance.new("Frame"); plate.Name = "Plate"; plate.AnchorPoint = Vector2.new(0.5, 0); plate.Position = UDim2.new(0.5, 0, 0, 4)
			plate.Size = UDim2.fromOffset(190, 34); plate.BackgroundColor3 = C(248, 240, 214); plate.BackgroundTransparency = 0.12
			plate.BorderSizePixel = 0; plate.Parent = holder
			local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 6); pc.Parent = plate
			local pstroke = Instance.new("UIStroke"); pstroke.Color = C(150, 118, 74); pstroke.Thickness = 1; pstroke.Parent = plate
			local title = Instance.new("TextLabel"); title.Name = "Title"; title.Size = UDim2.new(1, -6, 0, 17); title.Position = UDim2.new(0, 3, 0, 2)
			title.BackgroundTransparency = 1; title.Font = Enum.Font.Antique; title.TextSize = 15; title.TextColor3 = C(88, 58, 32)
			title.TextTruncate = Enum.TextTruncate.AtEnd; title.Parent = plate
			local tally = Instance.new("TextLabel"); tally.Name = "Tally"; tally.Size = UDim2.new(1, -6, 0, 13); tally.Position = UDim2.new(0, 3, 0, 18)
			tally.BackgroundTransparency = 1; tally.Font = Enum.Font.FredokaOne; tally.TextSize = 12; tally.TextColor3 = C(120, 84, 44); tally.Parent = plate
			card.cover, card.plate, card.title, card.tally = cover, plate, title, tally
		end
		table.insert(layouts, function()
			local x0, z0 = toCanvas(r[1], r[2]); local x1, z1 = toCanvas(r[3], r[4])
			holder.Position = UDim2.fromOffset(x0, z0); holder.Size = UDim2.fromOffset(x1 - x0, z1 - z0)
			if plate then
				plate.Size = UDim2.fromOffset(math.max(70, math.min(x1 - x0 - 8, 190)), 34)
				plate.Visible = card.open and (x1 - x0) > 80            -- too small to read: the chart speaks for itself
			end
			cover.Visible = not card.open
			q.TextSize = math.clamp(44 * zoom, 16, 72)
			q.Visible = (x1 - x0) > 24 and (z1 - z0) > 24              -- no "?" squeezed into a sliver
		end)
	end
	cards[a.id] = card
end
]] .. s:sub(b1 + 1)
log('patched', 'cards per rect')

-- 5. tallies
rep([[			if a.id == "porto" then
				card.tally.Text = "harbour coming soon"
			else
				local found = player:GetAttribute("Found_" .. a.id) or 0
				card.tally.Text = string.format("%d / %d found", found, TOTAL[a.id] or 0)
			end
]], [[			local found = a.porto and portoFound(a.porto) or (player:GetAttribute("Found_" .. a.id) or 0)
			card.tally.Text = string.format("%d / %d found", found, TOTAL[a.id] or 0)
]], 'tallies')
rep([[	if a.needs == "porto" then player:GetAttributeChangedSignal("Item_porto"):Connect(refreshMap)
	elseif a.needs then player:GetAttributeChangedSignal("Found_" .. a.needs):Connect(refreshMap) end
	player:GetAttributeChangedSignal("Found_" .. a.id):Connect(refreshMap)
end
]], [[	if a.needs == "porto" or a.needs == "porto_inner" then player:GetAttributeChangedSignal("Item_porto"):Connect(refreshMap)
	elseif a.needs then player:GetAttributeChangedSignal("Found_" .. a.needs):Connect(refreshMap) end
	if not a.porto then player:GetAttributeChangedSignal("Found_" .. a.id):Connect(refreshMap) end
end
player:GetAttributeChangedSignal("FoundIds"):Connect(refreshMap)          -- Porto's per-area tallies
player:GetAttributeChangedSignal("Found_porto"):Connect(refreshMap)       -- the town + groves unlock
]], 'signals')

-- 6. "You are here: Porto Nocciola · The Groves"
rep('here.Text = a and ("You are here: " .. (a.name or NAME[a.id] or a.id)) or "You are here"',
'here.Text = a and ("You are here: " .. (a.long or a.name or NAME[a.id] or a.id)) or "You are here"', 'here text')

-- parse check, then backup + write
local m = Instance.new('ModuleScript') m.Source = 'if true then return 0 end\n' .. s m.Parent = game.ServerStorage
local okp, err = pcall(require, m) m:Destroy()
if not okp then return 'QM@ABORT parse ' .. tostring(err) .. '\n' .. table.concat(LOG, '\n') end
local bk = game.ServerStorage:FindFirstChild('HudBackup') or Instance.new('Folder', game.ServerStorage) bk.Name = 'HudBackup'
if not bk:FindFirstChild('HudBarClient_before_map2_oct8') then local c = scr:Clone() c.Name = 'HudBarClient_before_map2_oct8' c.Enabled = false c.Parent = bk end
scr.Source = s
game:GetService('ChangeHistoryService'):SetWaypoint('World chart v2 + Porto areas on the map')
log('QM@OK new length', #s)
return table.concat(LOG, '\n')
