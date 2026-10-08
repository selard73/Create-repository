from pathlib import Path
p = Path(__file__).parent / "make_squirrel_scripts.py"
s = p.read_text(encoding="utf-8")

# ---------------------------------------------------------------- registry module ----
REGISTRY = r'''
-- SquirrelRegistry: the one list of every squirrel in the game. Both the server and the HUD read this.
-- id      stable key used for saving finds (the model in the world is named "<id>_color" / "<id>_gray")
-- map     which map the squirrel lives on (see maps below)
-- name    what the tag, badge and card show
-- bio     the card text
-- face    optional badge framing tweaks: dist (camera distance, default 1.35), up (aim height, default 0), camUp (camera height, default 0.05)
-- Add new squirrels here; nothing else needs editing.
return {
	maps = {
		{id = "forest", name = "The Great Acorn Forest"},
	},
	squirrels = {
		{id = "detective_squirrel",    map = "forest", name = "Mr. Holmes Squirrel",   face = {dist = 1.7, up = -0.02},
		 bio = "Solves mysteries nobody asked him to solve. Currently investigating the Case of the Missing Acorn. He ate it."},
		{id = "rainy_day_squirrel",    map = "forest", name = "Rainy Day Squirrel",    face = {dist = 1.6, up = -0.09, camUp = -0.24},
		 bio = "Ready for weather at all times, even indoors. Has never once been caught without her umbrella. Or her spare umbrella."},
		{id = "squirrel_buccaneer",    map = "forest", name = "Buccaneer Squirrel",
		 bio = "Sailed the seven puddles in search of buried acorns. Has a treasure map, but keeps reading it upside down."},
		{id = "squirrel_scientist",    map = "forest", name = "El Scientifico",
		 bio = "Holds three degrees in Acorn Physics and one in Explosions. Every experiment ends with 'well, THAT was interesting.'"},
		{id = "surfing_squirrel",      map = "forest", name = "Surfer Dude Squirrel",
		 bio = "Rides the gnarliest waves in the forest, which are mostly puddles. Says 'dude' more than any squirrel should."},
		{id = "super_squirrel",        map = "forest", name = "Nacho Libre Squirrel",  face = {dist = 1.75, up = -0.04},
		 bio = "Masked defender of the forest and its snacks. Weakness: nachos. Also cheese. Also anything with cheese on it."},
		{id = "gordo_squirrel",        map = "forest", name = "Gordo Squirrel",
		 bio = "Gordo has never met an acorn he didn't like. Or two. Or the whole tree. Hobbies include napping, snacking, and napping after snacking."},
		{id = "fairy_squirrel",        map = "forest", name = "Fairy Squirrel",        face = {dist = 1.5, up = -0.02},
		 bio = "Sprinkles glitter wherever she goes, mostly by accident. Grants wishes on Tuesdays, but only small ones, like finding a really good acorn."},
		{id = "ski_squirrel",          map = "forest", name = "Ski-a-roo Squirrel",
		 bio = "Skis all year round, snow or no snow. Has yet to make it down a hill without hugging a tree."},
		{id = "ballerina_squirrel",    map = "forest", name = "Ballerina Squirrel",
		 bio = "Practices pirouettes on tree branches, to the great alarm of the birds. The tutu is very serious business."},
		{id = "baking_betty_squirrel", map = "forest", name = "Baking Betty Squirrel",
		 bio = "Bakes forty cupcakes a day and eats thirty-nine of them for quality control. Her frosting is legendary. So is her sugar rush."},
	},
}
'''

# ---------------------------------------------------------------- server: use the registry ----
old_start = s.index("local BIO = {")
old_end = s.index("-- 3. set each one up")
s = s[:old_start] + '''-- the registry: names, bios, maps, framing. Edit SquirrelRegistry, not this script.
local Registry = require(folder:WaitForChild("SquirrelRegistry"))
local byId = {}
for _, e in ipairs(Registry.squirrels) do byId[e.id] = e end
local THIS_MAP = folder:GetAttribute("MapId") or "forest"
folder:SetAttribute("MapId", THIS_MAP)
local function baseId(model)
	local n = model.Name:lower():gsub("_color$", ""):gsub("_gray$", "")
	return n
end
''' + s[old_end:]

