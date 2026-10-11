-- install_boatinvite1.lua (Studio EDIT mode; re-runnable). Job 89. The one-click trip to the boat after the last French
-- squirrel: workspace.BoatInvite (server 4533, client 5901 chars) + RS.BoatTake, and three exact-string
-- patches to workspace.Boat.BoatServer (backup HudBackup.BoatServer_pre_invite1). Undo: delete workspace.BoatInvite and
-- RS.BoatTake, put the backup's Source back, and the jetty sign's old text (printed below). No publish.
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local SERVER = [===[
-- BoatInviteServer (workspace.BoatInvite): the one-click trip to the boat (Shannon, Oct 11 2026: "when the player finds the
-- last squirrel on the France map, we need a way to get their character to the dock where the boat is in a non awkward way";
-- "they should be able to take the boat with one click"). The card (BoatInviteClient) sends "go"; this checks the player has
-- found all 44 French squirrels, fades their screen with the luggage cart's fade (workspace.Travel.TravelEvent), puts them on
-- the jetty facing the moored boat, and fires ReplicatedStorage.BoatTake, which BoatServer answers by boarding them exactly
-- as its own jetty prompt does (the parachute is packed for everyone who has found all 44).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local F = script.Parent
local ev = F:WaitForChild("BoatInviteEvent")
local MAPS = {"forest", "village", "domaine"}
local function need() local v = F:GetAttribute("Need"); return type(v) == "number" and v or 44 end
local function found(p) local n = 0; for _, m in ipairs(MAPS) do n += tonumber(p:GetAttribute("Found_" .. m)) or 0 end; return n end
local busy, last = {}, {}

local function travelEvent() local t = workspace:FindFirstChild("Travel"); return t and t:FindFirstChild("TravelEvent") end
local function note(p, text) local tev = travelEvent(); if tev then tev:FireClient(p, "note", text) end end

-- the jetty deck (x 160.4..163.9) beside the moored boat, found by a ray down; facing the boat
local function jettySpot()
	local River = workspace:FindFirstChild("River")
	local preview = River and River:FindFirstChild("BoatPreview")
	local visual = preview and preview:FindFirstChildWhichIsA("MeshPart", true)
	if not visual then return nil end
	local x, z = 162.2, math.clamp(visual.Position.Z + 3, -164, -148)   -- (a little up the deck from the boat: clear of the BATEAUX sign at -166..-168.5)
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.RespectCanCollide = true
	local skip = {preview}
	for _, pl in ipairs(Players:GetPlayers()) do if pl.Character then table.insert(skip, pl.Character) end end
	local boat = workspace:FindFirstChild("Boat"); if boat then table.insert(skip, boat) end
	rp.FilterDescendantsInstances = skip
	local top                                                    -- the highest of three rays (one may fall between two planks onto a stringer)
	for _, dz in ipairs({0, 0.45, -0.45}) do
		local hit = workspace:Raycast(Vector3.new(x, visual.Position.Y + 10, z + dz), Vector3.new(0, -25, 0), rp)   -- (from low: no tree or bridge above counts)
		if hit and (not top or hit.Position.Y > top) then top = hit.Position.Y end
	end
	top = top or visual.Position.Y + 2
	if top > visual.Position.Y + 8 or top < visual.Position.Y - 4 then top = visual.Position.Y + 2 end
	local pos = Vector3.new(x, top + 3.2, z)
	return CFrame.lookAt(pos, Vector3.new(visual.Position.X, pos.Y, visual.Position.Z))
end

ev.OnServerEvent:Connect(function(p, what)
	if what ~= "go" or busy[p] or os.clock() - (last[p] or 0) < 8 then return end
	if found(p) < need() and p.UserId ~= game.CreatorId then return end
	local char = p.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and root) or hum.Health <= 0 then return end
	if hum.SeatPart then note(p, "Hop off first, then the boat is yours.") return end
	local take = RS:FindFirstChild("BoatTake")
	local cf = jettySpot()
	if not (take and take:IsA("BindableEvent") and cf) then note(p, "The boat is at the river dock, by the bridge.") return end
	busy[p] = true; last[p] = os.clock()
	local tev = travelEvent()
	if tev then tev:FireClient(p, "fade", F:GetAttribute("Place") or "The River Dock") end
	task.wait(0.45)                                              -- the screen is dark before anything moves (as the luggage cart)
	if char.Parent and root.Parent and hum.Health > 0 then
		pcall(function() p:RequestStreamAroundAsync(cf.Position, 3) end)
		root.AssemblyLinearVelocity = Vector3.zero
		char:PivotTo(cf)
		task.wait(0.25)
		take:Fire(p)                                             -- BoatServer boards them (its own checks: all 44, a free slot)
		print(string.format("BoatInvite: %s -> the boat", p.Name))
	end
	if tev then tev:FireClient(p, "arrived") end
	task.delay(2, function() busy[p] = nil end)
end)
Players.PlayerRemoving:Connect(function(p) busy[p] = nil; last[p] = nil end)
print("BoatInviteServer: ready")
]===]
local CLIENT = [===[
-- BoatInviteClient (workspace.BoatInvite, RunContext Client): the "to the boat" card (Shannon, Oct 11 2026). When the player
-- finds the last of the 44 French squirrels, a few seconds after the reveal: "All 44 found! The boat to Italy is waiting at
-- the river dock" with "Take the boat" (one click: the fade, the jetty, aboard, off down the river) and "Later". It shows again
-- once per visit, a little after joining, until the player has reached Italy (Item_porto). Same look as the daily card.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local F = script.Parent
local ev = F:WaitForChild("BoatInviteEvent")
local MAPS = {"forest", "village", "domaine"}
local function num(name, d) local v = F:GetAttribute(name) return type(v) == "number" and v or d end
local function found() local n = 0; for _, m in ipairs(MAPS) do n += tonumber(player:GetAttribute("Found_" .. m)) or 0 end; return n end
local function reachedItaly() return (tonumber(player:GetAttribute("Item_porto")) or 0) >= 1 end
local C = Color3.fromRGB
local NAVY, GOLD, CREAM, DEEP, DIM = C(38, 30, 52), C(240, 200, 90), C(255, 246, 220), C(84, 48, 18), C(200, 190, 210)
local FONT = Enum.Font.FredokaOne
local phone = (function() local ok, pi = pcall(function() return UIS.PreferredInput end); if ok and pi ~= nil then return pi == Enum.PreferredInput.Touch end; return UIS.TouchEnabled and not UIS.MouseEnabled end)()
local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = o end

local gui = Instance.new("ScreenGui"); gui.Name = "BoatInviteGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 100; gui.Enabled = false; gui.Parent = pg   -- (100: on top of everything until it is closed, the interact pills at 30 included - Shannon's rule for the gifts card)
local W, H = 320, 168
local card = Instance.new("Frame"); card.AnchorPoint = Vector2.new(0.5, 0); card.Position = UDim2.new(0.5, 0, 0, phone and 78 or 110)   -- (phone: under the HUD row, ending at 246, above the tool hotbar)
card.Size = UDim2.fromOffset(W, H); card.BackgroundColor3 = NAVY; card.BorderSizePixel = 0; card.Parent = gui; corner(card, 16)
local cs = Instance.new("UIStroke"); cs.Color = GOLD; cs.Thickness = 2; cs.Parent = card
local function text(t, size, colour, y, h)
	local l = Instance.new("TextLabel"); l.Position = UDim2.fromOffset(16, y); l.Size = UDim2.fromOffset(W - 32, h); l.BackgroundTransparency = 1
	l.Font = FONT; l.TextSize = size; l.TextColor3 = colour; l.Text = t; l.TextWrapped = true; l.Parent = card
	return l
end
text("All 44 found!", 22, CREAM, 10, 28)
text("The boat to Italy is waiting at the river dock.", 15, GOLD, 44, 44)
local go = Instance.new("TextButton"); go.AnchorPoint = Vector2.new(0.5, 0); go.Position = UDim2.new(0.5, 0, 0, 98); go.Size = UDim2.fromOffset(170, 38)
go.BackgroundColor3 = GOLD; go.BorderSizePixel = 0; go.Font = FONT; go.TextSize = 18; go.TextColor3 = DEEP; go.Text = "Take the boat"; go.AutoButtonColor = true; go.Parent = card; corner(go, 12)
local later = Instance.new("TextButton"); later.AnchorPoint = Vector2.new(0.5, 1); later.Position = UDim2.new(0.5, 0, 1, -4); later.Size = UDim2.fromOffset(120, 24)
later.BackgroundTransparency = 1; later.Font = FONT; later.TextSize = 15; later.TextColor3 = DIM; later.Text = "Later"; later.Parent = card

local shown = false
local function setOpen(on)
	gui.Enabled = on
	if on then pg:SetAttribute("OpenPanel", "boat")
	elseif pg:GetAttribute("OpenPanel") == "boat" then pg:SetAttribute("OpenPanel", nil) end
end
pg:GetAttributeChangedSignal("OpenPanel"):Connect(function() if gui.Enabled and pg:GetAttribute("OpenPanel") ~= "boat" then gui.Enabled = false end end)
later.Activated:Connect(function() setOpen(false) end)
go.Activated:Connect(function() setOpen(false); ev:FireServer("go") end)

-- a clear moment: nothing else open, the squirrel's reveal card closed, not riding anything, still in France
local function clear()
	if pg:GetAttribute("OpenPanel") ~= nil then return false end
	local sh = pg:FindFirstChild("SquirrelHUD"); local cardUp = sh and sh:FindFirstChild("Card")
	if cardUp and cardUp:IsA("GuiObject") and cardUp.Visible then return false end
	local daily = pg:FindFirstChild("DailyGui"); local dcard = daily and daily:FindFirstChild("DailyCard")
	if daily and daily.Enabled and dcard and dcard.Visible then return false end
	local char = player.Character; local hum = char and char:FindFirstChildOfClass("Humanoid"); local root = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and root) or hum.Health <= 0 or hum.SeatPart then return false end
	return root.Position.Z > -300                                -- (south of z -300 is Porto Nocciola)
end
local function offer(waitFor, within)
	if shown or F:GetAttribute("Enabled") == false then return end
	task.wait(waitFor)
	local t0 = os.clock()
	while os.clock() - t0 < within do
		if shown or reachedItaly() or found() < num("Need", 44) then return end
		if clear() then shown = true; setOpen(true); return end
		task.wait(1)
	end
end

-- the moment the last French squirrel is found this visit
local before = found()
for _, m in ipairs(MAPS) do
	player:GetAttributeChangedSignal("Found_" .. m):Connect(function()
		local now = found()
		if before < num("Need", 44) and now >= num("Need", 44) and player:GetAttribute("SaveLoaded") then task.spawn(offer, num("RevealDelay", 6), 120) end
		before = now
	end)
end
-- a visit that starts with all 44 found and Italy not reached yet
task.spawn(function()
	local t0 = os.clock()
	while not player:GetAttribute("SaveLoaded") and os.clock() - t0 < 60 do task.wait(0.5) end
	before = found()
	if before >= num("Need", 44) and not reachedItaly() then offer(num("JoinDelay", 25), 180) end
end)
print("BoatInviteClient: ready")
]===]
for _, pair in ipairs({{"server", SERVER}, {"client", CLIENT}}) do
	local f, err = loadstring(pair[2]); if not f then print("QQ BOATINV ABORT: the " .. pair[1] .. " does not compile: " .. tostring(err)) return end
