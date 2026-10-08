-- Oct 4 2026: the crab trap becomes a hotbar Tool + Equip/Store in the Acorn Store (Shannon: "yes please").
-- Needs the imported icon carrier (workspace.icon_carrier / CrabIconCarrier MeshPart) for the hotbar picture.
-- Exact-anchor edits; a missing anchor warns and skips that one; never inserts twice. No asserts after the first edit.
local RS=game.ReplicatedStorage local SS=game.ServerStorage
local kit=RS:FindFirstChild('CrabGame')
if not (kit and kit:FindFirstChild('Trap')) then warn('QH@ABORT no CrabGame kit') return end
local carrier=workspace:FindFirstChild('CrabIconCarrier',true)
local ICON=(carrier and carrier:IsA('MeshPart') and carrier.TextureID) or (SS:FindFirstChild('CrabTrapTool') and SS.CrabTrapTool.TextureId) or ''
if ICON=='' then warn('QH@ABORT no icon texture yet') return end
local carModel=workspace:FindFirstChild('icon_carrier') if carModel then carModel:Destroy() elseif carrier then carrier:Destroy() end

-- the trap a little smaller, held and flying alike
local trap=kit.Trap
if not trap:GetAttribute('Scaled') then pcall(function() trap:ScaleTo(0.8) end) trap:SetAttribute('Scaled',0.8) end
-- the Tool: an invisible handle at the hoop's top, the trap hanging below it
local old=SS:FindFirstChild('CrabTrapTool') if old then old:Destroy() end
local tool=Instance.new('Tool') tool.Name='CrabTrapTool' tool.ToolTip='Crab trap' tool.CanBeDropped=false tool.RequiresHandle=true
tool.TextureId=ICON
local body=trap:Clone()
local fr=body.TrapFrame
local s=fr.Size
-- the trap's own axis is its shortest side (hoops are round); hang it with the hoops facing forward, axis along the arm's side
local axis=(s.X<s.Y and s.X<s.Z) and Vector3.xAxis or ((s.Z<s.Y) and Vector3.zAxis or Vector3.yAxis)
local h=Instance.new('Part') h.Name='Handle' h.Size=Vector3.new(0.35,0.35,0.35) h.Transparency=1 h.CanCollide=false h.CanQuery=false h.CanTouch=false h.Massless=true
local r=math.max(s.X,s.Y,s.Z)/2
-- body placed so its centre is r+0.05 under the handle, its axis along the handle's X
local rot=CFrame.fromMatrix(Vector3.zero, axis, (axis==Vector3.yAxis) and Vector3.zAxis or Vector3.yAxis)   -- local frame with X = trap axis
h.CFrame=CFrame.new(0,100,0)
body:PivotTo(h.CFrame*CFrame.new(0,-(r+0.05),0)*rot:Inverse())
for _,v in ipairs(body:GetDescendants()) do
	if v:IsA('BasePart') then
		v.Anchored=false v.Massless=true v.CanCollide=false v.CanQuery=false v.CanTouch=false
		local w=Instance.new('WeldConstraint') w.Part0=h w.Part1=v w.Parent=v
		v.Parent=tool
	end
end
body:Destroy()
h.Parent=tool
tool.Grip=CFrame.new(0,0,0)
tool.Parent=SS

