-- StatsClient (workspace.Funnel, RunContext Client; funnel2, Oct 22 2026): once per area per visit, after 20 s in it, this
-- screen's frame rate (averaged over 10 s) and memory (MB) go to SquirrelStats as AreaFPS / AreaMemory - is the busy Rue
-- lagging or crashing tablets and phones? Nothing drawn. Paused while the game window is in the background (the frame rate
-- would be meaningless).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local player = Players.LocalPlayer
local ev = script.Parent:WaitForChild("StatsEvent", 60)
if not ev then return end
local AREAS = {forest = true, village = true, domaine = true, porto = true}
local sent, focused = {}, true
UIS.WindowFocused:Connect(function() focused = true end)
UIS.WindowFocusReleased:Connect(function() focused = false end)
local function measure(area)
	task.wait(20)                                                       -- (settled in, the area loaded around them)
	if player:GetAttribute("Area") ~= area or sent[area] then return end
	local frames, t0 = 0, os.clock()
	local conn = RunService.RenderStepped:Connect(function() frames += 1 end)
	task.wait(10)
	conn:Disconnect()
	local secs = os.clock() - t0
	if not focused or player:GetAttribute("Area") ~= area or sent[area] or secs <= 0 then return end
	sent[area] = true
	local ok, mem = pcall(function() return Stats:GetTotalMemoryUsageMb() end)
	ev:FireServer("perf", area, frames / secs, ok and mem or nil)
end
local function check()
	local a = player:GetAttribute("Area")
	if AREAS[a] and not sent[a] then task.spawn(measure, a) end
end
player:GetAttributeChangedSignal("Area"):Connect(check)
check()