old = '''	if not model:GetAttribute("DisplayName") then
		local low = model.Name:lower()
		for _, pair in ipairs(NAMES) do
			if low:find(pair[1], 1, true) then model:SetAttribute("DisplayName", pair[2]) break end
		end
	end
	if not model:GetAttribute("Bio") then
		local dn = model:GetAttribute("DisplayName")
		model:SetAttribute("Bio", (dn and BIO[dn]) or "A squirrel of mystery. Nobody knows where they came from, least of all them.")
	end'''
new = '''	local entry = byId[baseId(model)]
	if entry then
		model:SetAttribute("SquirrelId", entry.id)
		if not model:GetAttribute("DisplayName") then model:SetAttribute("DisplayName", entry.name) end
		if not model:GetAttribute("Bio") then model:SetAttribute("Bio", entry.bio or "") end
	else
		warn("SquirrelSetup: " .. model.Name .. " is not in SquirrelRegistry; add it there (id = '" .. baseId(model) .. "')")
		if not model:GetAttribute("SquirrelId") then model:SetAttribute("SquirrelId", baseId(model)) end
		if not model:GetAttribute("Bio") then model:SetAttribute("Bio", "A squirrel of mystery. Nobody knows where they came from, least of all them.") end
	end'''
assert old in s; s = s.replace(old, new)

# ids: registry id wins; the old "make one up from the model name" path only for unknowns
old = '''	local id = model:GetAttribute("SquirrelId")
	if not id or squirrels[id] then
		id = model.Name; local k = 1
		while squirrels[id] do k += 1; id = model.Name .. "_" .. k end
		model:SetAttribute("SquirrelId", id)
	end'''
new = '''	local id = model:GetAttribute("SquirrelId")
	if not id or squirrels[id] then
		id = baseId(model); local k = 1
		while squirrels[id] do k += 1; id = baseId(model) .. "_" .. k end
		model:SetAttribute("SquirrelId", id)
	end'''
assert old in s; s = s.replace(old, new)

# totals: this map from the registry, all maps too
old = '''local total = 0
for _, mesh in ipairs(colours) do setup(mesh); total += 1 end
folder:SetAttribute("Total", total)'''
new = '''local total = 0
for _, mesh in ipairs(colours) do setup(mesh); total += 1 end
folder:SetAttribute("Total", total)
local mapTotal = 0
for _, e in ipairs(Registry.squirrels) do if e.map == THIS_MAP then mapTotal += 1 end end
folder:SetAttribute("MapTotal", mapTotal); folder:SetAttribute("AllTotal", #Registry.squirrels)'''
assert old in s; s = s.replace(old, new)

# migrate finds saved under the old "<id>_color" keys
old = '''			if type(data) == "table" and type(data.found) == "table" then
				for _, id in ipairs(data.found) do t[id] = true end
			end'''
new = '''			if type(data) == "table" and type(data.found) == "table" then
				for _, id in ipairs(data.found) do t[(tostring(id):gsub("_color$", ""))] = true end
			end'''
assert old in s; s = s.replace(old, new)

# ---------------------------------------------------------------- client: registry-driven names, album ----
old = '''local function prettyName(model)
	local dn = model:GetAttribute("DisplayName")
	if dn and dn ~= "" then return dn end
	local n = model.Name:gsub("_color$", ""):gsub("_gray$", ""):gsub("_", " ")
	n = n:gsub("(%a)([%w']*)", function(a, b) return a:upper() .. b end)
	return n
end'''
new = '''local Registry = require(script.Parent:WaitForChild("SquirrelRegistry"))
local regById, regOrder = {}, {}
for i, e in ipairs(Registry.squirrels) do regById[e.id] = e; regOrder[e.id] = i end
local function idOf(model) return model:GetAttribute("SquirrelId") or (model.Name:lower():gsub("_color$", "")) end
local function prettyName(model)
	local dn = model:GetAttribute("DisplayName")
	if dn and dn ~= "" then return dn end
	local e = regById[idOf(model)]
	if e then return e.name end
	local n = model.Name:gsub("_color$", ""):gsub("_gray$", ""):gsub("_", " ")
	n = n:gsub("(%a)([%w']*)", function(a, b) return a:upper() .. b end)
	return n
end
local foundIds = {}        -- every id this player has found, on any map (from the server)'''
assert old in s; s = s.replace(old, new)

