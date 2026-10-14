-- TravelClient: the fade between cities (dark, the destination's name, then the new place), the small notes, and the
-- travel carts' prompts, which this player only gets once Porto Nocciola is opened (Item_porto >= 1).
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local p = Players.LocalPlayer
local F = script.Parent
local ev = F:WaitForChild("TravelEvent")
local gui = Instance.new("ScreenGui"); gui.Name = "TravelGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 30; gui.Parent = p:WaitForChild("PlayerGui")
local dark = Instance.new("Frame"); dark.Name = "Dark"; dark.Size = UDim2.fromScale(1, 1); dark.BackgroundColor3 = Color3.fromRGB(22, 15, 10)
dark.BackgroundTransparency = 1; dark.BorderSizePixel = 0; dark.Visible = false; dark.ZIndex = 10; dark.Parent = gui
local name = Instance.new("TextLabel"); name.AnchorPoint = Vector2.new(0.5, 0.5); name.Position = UDim2.fromScale(0.5, 0.5); name.Size = UDim2.new(0.9, 0, 0, 60)
name.BackgroundTransparency = 1; name.Font = Enum.Font.FredokaOne; name.TextSize = 34; name.TextWrapped = true; name.TextColor3 = Color3.fromRGB(255, 244, 214)
name.TextTransparency = 1; name.ZIndex = 11; name.Parent = dark
local toast = Instance.new("TextLabel"); toast.AnchorPoint = Vector2.new(0.5, 0); toast.Position = UDim2.new(0.5, 0, 0, 72)
toast.Size = UDim2.new(0.92, 0, 0, 56); toast.BackgroundColor3 = Color3.fromRGB(58, 36, 16); toast.BackgroundTransparency = 0.1
toast.BorderSizePixel = 0; toast.Font = Enum.Font.FredokaOne; toast.TextSize = 17; toast.TextWrapped = true
toast.TextColor3 = Color3.fromRGB(255, 244, 214); toast.Visible = false; toast.Parent = gui
Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 12)
local lim = Instance.new("UISizeConstraint"); lim.MaxSize = Vector2.new(460, 56); lim.Parent = toast
local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 12); pad.PaddingRight = UDim.new(0, 12); pad.Parent = toast
local shown = 0
local function note(text, secs)
	shown += 1
	local me = shown
	toast.Text = text; toast.Visible = true
	task.delay(secs or 4, function() if shown == me then toast.Visible = false end end)
end
local trip = 0
local fadeIn
local function fadeOut(where)
	trip += 1
	local me = trip
	name.Text = where or ""
	dark.Visible = true
	TweenService:Create(dark, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
	TweenService:Create(name, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
	task.delay(5, function() if trip == me and dark.Visible then fadeIn() end end)   -- never stuck in the dark
end
fadeIn = function()
	trip += 1
	TweenService:Create(name, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
	local tw = TweenService:Create(dark, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1})
	tw:Play()
	tw.Completed:Once(function() if dark.BackgroundTransparency >= 0.99 then dark.Visible = false end end)
end
ev.OnClientEvent:Connect(function(what, arg)
	if what == "fade" then fadeOut(arg)
	elseif what == "arrived" then task.delay(0.5, fadeIn)
	elseif what == "note" then note(arg, 5) end
end)
-- the travel carts stand for everyone; their hold prompt shows for this player only once Porto Nocciola is opened
-- (prompts stream in and out with their parts, so apply on every arrival)
local function opened() return (tonumber(p:GetAttribute("Item_porto")) or 0) >= 1 end
local function apply(d)
	if d:IsA("ProximityPrompt") then d.Enabled = opened() end
end
local function applyAll() for _, d in ipairs(F:GetDescendants()) do apply(d) end end
F.DescendantAdded:Connect(function(d) task.defer(apply, d) end)
p:GetAttributeChangedSignal("Item_porto"):Connect(applyAll)
applyAll()