end
local boatF = workspace:FindFirstChild("Boat"); local bs = boatF and boatF:FindFirstChild("BoatServer")
if not (bs and bs:IsA("Script")) then print("QQ BOATINV ABORT: workspace.Boat.BoatServer not found; nothing changed") return end
if not workspace:FindFirstChild("Travel") then print("QQ BOATINV ABORT: workspace.Travel (the luggage cart fade) not found; nothing changed") return end
-- BoatClient's jetty prompt (no "no parachute!" / "see the Sky Diving Squirrel first": the waterfall stays a surprise), checked first
local bc = boatF:FindFirstChild("BoatClient")
if not (bc and bc:IsA("BaseScript")) then print("QQ BOATINV ABORT: workspace.Boat.BoatClient not found; nothing changed") return end
local C1, D1 = [==[(may and not player:GetAttribute("HasChute")) and "Take the boat (no parachute!)" or "Take the boat"]==], [==["Take the boat"]==]
local C2, D2 = [==[(player:GetAttribute("HasChute") and "Bateau" or "Bateau - see the Sky Diving Squirrel first")]==], [==["Bateau"]==]
local function count0(s, sub) if sub == "" then return 0 end; local n, i = 0, 1; while true do local a, b = s:find(sub, i, true); if not a then return n end; n += 1; i = b + 1 end end
local bcSrc, bcOut, bcNote = bc.Source, nil, nil
if count0(bcSrc, C1) == 0 and count0(bcSrc, C2) == 0 and bcSrc:find("Bateau - see the Sky Diving", 1, true) == nil and bcSrc:find("(no parachute!)", 1, true) == nil then
	bcNote = "BoatClient already plain (" .. #bcSrc .. ")"