# face tweaks from the registry
old = '''local FACE = {
	["Nacho Libre Squirrel"] = {dist = 1.75, up = -0.04},
	["Mr. Holmes Squirrel"]  = {dist = 1.7, up = -0.02},
	["Fairy Squirrel"]       = {dist = 1.5, up = -0.02},
	["Rainy Day Squirrel"]   = {dist = 1.6, up = -0.09, camUp = -0.24},
}'''
new = '''local FACE = setmetatable({}, {__index = function(_, name)
	for _, e in ipairs(Registry.squirrels) do if e.name == name and e.face then return e.face end end
	return nil
end})'''
assert old in s; s = s.replace(old, new)

# counter: here / total
old = '''	local total = script.Parent:GetAttribute("Total") or n
	counter.Text = string.format("Squirrels found  %d / %d", n, math.max(total, n))'''
new = '''	local total = script.Parent:GetAttribute("MapTotal") or script.Parent:GetAttribute("Total") or n
	local all = 0
	for _ in pairs(foundIds) do all += 1 end
	counter.Text = string.format("Found here  %d / %d      All maps  %d / %d", n, math.max(total, n), math.max(all, n), script.Parent:GetAttribute("AllTotal") or total)'''
assert old in s; s = s.replace(old, new)

# badge order from the registry
old = '''	table.sort(list, function(a, b) return prettyName(a.model) < prettyName(b.model) end)'''
new = '''	table.sort(list, function(a, b) return (regOrder[idOf(a.model)] or 999) < (regOrder[idOf(b.model)] or 999) end)'''
assert old in s; s = s.replace(old, new)

# initial sync fills foundIds
old = '''	local list = sync and sync:InvokeServer() or {}
	local foundSet = {}
	for _, id in ipairs(list) do foundSet[id] = true end'''
new = '''	local list = sync and sync:InvokeServer() or {}
	local foundSet = {}
	for _, id in ipairs(list) do foundSet[id] = true; foundIds[id] = true end'''
assert old in s; s = s.replace(old, new)
old = '''	ev.OnClientEvent:Connect(function(id)
		local model, st = byId(id)
		if model and not st.found then reveal(model, st) end
	end)'''
new = '''	ev.OnClientEvent:Connect(function(id)
		foundIds[id] = true
		local model, st = byId(id)
		if model and not st.found then reveal(model, st) end
		updateCounter()
	end)'''
assert old in s; s = s.replace(old, new)

