-- The backpack. Acorn Store: "Backpack - carry your things, and your favourite squirrel, on your back." (900 acorns,
-- once.) The one worn thing everyone else can see, which is why it costs what it does.
--
-- When a player who owns one (Item_backpack > 0) spawns, or the moment they buy it, the server dresses their
-- character: a canvas bag on the UpperTorso (Torso on R6) with straps, buckles, a side pocket with an acorn poking
-- out, and riding in the top, a small copy of one of their squirrels - their favourite (the player attribute
-- BackpackPal, a squirrel id) or, until they have picked one, the first of their finds by name. Everything is
-- massless and welded, so nothing about movement changes. The passenger can be chosen from any found squirrel's card
-- (Item_pal_<id> = 1 in the ledger) and the bag can be taken off and put back on (Item_bagoff = 1 while off), from the
-- store's backpack row; both save with the rest of the progress through AwardItems.
-- Run in edit mode (re-runnable).
return function(opts)
	opts = opts or {}
	local F = workspace:FindFirstChild("BackpackWear")
	if not F then F = Instance.new("Folder"); F.Name = "BackpackWear"; F.Parent = workspace end
	if F:GetAttribute("PalScale") == nil or opts.palScale then F:SetAttribute("PalScale", opts.palScale or 0.42) end
	F:SetAttribute("FixedPal", nil)
	F:SetAttribute("AllowedPals", opts.allowedPals or "spy_squirrel")                          -- the squirrels that ride: just the spy (Shannon, Sep 24: "keep it simple")
	for _, n in ipairs({"BackpackServer", "BackpackClient"}) do local old = F:FindFirstChild(n); if old then old:Destroy() end end
	for _, n in ipairs({"SetPal", "ToggleWear"}) do if not F:FindFirstChild(n) then local e = Instance.new("RemoteEvent"); e.Name = n; e.Parent = F end end

	local SERVER = [==[
-- BackpackServer: dresses owners on spawn and on purchase
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local F = script.Parent
local C = Color3.fromRGB
local CANVAS, CANVAS_DARK, LEATHER, BRASS, NUT, CAP = C(152, 118, 76), C(122, 92, 58), C(84, 56, 34), C(218, 178, 88), C(196, 136, 66), C(120, 78, 40)

local function part(parent, name, size, colour, material, shape)
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.Color = colour; p.Material = material or Enum.Material.Fabric
	p.Anchored = false; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Massless = true; p.CastShadow = true
	if shape then p.Shape = shape end
	p.Parent = parent
	return p
end
local RS = game:GetService("ReplicatedStorage")
local awardItems = RS:WaitForChild("AwardItems")
local function allowedList()
	local t = {}
	for id in string.gmatch(F:GetAttribute("AllowedPals") or "", "[^,%s]+") do t[#t + 1] = id end
	return t
end
local function isAllowed(id) for _, a in ipairs(allowedList()) do if a == id then return true end end return false end
-- where each passenger sits: lift = the share of its height above the rim's centre line, back = a nudge away from the spine
local SEAT = {baking_betty_squirrel = {lift = 0.4, back = 0.08}}
local function seatFor(id) return SEAT[id] or {lift = 0.25, back = 0} end
local function hasFound(player, id)
	for f in string.gmatch(player:GetAttribute("FoundIds") or "", "[^,]+") do if f == id then return true end end
	return false
end
local function palChoice(player)                              -- the chosen passenger: the Item_pal_<id> that is 1
	for name, v in pairs(player:GetAttributes()) do
		if name:sub(1, 9) == "Item_pal_" and (tonumber(v) or 0) > 0 then return name:sub(10) end
	end
	return nil
end
local function bagOff(player) return (player:GetAttribute("Item_bagoff") or 0) > 0 end
-- the squirrel to ride along: the chosen one, else the first find by name; a small copy of its coloured mesh
local function palFor(player)
	-- the chosen passenger if it is allowed, else the first allowed squirrel they have found (by name), else the first allowed
	local allowed = allowedList()
	local want = palChoice(player)
	if want and not isAllowed(want) then want = nil end
	if not want then
		local ids = {}
		for id in string.gmatch(player:GetAttribute("FoundIds") or "", "[^,]+") do if isAllowed(id) then ids[#ids + 1] = id end end
		table.sort(ids)
		want = ids[1] or allowed[1]
	end
	local ids = {}
	for id in string.gmatch(player:GetAttribute("FoundIds") or "", "[^,]+") do ids[#ids + 1] = id end
	table.sort(ids)
	local id = (type(want) == "string" and #want > 0) and want or nil
	if not id then return nil end
	local model
	for _, m in ipairs(CollectionService:GetTagged("Squirrel")) do
		if m:IsA("Model") and not m.Name:lower():find("gray") and (m:GetAttribute("SquirrelId") == id or m.Name:lower():gsub("_color$", "") == id) then model = m; break end
	end
	if not model then model = workspace:FindFirstChild(id .. "_color") end
	local mesh = model and (model:FindFirstChild("Squirrel", true) or model:FindFirstChildWhichIsA("MeshPart", true))
	return mesh, id
end
local function dress(player)
	local char = player.Character
	if not char or (player:GetAttribute("Item_backpack") or 0) <= 0 or bagOff(player) then return end
	if char:FindFirstChild("WornBackpack") then return end
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	if not torso then return end
	local r15 = char:FindFirstChild("UpperTorso") ~= nil
	local bag = Instance.new("Model"); bag.Name = "WornBackpack"
	-- the bag body, behind the torso (+z is the character's back)
	local body = part(bag, "Body", Vector3.new(1.7, 1.9, 0.8), CANVAS)
	local flap = part(bag, "Flap", Vector3.new(1.75, 0.55, 0.86), CANVAS_DARK)
	local pocket = part(bag, "Pocket", Vector3.new(0.5, 0.7, 0.45), CANVAS_DARK)
	local nut = part(bag, "Acorn", Vector3.new(0.34, 0.4, 0.34), NUT, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	local cap = part(bag, "AcornCap", Vector3.new(0.38, 0.16, 0.38), CAP, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	local buckle1 = part(bag, "Buckle", Vector3.new(0.22, 0.16, 0.06), BRASS, Enum.Material.Metal)
	local buckle2 = part(bag, "Buckle", Vector3.new(0.22, 0.16, 0.06), BRASS, Enum.Material.Metal)
	-- offsets from the torso (R15 UpperTorso is about 2 x 1.6 x 1; R6 Torso 2 x 2 x 1)
	local back = 0.95                                                    -- the bag's centre, behind the torso
	local function weld(p, cf) local w = Instance.new("Weld"); w.Part0 = torso; w.Part1 = p; w.C0 = cf; w.Parent = p end
	weld(body, CFrame.new(0, 0.05, back))
	weld(flap, CFrame.new(0, 0.05 + 0.75, back + 0.02))
	weld(pocket, CFrame.new(0.95, -0.25, back))
	weld(nut, CFrame.new(0.95, 0.22, back))
	weld(cap, CFrame.new(0.95, 0.42, back) * CFrame.Angles(0, 0, math.rad(90)))
	weld(buckle1, CFrame.new(-0.45, 0.35, back - 0.42)); weld(buckle2, CFrame.new(0.45, 0.35, back - 0.42))
	-- the straps: five short segments a side that follow the shoulder and lie flat on the body (Shannon: the old
	-- straight slabs "looked like stiff wood sticks"). Points are in torso space (+z back), scaled from the torso.
	local function strapChain(side)
		local W, H, D = torso.Size.X, torso.Size.Y, torso.Size.Z
		local x = side * 0.275 * W
		local ty = 0.5 * H                                                -- the shoulder crest
		local fz, bz = -(0.5 * D + 0.06), 0.5 * D + 0.06                  -- just off the chest / just off the back
		local pts = {
			Vector3.new(x, ty + 0.14, bz + 0.02),                     -- the bag's top edge
			Vector3.new(x, ty + 0.06, 0.12),                          -- shoulder crest, back
			Vector3.new(x, ty + 0.06, -0.2),                          -- shoulder crest, front
			Vector3.new(x, ty - 0.42, fz),                            -- onto the chest
			Vector3.new(x * 0.92, -0.05 * H, fz - 0.02),              -- down the chest
			Vector3.new(x * 0.85, -0.42 * H, fz),                     -- to the waist
		}
		local normals = {Vector3.new(0, 0.55, 0.85), Vector3.new(0, 1, 0), Vector3.new(0, 0.6, -0.8), Vector3.new(0, 0.15, -1), Vector3.new(0, 0, -1)}
		for i = 1, #pts - 1 do
			local a, b = pts[i], pts[i + 1]
			local seg = part(bag, "Strap", Vector3.new(0.3, 0.1, (b - a).Magnitude + 0.1), LEATHER)
			weld(seg, CFrame.lookAt((a + b) / 2, b, normals[i]))         -- flat side along the body's normal
		end
		local chest = part(bag, "Buckle", Vector3.new(0.22, 0.16, 0.06), BRASS, Enum.Material.Metal)
		weld(chest, CFrame.new(x * 0.92, -0.05 * H, fz - 0.07))
	end
	strapChain(-1); strapChain(1)
	-- the passenger
	local mesh, id = palFor(player)
	if mesh then
		local ok, err = pcall(function()
			local pal = mesh:Clone(); pal.Name = "Pal"
			for _, d in ipairs(pal:GetDescendants()) do if not d:IsA("SpecialMesh") and not d:IsA("SurfaceAppearance") then d:Destroy() end end
			local s = F:GetAttribute("PalScale") or 0.42
			-- Every squirrel in the world stands the same body height (SquirrelSetup's TargetHeight; a prop such as the kite
			-- sets its own, taller), so one scale gives every passenger the same body size - props are not shrunk for
			-- (Shannon: the kite squirrel came out too small when they were). Feet stay inside the bag by the seating below.
			local yaw = math.rad(180 + 20)
			pal.Size = mesh.Size * s
			pal.Anchored = false; pal.CanCollide = false; pal.CanQuery = false; pal.CanTouch = false; pal.Massless = true
			pal:SetAttribute("SquirrelId", nil)                     -- not a squirrel to find; just a passenger
			pal.Parent = bag
			-- sitting in the top of the bag, half in, looking forward over the shoulder (the look Shannon liked)
			local seat = seatFor(id)
			weld(pal, CFrame.new(0, 0.05 + 0.95 + pal.Size.Y * seat.lift, back + seat.back) * CFrame.Angles(0, yaw, 0))
		end)
		if not ok then warn("Backpack: could not seat the squirrel (" .. tostring(err) .. ")") end
	end
	bag:SetAttribute("Pal", id or "")
	bag.Parent = char
	local palPart = bag:FindFirstChild("Pal")
	print(string.format("Backpack: %s wears the backpack%s%s", player.Name, id and (" with " .. id) or "", palPart and string.format(" (pal %.2f x %.2f x %.2f)", palPart.Size.X, palPart.Size.Y, palPart.Size.Z) or ""))
end
local function undress(player)
	local char = player.Character; local old = char and char:FindFirstChild("WornBackpack"); if old then old:Destroy() end
end
local pending = {}
local function redress(player)                                -- once, shortly: a swap changes two ledger lines
	if pending[player] then return end
	pending[player] = true
	task.delay(0.15, function() pending[player] = nil; undress(player); dress(player) end)
end
local function watch(player)
	player.CharacterAdded:Connect(function() task.wait(0.5); dress(player) end)
	player:GetAttributeChangedSignal("Item_backpack"):Connect(function() dress(player) end)
	player:GetAttributeChangedSignal("BackpackPal"):Connect(function() redress(player) end)
	player:GetAttributeChangedSignal("Item_bagoff"):Connect(function() if bagOff(player) then undress(player) else dress(player) end end)
	player.AttributeChanged:Connect(function(name) if name:sub(1, 9) == "Item_pal_" then redress(player) end end)
	player:GetAttributeChangedSignal("SaveLoaded"):Connect(function() dress(player) end)
	if player.Character then dress(player) end
end
-- the two asks from the client, checked here: you must own the bag, and only a squirrel you have found may ride
F:WaitForChild("SetPal").OnServerEvent:Connect(function(player, id)
	if type(id) ~= "string" or #id == 0 or #id > 60 or not id:match("^[%w_]+$") then return end
	if (player:GetAttribute("Item_backpack") or 0) <= 0 or not hasFound(player, id) or not isAllowed(id) then return end
	local cur = palChoice(player)
	if cur == id then return end
	if cur then awardItems:Fire(player, "pal_" .. cur, -1) end
	awardItems:Fire(player, "pal_" .. id, 1)
	print(string.format("Backpack: %s chose %s as the passenger", player.Name, id))
end)
F:WaitForChild("ToggleWear").OnServerEvent:Connect(function(player)
	if (player:GetAttribute("Item_backpack") or 0) <= 0 then return end
	awardItems:Fire(player, "bagoff", bagOff(player) and -1 or 1)
	print(string.format("Backpack: %s %s the backpack", player.Name, bagOff(player) and "put on" or "took off"))
end)
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
print("BackpackServer: ready")
]==]
	local CLIENT = [==[
-- BackpackClient: a "Carry in my backpack" button on every found squirrel's card (owners only)
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local F = script.Parent
local setPal = F:WaitForChild("SetPal")
local C = Color3.fromRGB
local okR, Registry = pcall(function() return require(workspace:WaitForChild("SquirrelScripts", 30):WaitForChild("SquirrelRegistry", 30)) end)
if not okR then Registry = {squirrels = {}} end
local function owns() return (player:GetAttribute("Item_backpack") or 0) > 0 end
local function foundIds()
	local ids = {}; for f in string.gmatch(player:GetAttribute("FoundIds") or "", "[^,]+") do ids[#ids + 1] = f end
	return ids
end
local function found(id) for _, f in ipairs(foundIds()) do if f == id then return true end end return false end
local function current()                                      -- the chosen passenger, else the first find by name (as the server does)
	for name, v in pairs(player:GetAttributes()) do
		if name:sub(1, 9) == "Item_pal_" and (tonumber(v) or 0) > 0 then return name:sub(10) end
	end
	local allowed = {}
	for a in string.gmatch(F:GetAttribute("AllowedPals") or "", "[^,%s]+") do allowed[#allowed + 1] = a end
	local ids = {}
	for _, f in ipairs(foundIds()) do for _, a in ipairs(allowed) do if a == f then ids[#ids + 1] = f end end end
	table.sort(ids); return ids[1] or allowed[1]
end
local function idFromTitle(text)
	for _, e in ipairs(Registry.squirrels or {}) do if e.name == text then return e.id end end
	for _, m in ipairs(CollectionService:GetTagged("Squirrel")) do if m:GetAttribute("DisplayName") == text then return m:GetAttribute("SquirrelId") end end
	return nil
end
local function decorate(card)
	local title, bio
	for _, d in ipairs(card:GetDescendants()) do
		if d:IsA("TextLabel") then
			if d.Position.Y.Offset == 368 then title = d elseif d.Position.Y.Offset == 414 then bio = d end
		end
	end
	if not (title and bio) then return end
	local panel = title.Parent
	local id = idFromTitle(title.Text)
	local allowed, count = false, 0
	for a in string.gmatch(F:GetAttribute("AllowedPals") or "", "[^,%s]+") do count += 1; if a == id then allowed = true end end
	if count <= 1 then return end                                   -- one passenger for everyone: nothing to choose
	if not id or not allowed or not owns() or not found(id) then return end      -- only the squirrels that ride get a button
	bio.Size = UDim2.new(1, -44, 0, 96)                          -- room for the button under the bio
	local btn = Instance.new("TextButton"); btn.Name = "CarryButton"; btn.AnchorPoint = Vector2.new(0.5, 0); btn.Position = UDim2.new(0.5, 0, 0, 516); btn.Size = UDim2.fromOffset(250, 36)
	btn.BorderSizePixel = 0; btn.Font = Enum.Font.FredokaOne; btn.TextSize = 17; btn.AutoButtonColor = false; btn.ZIndex = 26; btn.Parent = panel
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = btn
	local st = Instance.new("UIStroke"); st.Color = C(150, 98, 36); st.Thickness = 2; st.Transparency = 0.2; st.Parent = btn
	local function refresh()
		if current() == id then
			btn.Text = "Riding in your backpack"; btn.BackgroundColor3 = C(214, 202, 176); btn.TextColor3 = C(120, 100, 70)
		else
			btn.Text = "Carry in my backpack"; btn.BackgroundColor3 = C(240, 200, 90); btn.TextColor3 = C(84, 48, 18)
		end
	end
	refresh()
	btn.Activated:Connect(function()
		if current() == id then return end
		setPal:FireServer(id); btn.Text = "..."
	end)
	local conn = player.AttributeChanged:Connect(function(name) if name:sub(1, 9) == "Item_pal_" then refresh() end end)
	card.Destroying:Connect(function() conn:Disconnect() end)
end
task.spawn(function()
	local hud = pg:WaitForChild("SquirrelHUD", 180)
	if not hud then return end
	for _, c in ipairs(hud:GetChildren()) do if c.Name == "Card" then task.defer(decorate, c) end end
	hud.ChildAdded:Connect(function(c) if c.Name == "Card" then task.defer(decorate, c) end end)
end)
]==]
	local s = Instance.new("Script"); s.Name = "BackpackServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F
	local c = Instance.new("Script"); c.Name = "BackpackClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
	print("Backpack: dresses owners on spawn; favourite squirrel = player attribute BackpackPal (else the first find)")
end
