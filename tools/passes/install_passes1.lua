-- install_passes1.lua (job 109): Studio EDIT mode. Game Passes beside the Acorn Store's once-items (Shannon, Oct 15 2026). (1)
-- workspace.Passes {PassServer} with attributes Pass_ziphandle = 2036372649 and Pass_glider = 2037656625 (existing values kept). (2)
-- Four exact-string patches of workspace.Shop.ShopClient (a green Robux button on the row of any item with a pass id; Roblox's own
-- prompt sells it; PassServer grants the item). Anchors counted first; compiled where loadstring runs; backup
-- HudBackup.ShopClient_pre_pass1. Acorn prices untouched (Price_<id> attributes on workspace.Shop; her call). Output "QQ PASS".
if game:GetService("RunService"):IsRunning() then print("QQ PASS ABORT - Play mode") return end
local SS = game:GetService("ServerStorage")
local SERVER = [===[
-- PassServer (workspace.Passes, RunContext Server). Job 109 (Shannon, Oct 15 2026: "give the chance to purchase with a LOT of acorns OR
-- purchase for robux ... the hand glider, and the zip line handle"). Game Passes stand beside the Acorn Store's once-items: the
-- folder's attributes Pass_<itemId> hold the pass ids (Pass_ziphandle = 2036372649, Pass_glider = 2037656625; 0 = not for sale for Robux). Whoever OWNS a pass gets the item on arrival (UserOwnsGamePassAsync, once the save is loaded), and whoever BUYS
-- one gets it the moment Roblox says the purchase went through (PromptGamePassPurchaseFinished) - through the game's AwardItems
-- ledger, so it is kept on the save exactly like an acorn purchase (Item_<id> = 1; the tower and the ramp check that attribute).
-- The Acorn Store's own prompt for the pass lives in ShopClient (its Robux button). Never a DataStore here.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local MPS = game:GetService("MarketplaceService")
local F = script.Parent
local awardItems = RS:WaitForChild("AwardItems", 60)
if not awardItems then warn("PassServer: no ReplicatedStorage.AwardItems; passes grant nothing") return end
local function passes()
	local t = {}
	for k, v in pairs(F:GetAttributes()) do
		local id = k:match("^Pass_(.+)$")
		if id and tonumber(v) and tonumber(v) > 0 then t[id] = tonumber(v) end
	end
	return t
end
local function grant(p, id, how)
	if (tonumber(p:GetAttribute("Item_" .. id)) or 0) > 0 then return end
	awardItems:Fire(p, id, 1)
	print(string.format("PassServer: %s gets %s (%s)", p.Name, id, how))
end
local function check(p)
	local t0 = os.clock()
	while p.Parent and p:GetAttribute("SaveLoaded") ~= true and os.clock() - t0 < 120 do task.wait(0.5) end
	if not p.Parent then return end
	for id, passId in pairs(passes()) do
		if (tonumber(p:GetAttribute("Item_" .. id)) or 0) <= 0 then
			local ok, owns = pcall(function() return MPS:UserOwnsGamePassAsync(p.UserId, passId) end)
			if ok and owns then grant(p, id, "owns the pass") end
		end
	end
end
MPS.PromptGamePassPurchaseFinished:Connect(function(p, passId, purchased)
	for id, x in pairs(passes()) do
		if x == passId then
			if purchased then grant(p, id, "bought the pass")
			else   -- (Roblox refuses to sell a pass you already own: a player whose arrival check failed still gets the item here)
				local ok, owns = pcall(function() return MPS:UserOwnsGamePassAsync(p.UserId, passId) end)
				if ok and owns then grant(p, id, "owns the pass (checked again)") end
			end
		end
	end
end)
Players.PlayerAdded:Connect(function(p) task.spawn(check, p) end)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(check, p) end
local n = 0
for _ in pairs(passes()) do n += 1 end
print(string.format("PassServer: %d pass(es) on sale", n))
]===]
local Shop = workspace:FindFirstChild("Shop")
local s = Shop and Shop:FindFirstChild("ShopClient")
if not (s and s:IsA("LuaSourceContainer")) then print("QQ PASS ABORT - missing workspace.Shop.ShopClient") return end
local o = s.Source
print("QQ PASS ShopClient is " .. #o .. " chars")
local P = {{[===[
local buy = RS:WaitForChild("ShopBuy")
]===], [===[
local buy = RS:WaitForChild("ShopBuy")
local PASSES = workspace:WaitForChild("Passes", 5)   -- PASS1 (Oct 15 2026): Game Pass ids per item, attributes Pass_<id> on workspace.Passes
]===]}, {[===[
	rec.btn = btn
	if HOTBAR[item.id] then
]===], [===[
	rec.btn = btn
	-- PASS1 (Shannon: "purchase with a LOT of acorns OR purchase for robux"): an item with a Game Pass gets a second, green button;
	-- Roblox's own prompt sells the pass and PassServer grants the item the moment the purchase completes
	local passId = PASSES and tonumber(PASSES:GetAttribute("Pass_" .. item.id)) or 0
	if passId > 0 and item.once and not item.robux then
		local b3 = Instance.new("TextButton")
		b3.Name = "RobuxBtn"; b3.AnchorPoint = Vector2.new(1, 0); b3.Position = UDim2.new(1, -12, 0, 106)
		b3.Size = UDim2.fromOffset(70, 36); b3.BackgroundColor3 = RGB(70, 170, 110); b3.BorderSizePixel = 0
		b3.FontFace = FONT; b3.TextSize = 15; b3.TextColor3 = RGB(255, 255, 255); b3.Text = ROBUX .. " ..."
		b3.AutoButtonColor = false; b3.ZIndex = 4; b3.Visible = false; b3.Parent = row
		corner(b3, UDim.new(0, 10)); stroke(b3, RGB(40, 110, 70), 2, 0.2)
		rec.btn3 = b3
		btn.TextScaled = true; local tc = Instance.new("UITextSizeConstraint"); tc.MaxTextSize = 18; tc.MinTextSize = 9; tc.Parent = btn   -- ("1000 acorns" fits the half-width button)
		task.spawn(function()
			local ok, info = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(passId, Enum.InfoType.GamePass) end)
			if ok and type(info) == "table" and info.PriceInRobux then b3.Text = ROBUX .. " " .. tostring(info.PriceInRobux) end
		end)
		b3.MouseButton1Click:Connect(function()
			if player:GetAttribute("SaveLoaded") ~= true then say(rec, "still loading your save", false) return end   -- (never sell the pass before we know what is already theirs)
			if (player:GetAttribute("Item_" .. item.id) or 0) > 0 then say(rec, "already yours", true) return end
			game:GetService("MarketplaceService"):PromptGamePassPurchase(player, passId)
		end)
	end
	if HOTBAR[item.id] then
]===]}, {[===[
				else
					rec.btn.Size = UDim2.fromOffset(142, 36); rec.btn.Position = UDim2.new(1, -12, 0, 106); rec.btn.TextSize = 18
					rec.btn2.Visible = false
				end
			end
]===], [===[
				else
					rec.btn.Size = UDim2.fromOffset(142, 36); rec.btn.Position = UDim2.new(1, -12, 0, 106); rec.btn.TextSize = 18
					rec.btn2.Visible = false
				end
			end
			if rec.btn3 then   -- PASS1: acorns on the left, Robux on the right, until it is yours
				if owned or player:GetAttribute("SaveLoaded") ~= true then   -- (hidden until the save says what is theirs)
					rec.btn3.Visible = false
					if not rec.btn2 then rec.btn.Size = UDim2.fromOffset(142, 36); rec.btn.Position = UDim2.new(1, -12, 0, 106); rec.btn.TextSize = 18 end
				else
					rec.btn3.Visible = true
					rec.btn.Size = UDim2.fromOffset(70, 36); rec.btn.Position = UDim2.new(1, -86, 0, 106); rec.btn.TextSize = 12
				end
			end
]===]}, {[===[
player:GetAttributeChangedSignal("Acorns"):Connect(refresh)
]===], [===[
player:GetAttributeChangedSignal("Acorns"):Connect(refresh)
player:GetAttributeChangedSignal("SaveLoaded"):Connect(refresh)   -- PASS1: the Robux buttons appear once the save has loaded
]===]}}
local n = o
if o:find("PASS1", 1, true) then print("QQ PASS ShopClient already patched")
else
	for i, p in ipairs(P) do
		local a, b = o:find(p[1], 1, true)
		if not a then print("QQ PASS ABORT - ShopClient anchor " .. i .. " not found; nothing changed") return end
		if o:find(p[1], b + 1, true) then print("QQ PASS ABORT - ShopClient anchor " .. i .. " matches more than once; nothing changed") return end
	end
	for _, p in ipairs(P) do local a, b = n:find(p[1], 1, true); n = n:sub(1, a - 1) .. p[2] .. n:sub(b + 1) end
	local ok, f, err = pcall(function() return loadstring(n) end)
	if ok and not f then print("QQ PASS ABORT - patched ShopClient does not compile: " .. tostring(err) .. "; nothing changed") return end
end
do
	local ok, f, err = pcall(function() return loadstring(SERVER) end)
	if ok and not f then print("QQ PASS ABORT - PassServer does not compile: " .. tostring(err)) return end
end
-- the folder and the server
local F = workspace:FindFirstChild("Passes")
if not F then F = Instance.new("Folder"); F.Name = "Passes"; F.Parent = workspace end
if F:GetAttribute("Pass_ziphandle") == nil then F:SetAttribute("Pass_ziphandle", 2036372649) end
if F:GetAttribute("Pass_glider") == nil then F:SetAttribute("Pass_glider", 2037656625) end
local old = F:FindFirstChild("PassServer")
if old then local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS; local k = 1; while hb:FindFirstChild("PassServer_pre_" .. k) do k += 1 end; old.Name = "PassServer_pre_" .. k; old.Enabled = false; old.Parent = hb end
local sv = Instance.new("Script"); sv.Name = "PassServer"; sv.RunContext = Enum.RunContext.Server; sv.Source = SERVER; sv.Parent = F
-- the client
if n ~= o then
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	if not hb:FindFirstChild("ShopClient_pre_pass1") then local c = s:Clone(); if c then c.Name = "ShopClient_pre_pass1"; c.Enabled = false; c.Parent = hb end end
	s.Source = n
end
print(string.format("QQ PASS DONE: workspace.Passes (PassServer %d chars; Pass_ziphandle %s, Pass_glider %s); ShopClient %d -> %d chars; Price_ziphandle %s, Price_glider %s acorns",
	#SERVER, tostring(F:GetAttribute("Pass_ziphandle")), tostring(F:GetAttribute("Pass_glider")), #o, #n, tostring(Shop:GetAttribute("Price_ziphandle")), tostring(Shop:GetAttribute("Price_glider"))))