# ---------------------------------------------------------------- album ----
old = '''local badgeOrder = 0
local CIRCLE = 52'''
new = '''-- ---- the album: every squirrel on every map, opened from the "Album" button ----
local album
local function closeAlbum() if album then album:Destroy(); album = nil end end
local function openAlbum()
	closeAlbum(); ensureHud()
	album = Instance.new("Frame"); album.Name = "Album"; album.Size = UDim2.fromScale(1, 1); album.BackgroundColor3 = Color3.new(0, 0, 0)
	album.BackgroundTransparency = 0.45; album.ZIndex = 30; album.Parent = hud
	local backdrop = Instance.new("TextButton"); backdrop.Size = UDim2.fromScale(1, 1); backdrop.BackgroundTransparency = 1; backdrop.Text = ""
	backdrop.ZIndex = 30; backdrop.Parent = album; backdrop.MouseButton1Click:Connect(closeAlbum)
	local panel = Instance.new("Frame"); panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(0, 560, 0.8, 0); panel.BackgroundColor3 = PANEL; panel.ZIndex = 31; panel.Parent = album
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 22); pc.Parent = panel
	local ps = Instance.new("UIStroke"); ps.Thickness = 3; ps.Color = Color3.fromRGB(255, 205, 90); ps.Parent = panel
	local title = Instance.new("TextLabel"); title.Size = UDim2.new(1, -80, 0, 44); title.Position = UDim2.new(0, 24, 0, 12)
	title.BackgroundTransparency = 1; title.TextXAlignment = Enum.TextXAlignment.Left; title.TextSize = 26
	title.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.ExtraBold); title.TextColor3 = Color3.fromRGB(255, 232, 170)
	local all, allTotal = 0, script.Parent:GetAttribute("AllTotal") or #Registry.squirrels
	for _ in pairs(foundIds) do all += 1 end
	title.Text = string.format("Squirrel Album   %d / %d", all, allTotal); title.ZIndex = 32; title.Parent = panel
	local close = Instance.new("TextButton"); close.Size = UDim2.fromOffset(34, 34); close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -12, 0, 12); close.BackgroundColor3 = Color3.fromRGB(255, 205, 90); close.Text = "x"
	close.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold); close.TextSize = 20; close.TextColor3 = PANEL
	close.ZIndex = 33; close.Parent = panel
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(1, 0); cc.Parent = close
	close.MouseButton1Click:Connect(closeAlbum)
	local scroll = Instance.new("ScrollingFrame"); scroll.Position = UDim2.new(0, 16, 0, 64); scroll.Size = UDim2.new(1, -32, 1, -80)
	scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 6; scroll.ZIndex = 32
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.CanvasSize = UDim2.new(); scroll.Parent = panel
	local list = Instance.new("UIListLayout"); list.Padding = UDim.new(0, 10); list.SortOrder = Enum.SortOrder.LayoutOrder; list.Parent = scroll
	-- squirrels present on this map, by id, for faces and cards
	local here = {}
	for model, st in pairs(squirrels) do here[idOf(model)] = {model = model, st = st} end
	for mi, map in ipairs(Registry.maps) do
		local mapFound, mapTotal = 0, 0
		for _, e in ipairs(Registry.squirrels) do if e.map == map.id then mapTotal += 1; if foundIds[e.id] then mapFound += 1 end end end
		local section = Instance.new("Frame"); section.Size = UDim2.new(1, 0, 0, 0); section.AutomaticSize = Enum.AutomaticSize.Y
		section.BackgroundTransparency = 1; section.LayoutOrder = mi; section.ZIndex = 32; section.Parent = scroll
		local head = Instance.new("TextLabel"); head.Size = UDim2.new(1, 0, 0, 24); head.BackgroundTransparency = 1
		head.TextXAlignment = Enum.TextXAlignment.Left; head.TextSize = 17; head.ZIndex = 32
		head.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold); head.TextColor3 = Color3.fromRGB(255, 255, 255)
		head.Text = string.format("%s   %d / %d", map.name, mapFound, mapTotal); head.Parent = section
		local grid = Instance.new("Frame"); grid.Position = UDim2.new(0, 0, 0, 28); grid.Size = UDim2.new(1, 0, 0, 0)
		grid.AutomaticSize = Enum.AutomaticSize.Y; grid.BackgroundTransparency = 1; grid.ZIndex = 32; grid.Parent = section
		local gl = Instance.new("UIGridLayout"); gl.CellSize = UDim2.fromOffset(62, 76); gl.CellPadding = UDim2.fromOffset(6, 4)
		gl.SortOrder = Enum.SortOrder.LayoutOrder; gl.Parent = grid
		local order = 0
		for _, e in ipairs(Registry.squirrels) do
			if e.map == map.id then
				order += 1
				local cell = Instance.new("Frame"); cell.BackgroundTransparency = 1; cell.LayoutOrder = order; cell.ZIndex = 32; cell.Parent = grid
				local isFound = foundIds[e.id] == true
				local box, disc, mask, rs = circleWindow(cell, CIRCLE, 33, isFound and Color3.fromRGB(255, 248, 225) or Color3.fromRGB(60, 58, 70))
				rs.Color = isFound and Color3.fromRGB(255, 205, 90) or Color3.fromRGB(120, 116, 130)
				local h = here[e.id]
				if isFound and h then
					makeViewport(box, h.st, faceCamera(h.st))
				else
					local q = Instance.new("TextLabel"); q.Size = UDim2.fromScale(1, 1); q.BackgroundTransparency = 1
					q.Text = isFound and e.name:sub(1, 1) or "?"; q.TextSize = isFound and 26 or 30
					q.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.ExtraBold)
					q.TextColor3 = isFound and PANEL or Color3.fromRGB(200, 196, 210); q.ZIndex = 35; q.Parent = box
				end
				local name = Instance.new("TextLabel"); name.Size = UDim2.new(1, 0, 0, 22); name.Position = UDim2.new(0, 0, 0, CIRCLE + 1)
				name.BackgroundTransparency = 1; name.Text = isFound and e.name or ""; name.TextWrapped = true; name.TextScaled = true
				name.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold); name.TextColor3 = Color3.fromRGB(255, 255, 255)
				name.ZIndex = 34; name.Parent = cell
				local nc = Instance.new("UITextSizeConstraint"); nc.MaxTextSize = 10; nc.MinTextSize = 7; nc.Parent = name
				if isFound and h then
					local btn = Instance.new("TextButton"); btn.Size = UDim2.fromScale(1, 1); btn.BackgroundTransparency = 1; btn.Text = ""
					btn.ZIndex = 40; btn.Parent = cell
					btn.MouseButton1Click:Connect(function() closeAlbum(); openCard(h.model, h.st) end)
				end
			end
		end
	end
	local sc = Instance.new("UIScale"); sc.Scale = 0.85; sc.Parent = panel
	TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end

local badgeOrder = 0
local CIRCLE = 52'''
assert old in s; s = s.replace(old, new)

