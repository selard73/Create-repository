-- PortraitServer: the sitters' list (newest first, at most Slots), its save, and the easels' pictures
local Players = game:GetService("Players")
local DSS = game:GetService("DataStoreService")
local G = script.Parent
local slots = G:WaitForChild("Slots")
local done = G:WaitForChild("PortraitDone")
local MAX = G:GetAttribute("Slots") or 12
local store
pcall(function() store = DSS:GetDataStore("PortraitWall") end)
local list = {}                                              -- {id=, name=, t=}, newest first

local function show()
	for i = 1, MAX do
		local slot = slots:FindFirstChild("Slot" .. i)
		local canvas = slot and slot:FindFirstChild("Canvas", true)
		local gui = canvas and canvas:FindFirstChild("Picture")
		local plaque = slot and slot:FindFirstChild("Plaque")
		local e = list[i]
		if gui then
			local img, wash = gui:FindFirstChild("Portrait"), gui:FindFirstChild("Wash")
			local back, over = gui:FindFirstChild("Backdrop"), gui:FindFirstChild("Overlay")
			-- the dressing, from the user id: one of five painted scenes always, a companion four times in five (Shannon: "I
			-- like the different backgrounds and companions")
			local id = e and tonumber(e.id) or 0
			local scene = (id % 5) + 1
			local buddy = (math.floor(id / 7) % 5) + 1                    -- 5 = alone
			-- the sitter's place: centred, or to one side when the scene asks (SitX / SitScale attributes on the scene frame);
			-- a corner companion then shows on the far side - its mirrored copy when it was drawn on the sitter's side
			local sf = e and G:FindFirstChild("Scenes") and G.Scenes:FindFirstChild("Scene" .. scene)   -- the template to clone
			local sitX, sitS = (sf and sf:GetAttribute("SitX")) or 0.5, (sf and sf:GetAttribute("SitScale")) or 1
			img.Size = UDim2.fromScale(sitS, sitS); img.Position = UDim2.fromScale(sitX - sitS / 2, 1 - sitS)
			local side = (sitX < 0.45 and -1) or (sitX > 0.55 and 1) or 0
			local DRAWN = {[2] = 1, [3] = -1, [4] = 1}                       -- the side each corner companion was drawn on
			local want = "Buddy" .. buddy .. ((side ~= 0 and DRAWN[buddy] == side) and "M" or "")
			if back then back:ClearAllChildren(); if sf then local sc = sf:Clone(); sc.Visible = true; sc.Parent = back end end
			if over then for _, c in ipairs(over:GetChildren()) do c.Visible = (e ~= nil) and (c.Name == want) end end
			local b1 = img:FindFirstChild("Buddy1"); if b1 then b1.Visible = (e ~= nil) and (buddy == 1) end
			if e then
				img.Image = "rbxthumb://type=AvatarBust&id=" .. tostring(e.id) .. "&w=420&h=420"
				img.Visible = true; wash.Visible = true
			else
				img.Image = ""; img.Visible = false; wash.Visible = false
			end
		end
		if plaque then
			local sg = plaque:FindFirstChildWhichIsA("SurfaceGui")
			local t = sg and sg:FindFirstChild("Name")
			if t then t.Text = e and tostring(e.name) or "" end
		end
	end
end

local function merge(saved, entry)
	local out = {}
	if entry then out[1] = entry end
	for _, e in ipairs(saved or {}) do
		if type(e) == "table" and e.id and (not entry or e.id ~= entry.id) and #out < MAX then out[#out + 1] = e end
	end
	return out
end

local listLoaded = false
local function load()
	if not store then listLoaded = true return end
	local ok, saved = pcall(function() return store:GetAsync("latest") end)
	if ok and type(saved) == "table" then list = merge(saved, nil); show() end
	listLoaded = true
end

local function hang(player, late)
	local entry = {id = player.UserId, name = player.DisplayName, t = os.time()}
	list = merge(list, entry)
	show()
	if store then
		local ok, err = pcall(function()
			store:UpdateAsync("latest", function(saved) return merge(saved, entry) end)
		end)
		if not ok then warn("PortraitServer: could not save the gallery - " .. tostring(err)) end
	end
	-- the flourish: sparkle at the newest easel, and a word to the sitter
	local canvas = slots:FindFirstChild("Slot1") and slots.Slot1:FindFirstChild("Canvas", true)
	local em = canvas and canvas:FindFirstChild("Sparkle") and canvas.Sparkle:FindFirstChildOfClass("ParticleEmitter")
	if em then em:Emit(70) end
	local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(player,"portrait",{}) end
	done:FireClient(player, "hung", late == true)
end

-- A PURCHASE IS THE SHOP'S AWARD: the shop pays for a portrait with AwardItems(player, "portrait", 1), and that event
-- is the signal. (It used to be a RISING Item_portrait, which missed every FIRST purchase: a player who had never
-- bought one has no count in their save, so the count went from nothing to 1 - which looked like the save loading.
-- Shannon's alt paid 120 acorns and got no painting.)
local function paintedKey(uid) return "painted_u" .. tostring(uid) end
local function remember(player)                          -- how many of their portraits have been painted, kept per player
	if not store then return end
	local n = tonumber(player:GetAttribute("Item_portrait")) or 0
	local ok, err = pcall(function() store:SetAsync(paintedKey(player.UserId), n) end)
	if not ok then warn("PortraitServer: could not note " .. player.Name .. "'s painted count - " .. tostring(err)) end
end
local itemEv = game:GetService("ReplicatedStorage"):WaitForChild("AwardItems", 30)
if itemEv and itemEv:IsA("BindableEvent") then
	itemEv.Event:Connect(function(player, id, n)
		if id ~= "portrait" or (tonumber(n) or 0) <= 0 then return end
		if typeof(player) ~= "Instance" or not player:IsA("Player") then return end
		task.defer(function()
			hang(player)
			remember(player)
			print("PortraitServer: painted " .. player.Name .. " (bought " .. tostring(player:GetAttribute("Item_portrait")) .. ")")
		end)
	end)
else
	warn("PortraitServer: no AwardItems event - portraits cannot be bought")
end
-- MAKING GOOD: anyone who has paid for a portrait but was never painted - those missed first purchases above all - gets
-- it painted when they next come in, with an apology in the note. The count painted is kept per player, so a sitter
-- moved off the easels by newer ones is not hung again on every visit.
local function owed(player)
	if not store then return end
	local t0 = os.clock()
	while player.Parent and not (player:GetAttribute("SaveLoaded") and listLoaded) and os.clock() - t0 < 40 do task.wait(0.5) end
	if not player.Parent or not listLoaded then return end
	local bought = tonumber(player:GetAttribute("Item_portrait")) or 0
	if bought <= 0 then return end
	local ok, painted = pcall(function() return store:GetAsync(paintedKey(player.UserId)) end)
	if not ok then return end
	painted = tonumber(painted)
	local onWall = false
	for _, e in ipairs(list) do if tonumber(e.id) == player.UserId then onWall = true end end
	if (painted == nil and not onWall) or (painted ~= nil and bought > painted) then
		task.wait(5)                                        -- their screen is up by now, so they see the note
		if not player.Parent then return end
		hang(player, true)
		print("PortraitServer: made good " .. player.Name .. "'s unpainted portrait (bought " .. bought .. ", painted " .. tostring(painted) .. ")")
	end
	if painted == nil or bought > painted then remember(player) end
end
Players.PlayerAdded:Connect(function(p) task.spawn(owed, p) end)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(owed, p) end
show()
task.spawn(load)
print("PortraitServer: ready - " .. (store and "gallery saved in DataStore PortraitWall" or "no DataStore, gallery kept in memory"))
