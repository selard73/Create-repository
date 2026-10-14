-- FunnelClient (workspace.Funnel, RunContext Client): two things the server cannot see, sent once each per visit through
-- FunnelEvent: which kind of device this is (Phone / Tablet / Desktop / Console / VR - the Device breakdown of the onboarding
-- funnel) and the first time the map opens (PlayerGui attribute OpenPanel = "map", the HUD's own convention). Nothing drawn.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local VRService = game:GetService("VRService")
local player = Players.LocalPlayer
local F = script.Parent
local ev = F:WaitForChild("FunnelEvent")
local pg = player:WaitForChild("PlayerGui")
local function touch()
	local ok, pi = pcall(function() return UIS.PreferredInput end)
	if ok and pi ~= nil then return pi == Enum.PreferredInput.Touch end
	return UIS.TouchEnabled and not UIS.MouseEnabled
end
local function device()
	if VRService.VREnabled then return "VR" end
	if GuiService:IsTenFootInterface() then return "Console" end
	if touch() then
		local cam = workspace.CurrentCamera
		local v = cam and cam.ViewportSize or Vector2.new(0, 0)
		return (math.min(v.X, v.Y) >= 600) and "Tablet" or "Phone"     -- (a phone sideways is about 667 x 375; tablets run 768 and up)
	end
	return "Desktop"
end
task.spawn(function()
	local t0 = os.clock()                                               -- the viewport is tiny before the first frame: wait for a real size (5 s at most)
	while os.clock() - t0 < 5 do
		local cam = workspace.CurrentCamera
		local v = cam and cam.ViewportSize
		if v and math.min(v.X, v.Y) > 1 then break end
		task.wait(0.1)
	end
	ev:FireServer("device", device())
end)
local sent = false
local function look()
	if not sent and pg:GetAttribute("OpenPanel") == "map" then sent = true; ev:FireServer("map") end
end
pg:GetAttributeChangedSignal("OpenPanel"):Connect(look)
look()