# album button in the HUD panel (next to the counter)
old = '''	local cs = Instance.new("UIStroke"); cs.Thickness = 1.5; cs.Color = Color3.fromRGB(0, 0, 0); cs.LineJoinMode = Enum.LineJoinMode.Round; cs.Parent = counter'''
new = '''	local cs = Instance.new("UIStroke"); cs.Thickness = 1.5; cs.Color = Color3.fromRGB(0, 0, 0); cs.LineJoinMode = Enum.LineJoinMode.Round; cs.Parent = counter
	local albumBtn = Instance.new("TextButton"); albumBtn.Size = UDim2.new(1, 0, 0, 24); albumBtn.BackgroundColor3 = Color3.fromRGB(255, 205, 90)
	albumBtn.Text = "Open Album"; albumBtn.TextSize = 14; albumBtn.TextColor3 = PANEL; albumBtn.LayoutOrder = 3
	albumBtn.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold); albumBtn.Parent = panel
	local ac = Instance.new("UICorner"); ac.CornerRadius = UDim.new(0, 12); ac.Parent = albumBtn
	albumBtn.MouseButton1Click:Connect(function() if album then closeAlbum() else openAlbum() end end)'''
assert old in s; s = s.replace(old, new)
# CIRCLE and circleWindow are used by openAlbum, which is defined earlier: forward-declare them
old = "local ensureHud, updateCounter, addBadge, fillBadge, ensureBadges, openCard, closeCard, nameTag, faceCamera, makeViewport   -- defined below\n"
new = "local ensureHud, updateCounter, addBadge, fillBadge, ensureBadges, openCard, closeCard, nameTag, faceCamera, makeViewport, circleWindow, openAlbum, closeAlbum   -- defined below\nlocal CIRCLE = 52\n"
assert old in s; s = s.replace(old, new)
s = s.replace("local badgeOrder = 0\nlocal CIRCLE = 52", "local badgeOrder = 0")
s = s.replace("local function circleWindow(parent, size, z, discColor)", "circleWindow = function(parent, size, z, discColor)")
s = s.replace("local album\nlocal function closeAlbum() if album then album:Destroy(); album = nil end end\nlocal function openAlbum()",
              "local album\ncloseAlbum = function() if album then album:Destroy(); album = nil end end\nopenAlbum = function()")

# ---------------------------------------------------------------- bundle: add the module ----
old = '''<Properties><string name="Name">SquirrelScripts</string></Properties>{script_item("SquirrelSetup", SETUP, 1, "RBX1")}{script_item("SquirrelAnim", ANIM, 2, "RBX2")}'''
new = '''<Properties><string name="Name">SquirrelScripts</string></Properties>{module_item("SquirrelRegistry", REGISTRY, "RBX3")}{script_item("SquirrelSetup", SETUP, 1, "RBX1")}{script_item("SquirrelAnim", ANIM, 2, "RBX2")}'''
assert old in s; s = s.replace(old, new)
old = '''def script_item(name, source, run_context, ref):'''
new = '''REGISTRY = r\'\'\'''' + REGISTRY + '''\'\'\'

def module_item(name, source, ref):
    return f\'\'\'
  <Item class="ModuleScript" referent="{ref}">
    <Properties>
      <string name="Name">{name}</string>
      <ProtectedString name="Source"><![CDATA[{source}]]></ProtectedString>
    </Properties>
  </Item>\'\'\'

def script_item(name, source, run_context, ref):'''
assert old in s; s = s.replace(old, new, 1)
p.write_text(s, encoding="utf-8"); print("patched")
