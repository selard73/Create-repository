-- DomaineLife (server): the two prompts. It only records what happened as attributes; every client animates from them.
local domaine = script.Parent
local props = domaine:WaitForChild("Props")

local bin = props:FindFirstChild("FeedBin")
local binPrompt = bin and bin:FindFirstChildOfClass("ProximityPrompt")
if binPrompt then
	binPrompt.Triggered:Connect(function(player)
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		domaine:SetAttribute("FeedBy", player.UserId)
		domaine:SetAttribute("FeedAt", hrp.Position - Vector3.new(0, 2.6, 0) + hrp.CFrame.LookVector * 2.5)
		domaine:SetAttribute("FeedUntil", workspace:GetServerTimeNow() + 30)
	end)
end

for _, m in ipairs(props:GetChildren()) do
	if m.Name == "trough" then
		local handle = m:FindFirstChild("Handle")
		local prompt = handle and handle:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			local busyUntil = 0
			prompt.Triggered:Connect(function()
				local now = workspace:GetServerTimeNow()
				if now < busyUntil then return end
				busyUntil = now + 3
				m:SetAttribute("PumpAt", now)
			end)
		end
	end
end
