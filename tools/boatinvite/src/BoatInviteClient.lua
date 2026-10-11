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

local gui = Instance.new("ScreenGui"); gui.Name = "BoatInviteGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 20; gui.Enabled = false; gui.Parent = pg
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
text("The boat to Italy is waiting at the river dock. Your parachute is packed for the waterfall!", 14, GOLD, 40, 52)
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