-- Equip / Store
local re=RS:FindFirstChild('HotbarStow') if not re then re=Instance.new('RemoteEvent') re.Name='HotbarStow' re.Parent=RS end
local oldS=workspace.Shop:FindFirstChild('StowServer') if oldS then oldS:Destroy() end
local stow=Instance.new('Script') stow.Name='StowServer' stow.Source=[==[-- StowServer (workspace.Shop): Equip / Store for the things you own that ride in the hotbar (Oct 4 2026, Shannon: "On the
-- acorn store, if you bought something, you should have a button to equip (which puts it at the bottom of the screen) or
-- store (which would take it off the bottom of the screen)"). Storing is saved like any item: Item_stow_<id> = 1 through
-- AwardItems. Each tool's own giver (SlingServer, BinocularsServer, CrabServer) skips a stored tool and hands it back the
-- moment it is equipped again (they watch Item_stow_<id>); storing takes it out of the backpack and the hand here.
local RS = game:GetService("ReplicatedStorage")
local awardItems = RS:WaitForChild("AwardItems")
local ev = RS:WaitForChild("HotbarStow")
local TOOLS = {binoculars = "Binoculars", slingshot = "Slingshot", crabtrap = "Crab trap"}

ev.OnServerEvent:Connect(function(p, id, stow)
	local toolName = type(id) == "string" and TOOLS[id]
	if not toolName then return end
	if (p:GetAttribute("Item_" .. id) or 0) <= 0 then return end          -- only what is yours
	local cur = p:GetAttribute("Item_stow_" .. id) or 0
	local want = stow == true and 1 or 0
	if cur ~= want then awardItems:Fire(p, "stow_" .. id, want - cur) end
	if want == 1 then
		local pack = p:FindFirstChildOfClass("Backpack")
		local t = pack and pack:FindFirstChild(toolName)
		if t then t:Destroy() end
		t = p.Character and p.Character:FindFirstChild(toolName)
		if t and t:IsA("Tool") then t:Destroy() end
	end
end)
print("StowServer: ready")
]==] stow.Parent=workspace.Shop

local function insert(scr,anchor,add,dupKey,after)
	local src=scr.Source
	if src:find(dupKey,1,true) then warn('QH@SKIP already',scr:GetFullName(),dupKey) return true end
	local a,b=src:find(anchor,1,true)
	if not a then warn('QH@MISSING',scr:GetFullName(),anchor:sub(1,40)) return false end
	if after then scr.Source=src:sub(1,b)..add..src:sub(b+1) else scr.Source=src:sub(1,a-1)..add..src:sub(a) end
	return true
end
local res={}
-- givers: skip a stored tool, hand it back when equipped again
for _,g in ipairs({{workspace.Hoop.SlingServer,'slingshot'},{workspace.Binoculars.BinocularsServer,'binoculars'}}) do
	local scr,id=g[1],g[2]
	table.insert(res,insert(scr,'\tif (player:GetAttribute("Item_'..id..'") or 0) <= 0 then return end\n\tlocal char = player.Character\n',
		'\tif (player:GetAttribute("Item_stow_'..id..'") or 0) > 0 then return end   -- put away from the Acorn Store (StowServer, Oct 4 2026)\n',
		'Item_stow_'..id..'") or 0) > 0 then return end',false))
	-- (insert BEFORE the char line: place it between the two anchor lines)
	table.insert(res,insert(scr,'\tplayer:GetAttributeChangedSignal("Item_'..id..'"):Connect(function() give(player) end)\n',
		'\tplayer:GetAttributeChangedSignal("Item_stow_'..id..'"):Connect(function() give(player) end)\n',
		'GetAttributeChangedSignal("Item_stow_'..id..'")',true))
end
-- the store: Equip / Store buttons
local SC=workspace.Shop.ShopClient
table.insert(res,insert(SC,'local busy = false\nlocal function attempt(',
[[-- EQUIP / STORE (Oct 4 2026, Shannon): what you own that rides in the hotbar gets two buttons instead of "owned"
local HOTBAR = {binoculars = true, slingshot = true, crabtrap = true}
local function stowIt(item, rec, stow)
	local e = RS:FindFirstChild("HotbarStow")
	if not e then say(rec, "not ready yet", false) return end
	e:FireServer(item.id, stow)
	say(rec, stow and "stored - off your hotbar" or "equipped - on your hotbar", true)
end
]],'local HOTBAR = {',false))
table.insert(res,insert(SC,'\trec.btn = btn\n',
[[	if HOTBAR[item.id] then
		local b2 = Instance.new("TextButton")
		b2.AnchorPoint = Vector2.new(1, 0); b2.Position = UDim2.new(1, -12, 0, 106)
		b2.Size = UDim2.fromOffset(70, 36); b2.BackgroundColor3 = GOLD; b2.BorderSizePixel = 0
		b2.FontFace = FONT; b2.TextSize = 15; b2.TextColor3 = BTN_INK; b2.Text = "Store"
		b2.AutoButtonColor = false; b2.ZIndex = 4; b2.Visible = false; b2.Parent = row
		corner(b2, UDim.new(0, 10)); stroke(b2, RGB(150, 98, 36), 2, 0.2)
		rec.btn2 = b2
		b2.MouseButton1Click:Connect(function() stowIt(item, rec, true) end)
	end
]],'rec.btn2 = b2',true))
table.insert(res,insert(SC,'\tbtn.MouseButton1Click:Connect(function()\n',
'\t\tif HOTBAR[item.id] and (player:GetAttribute("Item_" .. item.id) or 0) > 0 then stowIt(item, rec, false) return end\n',
'then stowIt(item, rec, false) return end',true))
table.insert(res,insert(SC,'\t\t\trec.btn.TextColor3 = affordable and BTN_INK or INK_DIM\n',
[[			if rec.btn2 then
				local stowed = (player:GetAttribute("Item_stow_" .. item.id) or 0) > 0
				if owned then
					local GREEN = RGB(112, 160, 84)
					rec.btn.Size = UDim2.fromOffset(70, 36); rec.btn.Position = UDim2.new(1, -86, 0, 106); rec.btn.TextSize = 15
					rec.btn2.Visible = true
					rec.label = stowed and "Equip" or "Equipped"
					if rec.btn.Text ~= "..." then rec.btn.Text = rec.label end
					rec.btn2.Text = stowed and "Stored" or "Store"
					rec.btn.BackgroundColor3 = stowed and GOLD or GREEN; rec.btn.TextColor3 = stowed and BTN_INK or RGB(255, 255, 255)
					rec.btn2.BackgroundColor3 = stowed and GREEN or GOLD; rec.btn2.TextColor3 = stowed and RGB(255, 255, 255) or BTN_INK
				else
					rec.btn.Size = UDim2.fromOffset(142, 36); rec.btn.Position = UDim2.new(1, -12, 0, 106); rec.btn.TextSize = 18
					rec.btn2.Visible = false
				end
			end
]],'if rec.btn2 then\n\t\t\t\tlocal stowed',true))
table.insert(res,insert(SC,'player:GetAttributeChangedSignal("Item_bagoff"):Connect(refresh)\n',
'for id in pairs(HOTBAR) do player:GetAttributeChangedSignal("Item_stow_" .. id):Connect(refresh) end\n',
'GetAttributeChangedSignal("Item_stow_" .. id)',true))
-- the crab scripts
local srv=workspace.CrabGame:FindFirstChild('CrabServer') if srv then srv.Source=[==[-- CrabServer (workspace.CrabGame): the crab game at Porto Nocciola (Oct 4 2026, Shannon: "buy a crab trap from the acorn
-- store, cast the net into the ocean, wait a short time, pull it in and take it to the fish seller to exchange for acorns").
-- Everything that matters is decided HERE: where the trap lands, when it is ready, what is in it, what Beppe pays.
-- Saved through the same ledger as everything else (AwardItems / AwardAcorns): Item_crabtrap (owned, bought in the Acorn
-- Store), Item_crabs and Item_goldcrabs (the bucket - kept between visits). This script never touches a DataStore.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local G = script.Parent
local kit = RS:WaitForChild("CrabGame")
local ev = kit:WaitForChild("CrabEvent")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local awardItems = RS:WaitForChild("AwardItems")

local function num(name, default) local v = G:GetAttribute(name) return type(v) == "number" and v or default end
-- the Crab Catching Area: the tide-pool shelf and the little sandy cove beside it (ZoneMin/ZoneMax attributes)
local function inZone(pos)
	local a, b = G:GetAttribute("ZoneMin"), G:GetAttribute("ZoneMax")
	if typeof(a) ~= "Vector3" or typeof(b) ~= "Vector3" then return false end
	return pos.X >= a.X and pos.X <= b.X and pos.Y >= a.Y and pos.Y <= b.Y and pos.Z >= a.Z and pos.Z <= b.Z
end
local function bucket(p) return (p:GetAttribute("Item_crabs") or 0) + (p:GetAttribute("Item_goldcrabs") or 0) end

local casts = {}            -- [player] = {trap, buoy, beam, a0, readyAt, target}
local busy = {}

local function hand(char)
	local h = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm") or char:FindFirstChild("HumanoidRootPart")
	local a = h and h:FindFirstChild("CrabLine")
	if h and not a then a = Instance.new("Attachment") a.Name = "CrabLine" a.Position = Vector3.new(0, -0.25, 0) a.Parent = h end
	return a
end

-- THE TRAP IS CARRIED (Oct 4 2026, Shannon: "equip the trap like we are equipping the slingshot and binoculars"): a Tool in
-- the hotbar for whoever owns one and has not put it away from the Acorn Store (Item_stow_crabtrap, StowServer). It must be
-- held to cast; it leaves the hand while it is out on the rope, and the trap you pull in comes back into your hand with the
-- catch in it until you cast again or put it down (the crabs themselves are in the bucket the moment you pull).
local SS = game:GetService("ServerStorage")
local TOOL = "Crab trap"
local pull, clear                                   -- (defined below; the tool's Unequipped needs them)
local function heldTool(char) local t = char and char:FindFirstChild(TOOL) return t and t:IsA("Tool") and t or nil end
local function showHeld(tool, on)
	for _, v in ipairs(tool:GetDescendants()) do
		if v:IsA("BasePart") and v.Name ~= "Handle" and not v:FindFirstAncestor("CatchCrabs") then v.Transparency = on and 0 or 1 end
	end
end
local function clearCatch(tool) local f = tool and tool:FindFirstChild("CatchCrabs") if f then f:Destroy() end end
local function giveTrap(p)
	local own = (p:GetAttribute("Item_crabtrap") or 0) > 0
	local stowed = (p:GetAttribute("Item_stow_crabtrap") or 0) > 0
	local char = p.Character
	local pack = p:FindFirstChildOfClass("Backpack")
	local have = (pack and pack:FindFirstChild(TOOL)) or (char and char:FindFirstChild(TOOL))
	if own and not stowed then
		if have or not char then return end
		local tmpl = SS:FindFirstChild("CrabTrapTool")
		if not tmpl then warn("CrabServer: no ServerStorage.CrabTrapTool") return end
		local t = tmpl:Clone() t.Name = TOOL
		t.Unequipped:Connect(function()
			clearCatch(t)                            -- put down: the crabs are already in the bucket
			local c = casts[p]
			if c and c.tool == t then
				if c.readyAt then task.spawn(pull, p) else clear(p) end
			end
		end)
		t.Parent = pack or p
	elseif have then
		have:Destroy()
	end
end

-- open sea in front of the player: walk out along the way they face, then try a little to either side
local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Exclude
local function findWater(root)
	local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	if look.Magnitude < 0.1 then return nil end
	look = look.Unit
	local ex = {}
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(ex, p.Character) end end
	for _, v in ipairs(G:GetDescendants()) do if v:IsA("BasePart") then table.insert(ex, v) end end
	rp.FilterDescendantsInstances = ex
	local sea = num("SeaY", -52.9)
	for _, turn in ipairs({0, 20, -20, 40, -40, 60, -60}) do
		local dir = CFrame.Angles(0, math.rad(turn), 0):VectorToWorldSpace(look)
		for d = 9, 17, 2 do
			local p = root.Position + dir * d
			local q = workspace:Raycast(Vector3.new(p.X, sea + 12, p.Z), Vector3.new(0, -16, 0), rp)
			if q and q.Instance == workspace.Terrain and q.Material == Enum.Material.Water and math.abs(q.Position.Y - sea) < 0.6 then
				-- and nothing solid just under the surface (the shelf's foot)
				local under = workspace:Raycast(Vector3.new(p.X, sea - 0.2, p.Z), Vector3.new(0, -1.5, 0), rp)
				if not under or under.Material == Enum.Material.Water then
					return Vector3.new(p.X, sea, p.Z), dir
				end
			end
		end
	end
	return nil
end

local function splash(pos)
	local a = Instance.new("Part") a.Name = "Splash" a.Anchored = true a.CanCollide = false a.CanQuery = false a.CanTouch = false
	a.Transparency = 1 a.Size = Vector3.new(0.2, 0.2, 0.2) a.Position = pos a.Parent = G
	local pe = Instance.new("ParticleEmitter") pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(235, 250, 255)) pe.Size = NumberSequence.new(0.35, 0)
	pe.Speed = NumberRange.new(6, 10) pe.SpreadAngle = Vector2.new(35, 35) pe.Lifetime = NumberRange.new(0.4, 0.7)
	pe.Acceleration = Vector3.new(0, -30, 0) pe.EmissionDirection = Enum.NormalId.Top pe.Rate = 0 pe.Parent = a
	pe:Emit(26)
	local s = Instance.new("Sound") s.SoundId = "rbxasset://sounds/impact_water.mp3" s.Volume = 0.8
	s.RollOffMinDistance = 8 s.RollOffMaxDistance = 70 s.Parent = a s:Play()
	Debris:AddItem(a, 3)
end

-- fly a model along an arc (server steps it; everyone sees it)
local function arc(model, from, to, secs, height)
	local rot = model:GetPivot().Rotation
	local n = math.max(8, math.floor(secs * 30))
	for i = 1, n do
		local t = i / n
		local p = from:Lerp(to, t) + Vector3.new(0, math.sin(t * math.pi) * height, 0)
		model:PivotTo(CFrame.new(p) * rot)
		task.wait(secs / n)
		if not model.Parent then return end
	end
end

clear = function(p, keepTrap)
	local c = casts[p]
	casts[p] = nil
	if not c then return end
	if c.beam then c.beam:Destroy() end
	if c.buoy then c.buoy:Destroy() end
	if c.trap and not keepTrap then c.trap:Destroy() end
	if c.tool and c.tool.Parent then showHeld(c.tool, true) end
	p:SetAttribute("CrabCast", nil)
end

local function cast(p)
	if casts[p] or busy[p] then return end
	local char = p.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return end
	if (p:GetAttribute("Item_crabtrap") or 0) < 1 then ev:FireClient(p, "say", "You need a crab trap - they're in the Acorn Store.") return end
	local tool = heldTool(char)
	if not tool then ev:FireClient(p, "say", "Hold your crab trap to cast - it's in your hotbar.") return end
	if not inZone(root.Position) then ev:FireClient(p, "say", "Crabs live by the tide pools - cast from the Crab Catching Area.") return end
	if bucket(p) >= num("Bucket", 6) then ev:FireClient(p, "say", "Your bucket is full! Sell your crabs to Beppe at the fish stall.") return end
	local target, dir = findWater(root)
	if not target then ev:FireClient(p, "say", "Face the open sea to cast your trap.") return end
	busy[p] = true
	local trap = kit.Trap:Clone()
	trap.Name = "Trap_" .. p.UserId
	for _, v in ipairs(trap:GetDescendants()) do if v:IsA("BasePart") then v.Anchored = true v.CanCollide = false v.CanQuery = false v.CanTouch = false end end
	local h0 = hand(char)
	local start = h0 and h0.WorldPosition or (root.Position + dir * 1.5 + Vector3.new(0, 1.2, 0))
	clearCatch(tool) showHeld(tool, false)          -- it leaves your hand
	trap:PivotTo(CFrame.lookAt(start, start + dir))
	trap.Parent = G
	local buoy = kit.Buoy:Clone() buoy.Name = "Buoy_" .. p.UserId
	buoy:PivotTo(CFrame.new(start)) buoy.Parent = G
	local a1 = buoy.PrimaryPart:FindFirstChild("LineEnd")
	local beam = kit.Line:Clone() beam.Attachment0 = hand(char) beam.Attachment1 = a1 beam.Parent = buoy.PrimaryPart
	local wait = math.random() * (num("WaitMax", 15) - num("WaitMin", 10)) + num("WaitMin", 10)
	casts[p] = {trap = trap, buoy = buoy, beam = beam, target = target, tool = tool}
	p:SetAttribute("CrabCast", "flying")
	task.spawn(function() arc(buoy, start, target + Vector3.new(0, 0.15, 0), 0.75, 4) end)
	arc(trap, start, target, 0.75, 4)
	if casts[p] == nil or casts[p].trap ~= trap then busy[p] = nil return end
	splash(target)
	-- the trap sinks out of sight; only the float stays, bobbing
	trap:PivotTo(trap:GetPivot() + Vector3.new(0, -2.4, 0))
	local bob = TweenService:Create(buoy.PrimaryPart, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{CFrame = buoy.PrimaryPart.CFrame + Vector3.new(0, 0.18, 0)})
	bob:Play()
	casts[p].readyAt = workspace:GetServerTimeNow() + wait
	p:SetAttribute("CrabCast", casts[p].readyAt)
	busy[p] = nil
	ev:FireClient(p, "cast", casts[p].readyAt)
end

local function rollCatch()
	local r = math.random()
	local n = r < 0.15 and 0 or r < 0.55 and 1 or r < 0.85 and 2 or 3
	local gold = math.random() < num("GoldChance", 0.05)
	if gold then n = math.max(n, 1) end
	return n, gold and 1 or 0
end

pull = function(p)
	local c = casts[p]
	if not c or busy[p] or not c.readyAt then return end
	busy[p] = true
	local char = p.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local early = workspace:GetServerTimeNow() < c.readyAt
	local n, gold = 0, 0
	if not early then n, gold = rollCatch() end
	-- room in the bucket? the golden one goes in first; whatever doesn't fit is let go
	local room = math.max(0, num("Bucket", 6) - bucket(p))
	local g = math.min(gold, room) room -= g
	local plain = math.min(n - gold, room)
	local let = (gold - g) + (n - gold - plain)
	gold = g
	-- crabs ride up inside the trap
	local trap = c.trap
	trap:PivotTo(CFrame.new(c.target) * trap:GetPivot().Rotation)
	local shown = {}
	for i = 1, plain + gold do
		local crab = kit.Crab:Clone()
		for _, v in ipairs(crab:GetDescendants()) do if v:IsA("BasePart") then v.Anchored = true v.CanCollide = false v.CanQuery = false v.CanTouch = false end end
		if i <= gold then
			for _, v in ipairs(crab:GetDescendants()) do if v:IsA("MeshPart") then v.TextureID = "" v.Color = Color3.fromRGB(255, 196, 46) v.Material = Enum.Material.Foil end end
		end
		crab.Parent = trap
		table.insert(shown, {crab, Vector3.new((i - (plain + gold + 1) / 2) * 0.45, -0.5, (i % 2) * 0.25 - 0.1)})
	end
	local function place()
		for _, s in ipairs(shown) do s[1]:PivotTo(trap:GetPivot() * CFrame.new(s[2])) end
	end
	place()
	splash(c.target)
	if c.beam then c.beam:Destroy() c.beam = nil end
	if c.buoy then c.buoy:Destroy() c.buoy = nil end
	local h1 = char and hand(char)
	local to = (h1 and h1.WorldPosition) or (root and (root.Position + root.CFrame.LookVector * 1.6 + Vector3.new(0, 0.6, 0))) or c.target + Vector3.new(0, 3, 0)
	local n2 = 20
	local from = c.target
	for i = 1, n2 do
		local t = i / n2
		trap:PivotTo(CFrame.new(from:Lerp(to, t) + Vector3.new(0, math.sin(t * math.pi) * 3, 0)) * trap:GetPivot().Rotation)
		place()
		task.wait(0.6 / n2)
	end
	if plain > 0 then awardItems:Fire(p, "crabs", plain) end
	if gold > 0 then awardItems:Fire(p, "goldcrabs", gold) end
	ev:FireClient(p, "caught", plain, gold, let, early)
	-- back in your hand: the flying trap goes and the one you hold comes back, with the catch welded inside it
	local tool = c.tool
	local frame = tool and tool:FindFirstChild("TrapFrame")
	if tool and frame and char and tool.Parent == char then
		local f = Instance.new("Folder") f.Name = "CatchCrabs" f.Parent = tool
		for _, sh in ipairs(shown) do
			local crab = sh[1]
			crab:PivotTo(frame.CFrame * CFrame.new(sh[2]))
			for _, v in ipairs(crab:GetDescendants()) do
				if v:IsA("BasePart") then
					v.Anchored = false v.Massless = true
					local w = Instance.new("WeldConstraint") w.Part0 = frame w.Part1 = v w.Parent = v
				end
			end
			crab.Parent = f
		end
		clear(p, true)
		trap:Destroy()
	else
		clear(p, true)
		Debris:AddItem(trap, 1.6)
	end
	busy[p] = nil
end

ev.OnServerEvent:Connect(function(p, what)
	if what == "cast" then cast(p)
	elseif what == "pull" then pull(p) end
end)

-- leaving the area (or the game) brings the trap home empty
task.spawn(function()
	while true do
		task.wait(0.5)
		for p, c in pairs(casts) do
			local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if not p.Parent or not root or (not busy[p] and not inZone(root.Position)) then
				clear(p) if p.Parent then ev:FireClient(p, "lost") end
			end
		end
	end
end)
Players.PlayerRemoving:Connect(function(p) clear(p) busy[p] = nil end)
local function watchTrap(p)
	p.CharacterAdded:Connect(function() task.wait(0.6) giveTrap(p) end)
	p:GetAttributeChangedSignal("Item_crabtrap"):Connect(function() giveTrap(p) end)
	p:GetAttributeChangedSignal("Item_stow_crabtrap"):Connect(function() giveTrap(p) end)
	if p.Character then task.defer(giveTrap, p) end
end
Players.PlayerAdded:Connect(watchTrap)
for _, pl in ipairs(Players:GetPlayers()) do watchTrap(pl) end

-- BEPPE BUYS THE CATCH: a prompt at his crate (each client shows it only while it has crabs)
local sellPrompt = G:FindFirstChild("SellPrompt", true)
if sellPrompt then
	sellPrompt.Triggered:Connect(function(p)
		if busy[p] then return end
		local plain, gold = p:GetAttribute("Item_crabs") or 0, p:GetAttribute("Item_goldcrabs") or 0
		if plain + gold <= 0 then ev:FireClient(p, "sold", 0, 0, 0) return end
		busy[p] = true
		local pay = plain * num("CrabPay", 3) + gold * num("GoldPay", 100)
		if plain > 0 then awardItems:Fire(p, "crabs", -plain) end
		if gold > 0 then awardItems:Fire(p, "goldcrabs", -gold) end
		awardAcorns:Fire(p, pay)                                   -- same ledger the shop spends from
		p:SetAttribute("Acorns", (p:GetAttribute("Acorns") or 0) + pay)
		busy[p] = nil
		ev:FireClient(p, "sold", plain, gold, pay)
	end)
else
	warn("CrabServer: no SellPrompt - Beppe cannot buy crabs")
end
print("CrabServer: ready")
]==] end
local cli=game.StarterPlayer.StarterPlayerScripts:FindFirstChild('CrabClient') if cli then cli.Source=[==[-- CrabClient (StarterPlayerScripts): the crab game's button and bucket (Oct 4 2026). The server (workspace.CrabGame.CrabServer)
-- decides everything; this only shows it. In the Crab Catching Area with a trap: one round button - Cast, then a filling
-- ring while the crabs find the trap, then Pull in! The bucket count rides on the button; away from the area with crabs
-- in the bucket it shrinks to a little "sell to Beppe" pill. Beppe and Enzo talk through the SquirrelBubble like every squirrel.
-- PHONES: nothing may overlap anything - the panel tries a list of corners and takes the first one clear of every other
-- visible thing on screen (measured with the gui inset, the way phone_overlap_probe does).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local CAS = game:GetService("ContextActionService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local G = workspace:WaitForChild("CrabGame")
local kit = RS:WaitForChild("CrabGame")
local ev = kit:WaitForChild("CrabEvent")
local okBubble, Bubble = pcall(function() return require(RS:WaitForChild("SquirrelBubble", 10)) end)
local okArt, Art = pcall(function() return require(RS:WaitForChild("SquirrelIllustrations", 10)) end)

local RGB = Color3.fromRGB
local FACE, RIM, INK, GOLD = RGB(250, 241, 219), RGB(118, 80, 46), RGB(64, 42, 22), RGB(255, 202, 62)
local FONT = Font.new("rbxasset://fonts/families/FredokaOne.json")

local function inZone(pos)
	local a, b = G:GetAttribute("ZoneMin"), G:GetAttribute("ZoneMax")
	if typeof(a) ~= "Vector3" or typeof(b) ~= "Vector3" then return false end
	return pos.X >= a.X and pos.X <= b.X and pos.Y >= a.Y and pos.Y <= b.Y and pos.Z >= a.Z and pos.Z <= b.Z
end
local function counts() return player:GetAttribute("Item_crabs") or 0, player:GetAttribute("Item_goldcrabs") or 0 end
local function bucketMax() return G:GetAttribute("Bucket") or 6 end

-- ---------------------------------------------------------------- the panel
local gui = Instance.new("ScreenGui")
gui.Name = "CrabGui" gui.ResetOnSpawn = false gui.IgnoreGuiInset = true gui.DisplayOrder = 6 gui.Enabled = false gui.Parent = pg
local root = Instance.new("Frame") root.Name = "Root" root.BackgroundTransparency = 1 root.Size = UDim2.fromOffset(300, 128)
root.AnchorPoint = Vector2.new(1, 1) root.Parent = gui

local btn = Instance.new("TextButton") btn.Name = "CastButton" btn.Text = "" btn.AutoButtonColor = false
btn.Size = UDim2.fromOffset(92, 92) btn.Position = UDim2.new(1, -96, 0, 0) btn.BackgroundColor3 = FACE btn.Parent = root
Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
local rim = Instance.new("UIStroke") rim.Color = RIM rim.Thickness = 4 rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border rim.Parent = btn
local icon = okArt and Art.draw(btn, "crabtrap", 58) or Instance.new("Frame")
icon.Position = UDim2.fromOffset(17, 8) icon.Size = UDim2.fromOffset(58, 58) icon.BackgroundTransparency = 1
local word = Instance.new("TextLabel") word.BackgroundTransparency = 1 word.Size = UDim2.new(1, 0, 0, 22) word.Position = UDim2.fromOffset(0, 62)
word.FontFace = FONT word.TextSize = 17 word.TextColor3 = INK word.Text = "Cast" word.ZIndex = 5 word.Parent = btn
-- the waiting ring: a gold fill rising behind the icon
local fill = Instance.new("Frame") fill.Name = "Fill" fill.BackgroundColor3 = RGB(255, 226, 140) fill.BorderSizePixel = 0
fill.AnchorPoint = Vector2.new(0, 1) fill.Position = UDim2.fromScale(0, 1) fill.Size = UDim2.fromScale(1, 0) fill.ZIndex = 1 fill.Parent = btn
Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
btn.ClipsDescendants = true

local pill = Instance.new("Frame") pill.Name = "Bucket" pill.Size = UDim2.fromOffset(118, 24) pill.Position = UDim2.new(1, -109, 0, 102)
pill.BackgroundColor3 = FACE pill.Parent = root
Instance.new("UICorner", pill).CornerRadius = UDim.new(0, 12)
local ps = Instance.new("UIStroke") ps.Color = RIM ps.Thickness = 2 ps.Parent = pill
local pillText = Instance.new("TextLabel") pillText.BackgroundTransparency = 1 pillText.Size = UDim2.fromScale(1, 1)
pillText.FontFace = FONT pillText.TextSize = 14 pillText.TextColor3 = INK pillText.Parent = pill

local note = Instance.new("TextLabel") note.Name = "Note" note.BackgroundTransparency = 1 note.Size = UDim2.fromOffset(196, 56)
note.Position = UDim2.fromOffset(0, 18) note.TextXAlignment = Enum.TextXAlignment.Right note.FontFace = FONT note.TextSize = 14 note.TextColor3 = RGB(255, 255, 255)
note.TextStrokeTransparency = 0.35 note.TextWrapped = true note.TextYAlignment = Enum.TextYAlignment.Center note.Text = "" note.Parent = root

local noteUntil = 0
local function say(text, secs)
	noteUntil = os.clock() + (secs or 3) + 0.4
	note.Text = text note.TextTransparency = 0 note.TextStrokeTransparency = 0.35
	local myText = text
	task.delay(secs or 3, function()
		if note.Text == myText then
			TweenService:Create(note, TweenInfo.new(0.4), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
		end
	end)
end

-- ---------------------------------------------------------------- state
local state = "idle"        -- idle | flying | waiting | ready
local readyAt, castAt = 0, 0
local pulse
local function setWord(t, col) word.Text = t word.TextColor3 = col or INK end
local function stopPulse() if pulse then pulse:Cancel() pulse = nil end rim.Color = RIM rim.Thickness = 4 end
local function toIdle() state = "idle" stopPulse() fill.Size = UDim2.fromScale(1, 0) setWord("Cast") end

local function press()
	if state == "idle" then
		state = "flying" setWord("...") ev:FireServer("cast")
		task.delay(3, function() if state == "flying" then toIdle() end end)     -- the server said no (it also says why)
	elseif state == "waiting" or state == "ready" then
		ev:FireServer("pull") setWord("...")
	end
end
btn.Activated:Connect(press)

ev.OnClientEvent:Connect(function(what, a, b, c, d)
	if what == "say" then say(a, 3.5) if state == "flying" then toIdle() end
	elseif what == "cast" then
		state = "waiting" readyAt = a castAt = workspace:GetServerTimeNow() setWord("Wait...")
	elseif what == "caught" then
		local plain, gold, let, early = a, b, c, d
		toIdle()
		if early then say("Too soon - the crabs weren't in yet!", 3)
		elseif gold > 0 then say("A GOLDEN CRAB!" .. (plain > 0 and ("  +" .. plain .. " more") or ""), 4)
		elseif plain == 0 then say("Empty this time. Try again!", 3)
		else say(plain == 1 and "You caught a crab!" or ("You caught " .. plain .. " crabs!"), 3) end
		if let > 0 then task.delay(2.2, function() say("Bucket full - you let " .. let .. " go.", 3) end) end
	elseif what == "lost" then toIdle() say("You left the crab area - trap reeled in.", 3)
	elseif what == "sold" then
		local plain, gold, pay = a, b, c
		local beppe = workspace:FindFirstChild("fishmonger_squirrel_color")
		local line
		if pay == 0 then line = "No crabs? Come back when your bucket's full!"
		elseif gold > 0 then line = "A GOLDEN crab?! Mamma mia! " .. pay .. " acorns for you!"
		else line = ({"Grazie! Fresh from the rocks - " .. pay .. " acorns.", "Bellissimi! " .. pay .. " acorns for these.", "Ah, lovely crabs! Here's " .. pay .. " acorns."})[math.random(1, 3)] end
		if okBubble and beppe then pcall(Bubble.say, beppe, line, {secs = 3.5}) else say(line, 3.5) end
	end
end)

-- ---------------------------------------------------------------- placement clear of everything else
local function rectOf(o)
	local inset = GuiService:GetGuiInset()
	local p, s = o.AbsolutePosition + inset, o.AbsoluteSize
	return p.X, p.Y, p.X + s.X, p.Y + s.Y
end
local function visible(o)
	local x = o
	while x and x ~= pg do
		if x:IsA("GuiObject") and not x.Visible then return false end
		if x:IsA("ScreenGui") and not x.Enabled then return false end
		x = x.Parent
	end
	return true
end
local function drawn(o)
	if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then return o.BackgroundTransparency < 1 or (o.Text ~= "" and o.TextTransparency < 1) end
	if o:IsA("ImageLabel") or o:IsA("ImageButton") then return o.BackgroundTransparency < 1 or (o.Image ~= "" and o.ImageTransparency < 1) end
	return o.BackgroundTransparency < 1
end
local StarterGui = game:GetService("StarterGui")
local function others()
	local list = {}
	local vp = workspace.CurrentCamera.ViewportSize
	for _, sg in ipairs(pg:GetChildren()) do
		if sg:IsA("ScreenGui") and sg ~= gui and sg.Enabled and sg.Name ~= "SquirrelBubbleGui" and sg.Name ~= "DailyGui" then   -- (Shannon: the daily card only shows at spawn and is closed right away - it may overlap)
			for _, o in ipairs(sg:GetDescendants()) do
				if o:IsA("GuiObject") and o.AbsoluteSize.X > 2 and o.AbsoluteSize.Y > 2 and visible(o) and drawn(o) then
					local s = o.AbsoluteSize
					if not (s.X >= vp.X * 0.9 and s.Y >= vp.Y * 0.9) then table.insert(list, {rectOf(o)}) end
				end
			end
		end
	end
	-- Roblox's own hotbar (CoreGui, invisible to this list): keep the bottom middle free while it is on
	local okBP, bp = pcall(function() return StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack) end)
	if not okBP or bp then
		-- (this panel ignores the inset, so its spots are in whole-screen pixels, the same space as rectOf and the viewport)
		local half = math.min(vp.X * 0.5, 340)
		table.insert(list, {vp.X / 2 - half / 2, vp.Y - 96, vp.X / 2 + half / 2, vp.Y})
	end
	return list
end
local function clearAt(x0, y0, x1, y1, list)
	for _, r in ipairs(list) do
		if x0 < r[3] + 4 and x1 > r[1] - 4 and y0 < r[4] + 4 and y1 > r[2] - 4 then return false end
	end
	return true
end
local function place()
	local vp = workspace.CurrentCamera.ViewportSize
	local w, h = root.AbsoluteSize.X, root.AbsoluteSize.Y
	local list = others()
	-- bottom-right corner first (above a phone's jump button), then up the right side, then the bottom middle and left
	local tries = {}
	for _, fy in ipairs({0.62, 0.5, 0.75, 0.38, 0.85, 0.28}) do table.insert(tries, Vector2.new(vp.X - 16, vp.Y * fy + h / 2)) end
	for _, fy in ipairs({0.62, 0.5, 0.38}) do table.insert(tries, Vector2.new(vp.X - 120, vp.Y * fy + h / 2)) end
	for _, fx in ipairs({0.5, 0.65, 0.35}) do table.insert(tries, Vector2.new(vp.X * fx + w / 2, vp.Y - 16)) end
	for _, fy in ipairs({0.5, 0.38, 0.28}) do table.insert(tries, Vector2.new(16 + w, vp.Y * fy + h / 2)) end
	table.insert(tries, Vector2.new(vp.X * 0.3 + w / 2, vp.Y * 0.5 + h / 2))
	for _, t in ipairs(tries) do
		local x1, y1 = t.X, t.Y
		if clearAt(x1 - w, y1 - h, x1, y1, list) then
			root.Position = UDim2.fromOffset(x1, y1) root.Visible = true return true
		end
	end
	root.Position = UDim2.fromOffset(tries[1].X, tries[1].Y)
	if not btn.Visible then root.Visible = false end         -- just the bucket pill: wait for room rather than overlap
	return false
end

-- ---------------------------------------------------------------- every frame: show/hide, ring, prompt
local sellPrompt = nil                 -- looked up again while missing: with streaming the sell spot arrives only near Beppe
local lastLook = 0
local lastPlace, wasShown, compact, lastW = 0, false, nil, 0
local enzoSaid = 0
local wasZone, toldHold = false, false
local hookedTool = nil
-- PC: clicking with the trap in your hand casts / pulls, like the slingshot's click
local function hookTool(tool)
	if hookedTool == tool then return end
	hookedTool = tool
	tool.Activated:Connect(function() if gui.Enabled and btn.Visible then press() end end)
end
RunService.RenderStepped:Connect(function()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local plain, gold = counts()
	local have = (player:GetAttribute("Item_crabtrap") or 0) > 0
	local zone = hrp and inZone(hrp.Position)
	local tool = char and char:FindFirstChild("Crab trap")
	local holding = tool ~= nil and tool:IsA("Tool")
	if holding then hookTool(tool) end
	-- the button belongs to the trap in your hand (Shannon: equip it like the slingshot and binoculars)
	local castOn = have and zone and holding or state ~= "idle"
	if zone and not wasZone then toldHold = false end
	wasZone = zone
	if zone and have and not holding and not toldHold and state == "idle" then
		toldHold = true
		say("Hold your crab trap to cast - it's in your hotbar.", 4)
	end
	local noteOn = os.clock() < noteUntil
	local show = castOn or (plain + gold > 0) or noteOn
	gui.Enabled = show
	btn.Visible = castOn
	pill.Visible = plain + gold > 0 or castOn
	local compactNow = (not castOn) and plain + gold > 0 and not noteOn
	pillText.Text = (gold > 0 and ("Crabs " .. (plain + gold) .. "/" .. bucketMax() .. "  (" .. gold .. " gold)") or ("Crabs " .. plain .. "/" .. bucketMax()))
		.. (compactNow and "\nsell to Beppe" or "")
	-- the pill fits its words; away from the area it is the whole panel (so it can tuck into any free spot)
	local pw = math.max(118, math.ceil(pillText.TextBounds.X) + 26)
	pill.Size = UDim2.fromOffset(pw, compactNow and 40 or 24)
	if compactNow then
		root.Size = UDim2.fromOffset(pw, 42) pill.Position = UDim2.fromOffset(0, 1) note.Visible = false
	else
		root.Size = UDim2.fromOffset(300, 128) pill.Position = UDim2.fromOffset(math.min(250 - math.ceil(pw / 2), 300 - pw), 102) note.Visible = true   -- under the button, never past the panel edge
	end
	if (not sellPrompt or not sellPrompt.Parent) and os.clock() - lastLook > 1 then lastLook = os.clock() sellPrompt = G:FindFirstChild("SellPrompt", true) end
	if sellPrompt then sellPrompt.Enabled = plain + gold > 0 end
	if state == "waiting" or state == "ready" then
		local now = workspace:GetServerTimeNow()
		local t = math.clamp((now - castAt) / math.max(0.1, readyAt - castAt), 0, 1)
		fill.Size = UDim2.fromScale(1, t)
		if t >= 1 and state == "waiting" then
			state = "ready" setWord("Pull in!", RGB(150, 52, 30))
			rim.Color = GOLD
			pulse = TweenService:Create(rim, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Thickness = 7})
			pulse:Play()
		end
	end
	if show and (not wasShown or compact ~= castOn or lastW ~= root.Size.X.Offset or os.clock() - lastPlace > 2) then
		lastPlace = os.clock() compact = castOn lastW = root.Size.X.Offset
		task.defer(place)
	end
	wasShown = show
	-- Enzo's tip for anybody at the pools without a trap
	if hrp and not have and os.clock() - enzoSaid > 60 then
		local enzo = workspace:FindFirstChild("crabcatcher_squirrel_color")
		local cm = enzo and enzo:FindFirstChild("Squirrel")
		if cm and (cm.Position - hrp.Position).Magnitude < 12 then
			enzoSaid = os.clock()
			if okBubble then pcall(Bubble.say, enzo, "Want to catch crabs? Get a crab trap in the Acorn Store!", {secs = 4}) end
		end
	end
end)

-- PC: F casts and pulls while the button is up
CAS:BindAction("CrabCast", function(_, st)
	if st == Enum.UserInputState.Begin and gui.Enabled and btn.Visible then press() return Enum.ContextActionResult.Sink end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.F)
]==] end
game:GetService('ChangeHistoryService'):SetWaypoint('Crab trap tool + Equip/Store')
local ok=0 for _,v in ipairs(res) do if v then ok+=1 end end
warn('QH@OK edits',ok,'of',#res,'icon',ICON,'trap size',fr.Size,'axis',axis,'tool parts',#tool:GetChildren(),'server',srv and #srv.Source,'client',cli and #cli.Source)