elseif count0(bcSrc, C1) ~= 1 or count0(bcSrc, C2) ~= 1 then
	print(string.format("QQ BOATINV ABORT: BoatClient (%d chars) prompt-text anchors found %d and %d (need 1 and 1); nothing changed", #bcSrc, count0(bcSrc, C1), count0(bcSrc, C2))) return
else
	local a, b = bcSrc:find(C1, 1, true); bcOut = bcSrc:sub(1, a - 1) .. D1 .. bcSrc:sub(b + 1)
	a, b = bcOut:find(C2, 1, true); bcOut = bcOut:sub(1, a - 1) .. D2 .. bcOut:sub(b + 1)
	local f, err = loadstring(bcOut); if not f then print("QQ BOATINV ABORT: the patched BoatClient does not compile: " .. tostring(err) .. "; nothing changed") return end
end
-- the Passport's boat outings, checked before anything changes
local pf = workspace:FindFirstChild("Passport"); local cat = pf and pf:FindFirstChild("Catalogue")
if not (cat and cat:IsA("ModuleScript")) then print("QQ BOATINV ABORT: workspace.Passport.Catalogue not found; nothing changed") return end
local CAT = {{[==[ Steer down the river and see where it goes. The Sky Diving Squirrel in the forest has something you will want before you leave.]==], [==[ Steer down the river and see where it goes. Hold on to your hat!]==]}, {[==[hint="Ride the river all the way to the waterfall."]==], [==[hint="Ride the river all the way to the end."]==]}, {[==[detail="The river leaves French Squirrel Country through a gorge and ends in a great waterfall. Keep going past the brink and over you go, boat and all. Wet or dry, you arrive at Porto Nocciola."]==], [==[detail="The river leaves French Squirrel Country through a gorge. Keep going all the way to the very end, boat and all, and see where it takes you."]==]}, {[==[hint="Float down to Porto Nocciola under the Sky Diving Squirrel's parachute."]==], [==[hint="Arrive at Porto Nocciola with dry feet."]==]}, {[==[detail="After you have found all 44 squirrels, talk to the Sky Diving Squirrel in the forest and he lends you his spare parachute. Wear it over the falls and steer your way down to the shore."]==], [==[detail="Once you have found all 44 squirrels, take the boat all the way down the river. How you reach the shore is a surprise!"]==]}, {[==[Porto Nocciola lies at the foot of the falls.]==], [==[Porto Nocciola lies where the river ends.]==]}}
local catOut, catNote = cat.Source, nil
if catOut:find(CAT[2][2], 1, true) and not catOut:find(CAT[2][1], 1, true) then
	catNote = "Passport outings already reworded"; catOut = nil
else
	for i, pair in ipairs(CAT) do
		local n = count0(catOut, pair[1])
		if n ~= 1 then print(string.format("QQ BOATINV ABORT: Passport.Catalogue anchor %d found %d times (need 1); nothing changed", i, n)) return end
		local a, b = catOut:find(pair[1], 1, true); catOut = catOut:sub(1, a - 1) .. pair[2] .. catOut:sub(b + 1)
	end
	local f, err = loadstring(catOut); if not f then print("QQ BOATINV ABORT: the reworded Catalogue does not compile: " .. tostring(err) .. "; nothing changed") return end
end
-- the BoatServer patches, all checked before anything changes
local A1, I1 = [==[local function take(p)
]==], [==[	if not hasChute(p) and found(p) >= NEED then p:SetAttribute("HasChute", true) end   -- (Oct 11, Shannon: one click; all 44 found = the parachute is packed, before any "see Sky Diving Squirrel" warning)
]==]
local A2, I2 = [==[if prompt then prompt.Triggered:Connect(take) else warn("BoatServer: no BoatPrompt on River.BoatPreview") end
]==], [==[-- one click from the "to the boat" card (Oct 11, Shannon): workspace.BoatInvite puts the player on the jetty, then fires this
do
	local be = game:GetService("ReplicatedStorage"):FindFirstChild("BoatTake")
	if not (be and be:IsA("BindableEvent")) then be = Instance.new("BindableEvent"); be.Name = "BoatTake"; be.Parent = game:GetService("ReplicatedStorage") end
	be.Event:Connect(function(p) if typeof(p) == "Instance" and p:IsA("Player") and p.Parent == game:GetService("Players") then take(p) end end)
end
]==]
local A3, R3 = [==[\nSee Sky Diving Squirrel first.]==], [==[]==]
local function count(s, sub) if sub == "" then return 0 end; local n, i = 0, 1; while true do local a, b = s:find(sub, i, true); if not a then return n end; n += 1; i = b + 1 end end
local src, bsNote = bs.Source, nil
local oldLen = #src
if src:find([==[all 44 found = the parachute is packed]==], 1, true) then
	bsNote = "BoatServer already patched (" .. oldLen .. ")"
else
	if count(src, A1) ~= 1 or count(src, A2) ~= 1 then print(string.format("QQ BOATINV ABORT: BoatServer (%d chars) anchors found take=%d prompt=%d (need 1 and 1); nothing changed", oldLen, count(src, A1), count(src, A2))) return end
	local out = src
	local SKY = {{[==[local CHUTE_LINES = {"All 44 found! Take my spare chute.", "I packed it myself, so it will probably open.", "The river ends in a big drop... you will want it."}]==], [==[local CHUTE_LINES = {"All 44! Now THAT is a high score.", "I once jumped out of a plane and landed in a pie shop. Best day of my life.", "Seen the boat at the river dock? Take it. Trust me."}]==]}, {[==[local CHUTE_NO = "Find all %d squirrels first (%d so far), then come and see me about the falls!"]==], [==[local CHUTE_NO = "Find all %d squirrels (%d so far) and I will tell you my best skydiving story!"]==]}, {[==[local CHUTE_AGAIN = "You already have my chute on your back. Go on, the falls are waiting!"]==], [==[local CHUTE_AGAIN = "Still here? The boat at the river dock is waiting for you!"]==]}, {[==[p:SetAttribute("HasChute", true)
]==], [==[-- (Oct 11: no lending; the boat packs it)
]==]}, {[==[if p.Character then attachPack(p.Character) end]==], [==[-- (no pack from him any more)]==]}}
	for i, pair in ipairs(SKY) do
		local n = count(out, pair[1])
		if n ~= 1 then print(string.format("QQ BOATINV ABORT: BoatServer Sky Diving Squirrel anchor %d found %d times (need 1); nothing changed", i, n)) return end
		local a, b = out:find(pair[1], 1, true); out = out:sub(1, a - 1) .. pair[2] .. out:sub(b + 1)
	end
	local a, b = out:find(A1, 1, true); out = out:sub(1, b) .. I1 .. out:sub(b + 1)
	a, b = out:find(A2, 1, true); out = out:sub(1, b) .. I2 .. out:sub(b + 1)
	local signSrc = count(out, A3) == 1
	if signSrc then a, b = out:find(A3, 1, true); print("QQ BOATINV sign: dropping the line 'See Sky Diving Squirrel first.'"); out = out:sub(1, a - 1) .. R3 .. out:sub(b + 1) end
	local f, err = loadstring(out); if not f then print("QQ BOATINV ABORT: the patched BoatServer does not compile: " .. tostring(err) .. "; nothing changed") return end
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	if not hb:FindFirstChild("BoatServer_pre_invite1") then local bk = bs:Clone(); bk.Name = "BoatServer_pre_invite1"; bk.Enabled = false; bk.Parent = hb end
	bs.Source = out
	bsNote = string.format("BoatServer %d -> %d (backup HudBackup.BoatServer_pre_invite1; the sign's last line %s)", oldLen, #bs.Source, signSrc and "dropped" or "NOT FOUND, left")
end
if bcOut then
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	if not hb:FindFirstChild("BoatClient_pre_invite1") then local bk = bc:Clone(); bk.Name = "BoatClient_pre_invite1"; bk.Enabled = false; bk.Parent = hb end
	local was = #bc.Source; bc.Source = bcOut
	bcNote = string.format("BoatClient %d -> %d, the jetty prompt reads 'Take the boat' / 'Bateau' (backup HudBackup.BoatClient_pre_invite1)", was, #bc.Source)
end
if catOut then
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	if not hb:FindFirstChild("Catalogue_pre_invite1") then local bk = cat:Clone(); bk.Name = "Catalogue_pre_invite1"; bk.Parent = hb end
	local was = #cat.Source; cat.Source = catOut
	catNote = string.format("Passport.Catalogue %d -> %d, 6 boat-outing texts reworded (backup HudBackup.Catalogue_pre_invite1)", was, #cat.Source)
end
local signNote = "the jetty sign is built by BoatServer at run time"
-- RS.BoatTake and the BoatInvite folder
local take = RS:FindFirstChild("BoatTake"); if not (take and take:IsA("BindableEvent")) then take = Instance.new("BindableEvent"); take.Name = "BoatTake"; take.Parent = RS end
local old = workspace:FindFirstChild("BoatInvite")
local attrs = {}
if old then
	for k, v in pairs(old:GetAttributes()) do attrs[k] = v end
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	local n = 1; while hb:FindFirstChild("BoatInvite_pre_" .. n) do n += 1 end
	old.Name = "BoatInvite_pre_" .. n; old.Parent = hb
	for _, s in ipairs(old:GetChildren()) do if s:IsA("BaseScript") then s.Enabled = false end end
end
local F = Instance.new("Folder"); F.Name = "BoatInvite"
local defaults = {Need = 44, RevealDelay = 6, JoinDelay = 25, Place = "The River Dock", Enabled = true}
for k, v in pairs(defaults) do if attrs[k] ~= nil then F:SetAttribute(k, attrs[k]) else F:SetAttribute(k, v) end end
local e = Instance.new("RemoteEvent"); e.Name = "BoatInviteEvent"; e.Parent = F
local s = Instance.new("Script"); s.Name = "BoatInviteServer"; s.Source = SERVER; s.Parent = F
local c = Instance.new("Script"); c.Name = "BoatInviteClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
F.Parent = workspace
print(string.format("QQ BOATINV DONE: workspace.BoatInvite (server %d, client %d chars; Need %s, RevealDelay %s, JoinDelay %s, Enabled %s); RS.BoatTake; %s; %s; %s; %s%s",
	#s.Source, #c.Source, tostring(F:GetAttribute("Need")), tostring(F:GetAttribute("RevealDelay")), tostring(F:GetAttribute("JoinDelay")), tostring(F:GetAttribute("Enabled")),
	bsNote, bcNote, catNote, signNote, old and ("; the old folder is HudBackup." .. old.Name) or ""))
