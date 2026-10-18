-- ThanksClient (workspace.Thanks, RunContext Client): the thank-you card (daily-card look). Shown when the server pays a gift;
-- on top of everything until closed (Shannon's rule); never while another panel is open (waits for a clear moment).
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local F = script.Parent
local ev = F:WaitForChild("ThanksEvent")
local C = Color3.fromRGB
local NAVY, GOLD, CREAM, DEEP = C(38, 30, 52), C(240, 200, 90), C(255, 246, 220), C(84, 48, 18)
local FONT = Enum.Font.FredokaOne
local phone = (function() local ok, pi = pcall(function() return UIS.PreferredInput end); if ok and pi ~= nil then return pi == Enum.PreferredInput.Touch end; return UIS.TouchEnabled and not UIS.MouseEnabled end)()
local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = o end
local gui = Instance.new("ScreenGui"); gui.Name = "ThanksGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 100; gui.Enabled = false; gui.Parent = pg
local W, H = 320, 168
local card = Instance.new("Frame"); card.AnchorPoint = Vector2.new(0.5, 0); card.Position = UDim2.new(0.5, 0, 0, phone and 78 or 110)
card.Size = UDim2.fromOffset(W, H); card.BackgroundColor3 = NAVY; card.BorderSizePixel = 0; card.Parent = gui; corner(card, 16)
local cs = Instance.new("UIStroke"); cs.Color = GOLD; cs.Thickness = 2; cs.Parent = card
local function text(t, size, colour, y, h)
	local l = Instance.new("TextLabel"); l.Position = UDim2.fromOffset(16, y); l.Size = UDim2.fromOffset(W - 32, h); l.BackgroundTransparency = 1
	l.Font = FONT; l.TextSize = size; l.TextColor3 = colour; l.Text = t; l.TextWrapped = true; l.Parent = card
	return l
end
local title = text("A thank-you from the mayor", 20, CREAM, 10, 26)
local note = text("", 14, GOLD, 38, 56)
local sum = text("", 15, CREAM, 94, 22)
local ok = Instance.new("TextButton"); ok.AnchorPoint = Vector2.new(0.5, 1); ok.Position = UDim2.new(0.5, 0, 1, -10); ok.Size = UDim2.fromOffset(150, 34)
ok.BackgroundColor3 = GOLD; ok.BorderSizePixel = 0; ok.Font = FONT; ok.TextSize = 17; ok.TextColor3 = DEEP; ok.Text = "Thank you!"; ok.Parent = card; corner(ok, 12)
local function close() gui.Enabled = false; if pg:GetAttribute("OpenPanel") == "thanks" then pg:SetAttribute("OpenPanel", nil) end end
ok.Activated:Connect(close)
pg:GetAttributeChangedSignal("OpenPanel"):Connect(function() if gui.Enabled and pg:GetAttribute("OpenPanel") ~= "thanks" then gui.Enabled = false end end)
ev.OnClientEvent:Connect(function(info)
	if type(info) ~= "table" then return end
	title.Text = tostring(info.title or "A thank-you from the mayor"); note.Text = tostring(info.note or "")
	sum.Text = string.format("%d acorns are in your purse.", tonumber(info.acorns) or 0)
	-- Keep longer personal notes above the acorn amount and button.
	local bounds = game:GetService("TextService"):GetTextSize(note.Text, note.TextSize, FONT, Vector2.new(W - 32, 10000))
	local noteHeight = math.max(56, bounds.Y + 8)
	note.Size = UDim2.fromOffset(W - 32, noteHeight)
	sum.Position = UDim2.fromOffset(16, 38 + noteHeight)
	card.Size = UDim2.fromOffset(W, H + noteHeight - 56)
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < 120 do
			local daily = pg:FindFirstChild("DailyGui"); local dcard = daily and daily:FindFirstChild("DailyCard")
			local dailyUp = daily ~= nil and daily.Enabled and dcard ~= nil and dcard.Visible
			if pg:GetAttribute("OpenPanel") == nil and not dailyUp then pg:SetAttribute("OpenPanel", "thanks"); gui.Enabled = true; return end
			task.wait(1)
		end
		pg:SetAttribute("OpenPanel", "thanks"); gui.Enabled = true   -- (two minutes of panels: show it anyway; the acorns are already theirs)
	end)
end)
print("ThanksClient: ready")
