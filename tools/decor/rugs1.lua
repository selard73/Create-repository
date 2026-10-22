-- rugs1 (Oct 21 2026): ROADMAP STEP 2 - the Homebase decor system, as Shannon shaped it in the Oct 21 previews:
--   * a "Treehouse" tab in the Passport beside Wardrobe (the Passport's own fit() sizes ALL tabs, so five fit on
--     every screen - her "the buttons at the top need to be smaller so they all fit");
--   * the tab is the COLLECTION: Place / Store only, NO buying there ("you will buy and collect new pieces in the
--     game, you will decide which pieces to display in treehouse from the tab");
--   * three NATIVE rugs, all free ("I thought sunny gold and blue were free"): Classic Red (the default on the
--     floor), Sunny Yellow, Pastel Blue; storing them all leaves the floor bare; paid decor starts at the Cute tier;
--   * a one-time first-build tip ("when the treehouse first builds ... a mini tutorial or suggestion"): a toast +
--     the Passport button glows for a minute (her earlier "glowy thing on the passport icon" idea), once ever.
-- Ledger only: placed rug = Item_rugon_<id> (at most one), bare floor = Item_rug_bare, tip seen = Item_tree_decortip,
-- all through RS.AwardItems. Never a DataStore.
-- Run in Studio EDIT. Backs PassportClient + TreehouseClient up to ServerStorage.HudBackup first.
-- New instances: workspace.Treehouse.DecorServer, workspace.Treehouse.DecorClient, RS.DecorAction (made by DecorServer).

-- ============ PART 1: PassportClient - the Treehouse tab ============
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")
local pass = workspace.Passport.PassportClient
local src = pass.Source
assert(not src:find("rugs1", 1, true), "PassportClient already patched")
local function rep(old, new, what)
	local a, b = src:find(old, 1, true)
	assert(a, "PassportClient: " .. what .. " not found - nothing changed")
	assert(not src:find(old, b + 1, true), "PassportClient: " .. what .. " found twice - nothing changed")
	src = src:sub(1, a - 1) .. new .. src:sub(b + 1)
end
rep([=[for _,name in ipairs({"Outings","Completed","Clues","Wardrobe"})do tabs[name]=button(panel,name,name,0,56,95,30);tabs[name].TextSize=13 end]=],
	[=[for _,name in ipairs({"Outings","Completed","Clues","Wardrobe","Treehouse"})do tabs[name]=button(panel,name,name,0,56,95,30);tabs[name].TextSize=13 end]=],
	"tab list")
rep([=[return hasCities() and not detail and selected~="Wardrobe" end]=],
	[=[return hasCities() and not detail and selected~="Wardrobe" and selected~="Treehouse" end]=],
	"showCities")
rep([=[tabs.Wardrobe.Text="      Wardrobe"
]=],
	[=[tabs.Wardrobe.Text="      Wardrobe"
-- (rugs1, Oct 21 2026, Shannon) the Treehouse tab: the decor collection lives here (DecorClient fills DecorContent);
-- it appears once the Homebase stands finished. A mini rug is its badge, like the Wardrobe's suitcase.
tabs.Treehouse.Visible=false
local decorPage=Instance.new("Frame");decorPage.Name="DecorContent";decorPage.BackgroundTransparency=1;decorPage.Visible=false;decorPage.ZIndex=3;decorPage.Parent=panel
local function hasDecor()return (tonumber(p:GetAttribute("Item_tree_done")) or 0)>=1 end
local rugBadge=Instance.new("Frame");rugBadge.Name="MiniRug";rugBadge.Size=UDim2.fromOffset(24,15);rugBadge.Position=UDim2.new(.5,-57,.5,-6);rugBadge.BackgroundColor3=C(188,74,64);rugBadge.BorderSizePixel=0;rugBadge.Parent=tabs.Treehouse;round(rugBadge,7);stroke(rugBadge,C(121,65,29),1)
local rugRing=Instance.new("Frame");rugRing.Size=UDim2.fromOffset(14,7);rugRing.Position=UDim2.fromOffset(5,4);rugRing.BackgroundTransparency=1;rugRing.Parent=rugBadge;round(rugRing,4);stroke(rugRing,C(255,211,111),1)
tabs.Treehouse.Text="      Treehouse"
]=],
	"tab setup block")
rep([=[if selected=="Wardrobe" and not hasWardrobe()then selected="Outings";fit()end]=],
	[=[if selected=="Wardrobe" and not hasWardrobe()then selected="Outings";fit()end
 if selected=="Treehouse" and not hasDecor()then selected="Outings";fit()end]=],
	"wardrobe fallback")
rep([=[b.Visible=not detail and (name~="Wardrobe" or hasWardrobe())]=],
	[=[b.Visible=not detail and (name~="Wardrobe" or hasWardrobe()) and (name~="Treehouse" or hasDecor())]=],
	"tab visibility")
rep([=[wardrobe.Visible=not detail and selected=="Wardrobe";scroll.Visible=not wardrobe.Visible]=],
	[=[wardrobe.Visible=not detail and selected=="Wardrobe";decorPage.Visible=not detail and selected=="Treehouse";scroll.Visible=not wardrobe.Visible and not decorPage.Visible]=],
	"page switching")
rep([=[ elseif selected=="Wardrobe"then
  summary.Text="Your outfits & accessories"]=],
	[=[ elseif selected=="Wardrobe"then
  summary.Text="Your outfits & accessories"
 elseif selected=="Treehouse"then
  summary.Text="Your Homebase, your way"]=],
	"summary branch")
rep([=[wardrobe.Position=UDim2.fromOffset(14,93);wardrobe.Size=UDim2.fromOffset(contentWidth,math.max(1,height-103))]=],
	[=[wardrobe.Position=UDim2.fromOffset(14,93);wardrobe.Size=UDim2.fromOffset(contentWidth,math.max(1,height-103))
 decorPage.Position=UDim2.fromOffset(14,93);decorPage.Size=UDim2.fromOffset(contentWidth,math.max(1,height-103))]=],
	"page sizing")
rep([=[ local names=hasWardrobe() and {"Outings","Completed","Clues","Wardrobe"}or{"Outings","Completed","Clues"}]=],
	[=[ local names={"Outings","Completed","Clues"}
 if hasWardrobe()then names[#names+1]="Wardrobe" end
 if hasDecor()then names[#names+1]="Treehouse" end]=],
	"tab row names")
rep([=[pg:GetAttributeChangedSignal("HasWardrobe"):Connect(function()fit();render()end)]=],
	[=[pg:GetAttributeChangedSignal("HasWardrobe"):Connect(function()fit();render()end)
p:GetAttributeChangedSignal("Item_tree_done"):Connect(function()fit();render()end)]=],
	"refresh hook")
local bkP = pass:Clone(); bkP.Name = "PassportClient_pre_rugs1"; bkP.Enabled = false; bkP.Parent = backup
SES:UpdateSourceAsync(pass, function() return src end)
print(string.format("rugs1 part 1: PassportClient -> %d chars", #pass.Source))

-- ============ PART 2: TreehouseClient - the floor obeys the ledger + the first-build tip ============
local tc = workspace.Treehouse.TreehouseClient
local src2 = tc.Source
assert(not src2:find("rugs1", 1, true), "TreehouseClient already patched")
local anchor = [=[local gotLocal = {}]=]
local a2, b2 = src2:find(anchor, 1, true)
assert(a2, "TreehouseClient: gotLocal anchor not found")
assert(not src2:find(anchor, b2 + 1, true), "TreehouseClient: gotLocal anchor found twice")
local decorBlock = [=[-- HOMEBASE DECOR (rugs1, Oct 21 2026): the rug on the floor is the one placed in Passport -> Treehouse. Three
-- native rugs, all free; the placed one is Item_rugon_<id> (at most one line), Item_rug_bare = 1 is a deliberately
-- bare floor, and no lines at all is the Classic Red everyone starts with. DecorServer swaps the lines; the floor obeys.
local RUG_COLOURS = {red = C(188, 74, 64), sunny = C(238, 196, 88), pastel = C(154, 196, 230)}
local function rugChoice()
	if (tonumber(player:GetAttribute("Item_rug_bare")) or 0) >= 1 then return nil end
	for id in pairs(RUG_COLOURS) do
		if id ~= "red" and (tonumber(player:GetAttribute("Item_rugon_" .. id)) or 0) >= 1 then return id end
	end
	return "red"
end
local function decorRug(rugPart)
	local choice = rugChoice()
	rugPart.Transparency = choice and 0 or 1
	if choice then rugPart.Color = RUG_COLOURS[choice] end
end
player.AttributeChanged:Connect(function(attrName)
	if attrName:sub(1, 11) == "Item_rugon_" or attrName == "Item_rug_bare" then
		local lf = workspace:FindFirstChild("Treehouse_local")
		local lh = lf and lf:FindFirstChild("House")
		local rugPart = lh and lh:FindFirstChild("HomebaseRug")
		if rugPart then decorRug(rugPart) end
	end
end)
local gotLocal = {}]=]
src2 = src2:sub(1, a2 - 1) .. decorBlock .. src2:sub(b2 + 1)
local oldRug = [=[		local rug = part(Vector3.new(0.1, 7.0, 7.0), C(188, 74, 64), L(0, 10.55, 0.5, 0, 0, 90), houseF, Enum.Material.Fabric); rug.Shape = Enum.PartType.Cylinder   -- (a cylinder's length is its X; stood on end it is a disc)]=]
local newRug = [=[		local rug = part(Vector3.new(0.1, 7.0, 7.0), C(188, 74, 64), L(0, 10.55, 0.5, 0, 0, 90), houseF, Enum.Material.Fabric); rug.Shape = Enum.PartType.Cylinder   -- (a cylinder's length is its X; stood on end it is a disc)
		rug.Name = "HomebaseRug"; decorRug(rug)   -- (rugs1: the placed rug's colour, or a bare floor)]=]
local c2, d2 = src2:find(oldRug, 1, true)
assert(c2, "TreehouseClient: rug line not found")
assert(not src2:find(oldRug, d2 + 1, true), "TreehouseClient: rug line found twice")
src2 = src2:sub(1, c2 - 1) .. newRug .. src2:sub(d2 + 1)
local tipBlock = [=[

-- THE FIRST-BUILD DECOR TIP (rugs1, Oct 21 2026, Shannon: "we need a mini tutorial or suggestion to show how to and
-- that they can decorate"): once, when the house stands finished (Item_tree_done), a toast says the Homebase can be
-- decorated and the Passport button glows for a minute (or until the Passport opens). Item_tree_decortip on the
-- ledger keeps it to once ever; it waits 6 s so the "Treehouse built!" fanfare has the stage first.
task.spawn(function()
	local t0 = os.clock()
	while player:GetAttribute("SaveLoaded") ~= true and os.clock() - t0 < 120 do task.wait(0.5) end
	local act = RS:WaitForChild("DecorAction", 30)
	if not act then return end
	local shown = false
	local function maybeTip()
		if shown then return end
		if (tonumber(player:GetAttribute("Item_tree_decortip")) or 0) >= 1 then return end
		if (tonumber(player:GetAttribute("Item_tree_done")) or 0) < 1 then return end
		shown = true
		task.wait(6)
		local ok = pcall(function() return act:InvokeServer("tip") end)
		if not ok then return end
		local tg = Instance.new("ScreenGui"); tg.Name = "DecorTip"; tg.ResetOnSpawn = false; tg.DisplayOrder = 8; tg.Parent = pg
		local tipNote = Instance.new("TextLabel"); tipNote.AnchorPoint = Vector2.new(0.5, 1); tipNote.Position = UDim2.new(0.5, 0, 1, -118)
		tipNote.Size = UDim2.fromOffset(470, 44); tipNote.BackgroundColor3 = NAVY; tipNote.BackgroundTransparency = 0.1
		tipNote.Font = FONT; tipNote.TextSize = 16; tipNote.TextColor3 = GOLD; tipNote.TextWrapped = true
		tipNote.Text = "Your Homebase is yours to decorate! Open your Passport -> Treehouse to choose a rug."
		tipNote.Parent = tg
		local tc2 = Instance.new("UICorner"); tc2.CornerRadius = UDim.new(0, 14); tc2.Parent = tipNote
		local ts2 = Instance.new("UIStroke"); ts2.Color = GOLD; ts2.Thickness = 2; ts2.Parent = tipNote
		Debris:AddItem(tg, 8)
		local hudBtn
		for _, g in ipairs(pg:GetChildren()) do
			if g:IsA("ScreenGui") and g.Enabled then
				for _, d in ipairs(g:GetDescendants()) do
					if d:IsA("TextLabel") and d.Text == "Passport" and d.Visible then hudBtn = d.Parent break end
				end
			end
			if hudBtn then break end
		end
		if hudBtn then
			local glow = Instance.new("UIStroke"); glow.Name = "DecorTipGlow"; glow.Color = C(255, 222, 120); glow.Thickness = 3.5; glow.Parent = hudBtn
			task.spawn(function()
				local t1 = os.clock()
				while os.clock() - t1 < 60 and glow.Parent and pg:GetAttribute("OpenPanel") ~= "passport" do
					TweenService:Create(glow, TweenInfo.new(0.6), {Transparency = 0.65}):Play(); task.wait(0.65)
					TweenService:Create(glow, TweenInfo.new(0.6), {Transparency = 0}):Play(); task.wait(0.65)
				end
				if glow.Parent then glow:Destroy() end
			end)
		end
	end
	player.AttributeChanged:Connect(function(attrName) if attrName == "Item_tree_done" then task.defer(maybeTip) end end)
	maybeTip()
end)
]=]
src2 = src2 .. tipBlock
local bkT = tc:Clone(); bkT.Name = "TreehouseClient_pre_rugs1"; bkT.Enabled = false; bkT.Parent = backup
SES:UpdateSourceAsync(tc, function() return src2 end)
print(string.format("rugs1 part 2: TreehouseClient -> %d chars", #tc.Source))

-- ============ PART 3: the two new scripts ============
local F = workspace.Treehouse
local oldS = F:FindFirstChild("DecorServer"); if oldS then oldS:Destroy() end
local oldC = F:FindFirstChild("DecorClient"); if oldC then oldC:Destroy() end
local ds = Instance.new("Script"); ds.Name = "DecorServer"; ds.Parent = F
SES:UpdateSourceAsync(ds, function() return [==[
-- DecorServer (workspace.Treehouse; rugs1 Oct 21 2026): the Homebase decor ledger. Three native rugs (red, sunny,
-- pastel - free, everyone's from the start); the placed one is Item_rugon_<id> (at most one line), a deliberately
-- bare floor is Item_rug_bare, and no lines at all means the Classic Red default. Also pays the one-time
-- "decorate your Homebase" tip flag (Item_tree_decortip) once the house is done. Everything through RS.AwardItems -
-- never a DataStore.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local award = RS:WaitForChild("AwardItems")
local act = RS:FindFirstChild("DecorAction")
if not act then act = Instance.new("RemoteFunction"); act.Name = "DecorAction"; act.Parent = RS end
local RUGS = {red = true, sunny = true, pastel = true}
local function floorLines(p)
	local out = {}
	for name, v in pairs(p:GetAttributes()) do
		if name:sub(1, 11) == "Item_rugon_" and (tonumber(v) or 0) > 0 and RUGS[name:sub(12)] then out[#out + 1] = name:sub(12) end
	end
	return out
end
local function clearFloor(p)
	for _, id in ipairs(floorLines(p)) do award:Fire(p, "rugon_" .. id, -1) end
	if (tonumber(p:GetAttribute("Item_rug_bare")) or 0) > 0 then award:Fire(p, "rug_bare", -1) end
end
local last = {}
act.OnServerInvoke = function(p, what, id)
	if os.clock() - (last[p] or 0) < 0.25 then return false, "one at a time" end
	last[p] = os.clock()
	if what == "place" then
		if type(id) ~= "string" or not RUGS[id] then return false, "no such rug" end
		clearFloor(p)
		if id ~= "red" then award:Fire(p, "rugon_" .. id, 1) end   -- red is the default; it needs no line
		return true
	elseif what == "store" then
		clearFloor(p)
		award:Fire(p, "rug_bare", 1)
		return true
	elseif what == "tip" then
		if (tonumber(p:GetAttribute("Item_tree_done")) or 0) < 1 then return false end
		if (tonumber(p:GetAttribute("Item_tree_decortip")) or 0) >= 1 then return false end
		award:Fire(p, "tree_decortip", 1)
		return true
	end
	return false, "?"
end
Players.PlayerRemoving:Connect(function(p) last[p] = nil end)
print("DecorServer: ready - rugs red/sunny/pastel, the floor through the ledger")
]==] end)
local dc = Instance.new("Script"); dc.Name = "DecorClient"; dc.RunContext = Enum.RunContext.Client; dc.Parent = F
SES:UpdateSourceAsync(dc, function() return [==[
-- DecorClient (workspace.Treehouse, RunContext Client; rugs1 Oct 21 2026): fills the Passport's Treehouse tab
-- (Page.DecorContent, made by PassportClient) with the decor collection. Three native rugs to start: place one on
-- the Homebase floor or store them all for a bare floor. No buying here - priced decor is bought out in the game
-- (from the Cute tier on) and simply appears in this list once owned.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local C = Color3.fromRGB
local INK, MUTED = C(60, 40, 20), C(150, 110, 60)
local FONT = Enum.Font.FredokaOne
local act = RS:WaitForChild("DecorAction", 60)
if not act then return end
local gui = pg:WaitForChild("PassportGui", 60)
local page = gui and gui:WaitForChild("Page", 30)
local decor = page and page:WaitForChild("DecorContent", 30)
if not decor then return end
local RUGS = {
	{id = "red", name = "Classic Red", colour = C(188, 74, 64)},
	{id = "sunny", name = "Sunny Yellow", colour = C(238, 196, 88)},
	{id = "pastel", name = "Pastel Blue", colour = C(154, 196, 230)},
}
local function rugOn()
	if (tonumber(player:GetAttribute("Item_rug_bare")) or 0) >= 1 then return nil end
	for _, r in ipairs(RUGS) do
		if r.id ~= "red" and (tonumber(player:GetAttribute("Item_rugon_" .. r.id)) or 0) >= 1 then return r.id end
	end
	return "red"
end
local function round(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = o end
local function label(txt, x, y, w, h, size, colour, font)
	local l = Instance.new("TextLabel"); l.Position = UDim2.fromOffset(x, y); l.Size = UDim2.fromOffset(w, h)
	l.BackgroundTransparency = 1; l.Font = font or FONT; l.TextSize = size; l.TextColor3 = colour; l.Text = txt
	l.TextXAlignment = Enum.TextXAlignment.Left; l.ZIndex = 4; l.Parent = decor
	return l
end
label("Make the Homebase yours", 3, 0, 400, 22, 18, INK)
label("Place a rug on the floor, or store it for later.", 3, 24, 420, 16, 13, C(110, 70, 30), Enum.Font.BuilderSans)
label("RUG", 3, 52, 100, 14, 12, MUTED)
local rows = {}
local busy = false
local refresh
for i, r in ipairs(RUGS) do
	local y = 72 + (i - 1) * 60
	local row = Instance.new("Frame"); row.Position = UDim2.fromOffset(3, y); row.Size = UDim2.new(1, -10, 0, 52)
	row.BackgroundColor3 = C(255, 255, 255); row.BackgroundTransparency = 0.35; row.BorderSizePixel = 0; row.ZIndex = 4; row.Parent = decor
	round(row, 12)
	local sw = Instance.new("Frame"); sw.Position = UDim2.fromOffset(8, 8); sw.Size = UDim2.fromOffset(36, 36)
	sw.BackgroundColor3 = r.colour; sw.BorderSizePixel = 0; sw.ZIndex = 5; sw.Parent = row
	round(sw, 18)
	local st = Instance.new("UIStroke"); st.Color = C(200, 180, 150); st.Thickness = 1.5; st.Parent = sw
	local nm = Instance.new("TextLabel"); nm.Position = UDim2.fromOffset(56, 7); nm.Size = UDim2.fromOffset(220, 18)
	nm.BackgroundTransparency = 1; nm.Font = FONT; nm.TextSize = 15; nm.TextColor3 = INK; nm.Text = r.name
	nm.TextXAlignment = Enum.TextXAlignment.Left; nm.ZIndex = 5; nm.Parent = row
	local tag = Instance.new("TextLabel"); tag.Position = UDim2.fromOffset(56, 27); tag.Size = UDim2.fromOffset(220, 15)
	tag.BackgroundTransparency = 1; tag.Font = FONT; tag.TextSize = 12; tag.TextColor3 = MUTED; tag.Text = ""
	tag.TextXAlignment = Enum.TextXAlignment.Left; tag.ZIndex = 5; tag.Parent = row
	local b = Instance.new("TextButton"); b.AnchorPoint = Vector2.new(1, 0); b.Position = UDim2.new(1, -10, 0, 10)
	b.Size = UDim2.fromOffset(86, 32); b.BackgroundColor3 = C(245, 170, 60); b.Font = FONT; b.TextSize = 15
	b.TextColor3 = INK; b.Text = ""; b.AutoButtonColor = true; b.ZIndex = 5; b.Parent = row
	round(b, 10)
	local bs = Instance.new("UIStroke"); bs.Color = C(200, 150, 90); bs.Thickness = 1.5; bs.Parent = b
	rows[r.id] = {tag = tag, btn = b}
	b.Activated:Connect(function()
		if busy then return end
		busy = true
		local what = (r.id == rugOn()) and "store" or "place"
		pcall(function() act:InvokeServer(what, r.id) end)
		task.wait(0.2)
		busy = false
		if refresh then refresh() end
	end)
end
label("Decor you find or buy out in the game appears here.", 3, 72 + #RUGS * 60 + 8, 460, 16, 12, MUTED, Enum.Font.BuilderSans)
refresh = function()
	local on = rugOn()
	for id, row in pairs(rows) do
		row.tag.Text = (id == on) and "On the floor" or "Stored"
		row.tag.TextColor3 = (id == on) and C(64, 112, 48) or MUTED
		row.btn.Text = (id == on) and "Store" or "Place"
		row.btn.BackgroundColor3 = (id == on) and C(236, 226, 206) or C(245, 170, 60)
	end
end
player.AttributeChanged:Connect(function(name)
	if name:sub(1, 11) == "Item_rugon_" or name == "Item_rug_bare" then refresh() end
end)
refresh()
print("DecorClient: ready - " .. #RUGS .. " rugs in the Treehouse tab")
]==] end)
print("rugs1 part 3: DecorServer + DecorClient created")
return "rugs1 installed"
