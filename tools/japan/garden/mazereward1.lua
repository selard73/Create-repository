-- mazereward1.lua (runner 7, Oct 17 2026): a once-a-day acorn reward at the bamboo maze's exit. Shannon: "Yes, add a once-a-day acorn
-- reward at the maze exit". Adds to the installed JapanMap.BambooMaze (bamboomaze1.lua):
--  * attribute RewardAcorns = 25 on BambooMaze (the game's dailies pay 10-40; the Daily question 25) - change it there
--  * MazeEvent (RemoteEvent) and MazeReward (server Script): every 0.3 s it looks where each player stands; a player who is in the
--    ENTRANCE cell is "on the way"; leaving the maze (out of its footprint, or above y 30) clears it; reaching the EXIT cell while on the
--    way finishes the maze. The first finish of the day pays RewardAcorns through RS.AwardAcorns and saves the day through RS.AwardItems
--    (Item_mazeday = the day number, set by a delta, as the garden does); later finishes that day pay nothing but still show the card.
--    The day is the Daily's: (os.time() - DayOffsetHours h) // 86400, DayOffsetHours from workspace.Daily (9). Every finish also counts
--    Item_maze_done +1. Walking round the outside to the exit pays nothing (never on the way).
--  * MazeFinishClient (client): the thank-you card's look and place (ThanksClient: navy, gold edge, FredokaOne, 320 x 168 at y 78 on
--    phones / 110 elsewhere, 0 overlaps measured on the phone Oct 13), waits for other panels like it, closes on its button.
-- Re-runnable (the three are rebuilt). Output "QQ MAZEREWARD1". Undo: delete MazeEvent, MazeReward, MazeFinishClient and the attribute.
local J = workspace:FindFirstChild("JapanMap")
local maze = J and J:FindFirstChild("BambooMaze")
if not maze then print("QQ MAZEREWARD1 ABORT: JapanMap.BambooMaze is not installed (bamboomaze1.lua first)") return end
local RS = game:GetService("ReplicatedStorage")
if not (RS:FindFirstChild("AwardAcorns") and RS:FindFirstChild("AwardItems")) then print("QQ MAZEREWARD1 ABORT: RS.AwardAcorns / RS.AwardItems missing") return end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before mazereward1") end)
for _, n in ipairs({"MazeEvent", "MazeReward", "MazeFinishClient"}) do local o = maze:FindFirstChild(n); if o then o:Destroy() end end
if maze:GetAttribute("RewardAcorns") == nil then maze:SetAttribute("RewardAcorns", 25) end
local ev = Instance.new("RemoteEvent"); ev.Name = "MazeEvent"; ev.Parent = maze
local server = Instance.new("Script"); server.Name = "MazeReward"; server.RunContext = Enum.RunContext.Server
server.Source = [==[
-- the bamboo maze's once-a-day reward (mazereward1.lua): on the way = seen in the entrance cell; out of the maze clears it; the exit
-- cell while on the way = a finish. First finish of the day: RewardAcorns via RS.AwardAcorns, the day saved as Item_mazeday (RS.AwardItems).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local maze = script.Parent
local ev = maze:WaitForChild("MazeEvent")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local awardItems = RS:WaitForChild("AwardItems")
local X0, ZN, P, COLS, ROWS = 5378.5, -271, 9, 10, 12
local ENTRY, EXIT = {3, 11}, {4, 0}
local onWay = {}
local function item(p, id) return tonumber(p:GetAttribute("Item_" .. id)) or 0 end
local function today()
	local d = workspace:FindFirstChild("Daily")
	local off = (d and tonumber(d:GetAttribute("DayOffsetHours"))) or 9
	return (os.time() - off * 3600) // 86400
end
local function finish(p)
	local day = today()
	local reward = tonumber(maze:GetAttribute("RewardAcorns")) or 25
	local paid = 0
	if item(p, "mazeday") ~= day then
		awardItems:Fire(p, "mazeday", day - item(p, "mazeday"))
		if reward > 0 then awardAcorns:Fire(p, reward); paid = reward end
	end
	awardItems:Fire(p, "maze_done", 1)
	ev:FireClient(p, {acorns = paid, done = item(p, "maze_done")})
	print(string.format("BambooMaze: %s found the way out (day %d)%s", p.Name, day, paid > 0 and (", paid " .. paid .. " acorns") or ", already paid today"))
end
Players.PlayerRemoving:Connect(function(p) onWay[p] = nil end)
while true do
	task.wait(0.3)
	for _, p in ipairs(Players:GetPlayers()) do
		local ch = p.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		if hrp then
			local pos = hrp.Position
			local c, r = math.floor((pos.X - X0) / P), math.floor((pos.Z - ZN) / P)
			local inside = c >= 0 and c < COLS and r >= 0 and r < ROWS and pos.Y < 30
			if not inside then onWay[p] = nil
			elseif c == ENTRY[1] and r == ENTRY[2] then onWay[p] = true
			elseif c == EXIT[1] and r == EXIT[2] and onWay[p] then onWay[p] = nil; task.spawn(finish, p) end
		end
	end
end
]==]
server.Parent = maze
local client = Instance.new("Script"); client.Name = "MazeFinishClient"; client.RunContext = Enum.RunContext.Client
client.Source = [==[
-- the bamboo maze's "you found your way out" card (mazereward1.lua) - the thank-you card's look and place; waits for other panels
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
if pg:FindFirstChild("MazeFinishGui") then return end            -- (a Client script can start twice in a play test)
local ev = script.Parent:WaitForChild("MazeEvent")
local C = Color3.fromRGB
local NAVY, GOLD, CREAM, DEEP = C(38, 30, 52), C(240, 200, 90), C(255, 246, 220), C(84, 48, 18)
local FONT = Enum.Font.FredokaOne
local phone = (function() local ok, pi = pcall(function() return UIS.PreferredInput end); if ok and pi ~= nil then return pi == Enum.PreferredInput.Touch end; return UIS.TouchEnabled and not UIS.MouseEnabled end)()
local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = o end
local gui = Instance.new("ScreenGui"); gui.Name = "MazeFinishGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 100; gui.Enabled = false; gui.Parent = pg
local W, H = 320, 168
local card = Instance.new("Frame"); card.AnchorPoint = Vector2.new(0.5, 0); card.Position = UDim2.new(0.5, 0, 0, phone and 78 or 110)
card.Size = UDim2.fromOffset(W, H); card.BackgroundColor3 = NAVY; card.BorderSizePixel = 0; card.Parent = gui; corner(card, 16)
local cs = Instance.new("UIStroke"); cs.Color = GOLD; cs.Thickness = 2; cs.Parent = card
local function text(t, size, colour, y, h)
	local l = Instance.new("TextLabel"); l.Position = UDim2.fromOffset(16, y); l.Size = UDim2.fromOffset(W - 32, h); l.BackgroundTransparency = 1
	l.Font = FONT; l.TextSize = size; l.TextColor3 = colour; l.Text = t; l.TextWrapped = true; l.Parent = card
	return l
end
local title = text("You found your way out!", 20, CREAM, 10, 26)
local note = text("", 14, GOLD, 38, 56)
local sum = text("", 15, CREAM, 94, 22)
local ok = Instance.new("TextButton"); ok.AnchorPoint = Vector2.new(0.5, 1); ok.Position = UDim2.new(0.5, 0, 1, -10); ok.Size = UDim2.fromOffset(150, 34)
ok.BackgroundColor3 = GOLD; ok.BorderSizePixel = 0; ok.Font = FONT; ok.TextSize = 17; ok.TextColor3 = DEEP; ok.Text = "Hooray!"; ok.Parent = card; corner(ok, 12)
local function close() gui.Enabled = false; if pg:GetAttribute("OpenPanel") == "maze" then pg:SetAttribute("OpenPanel", nil) end end
ok.Activated:Connect(close)
pg:GetAttributeChangedSignal("OpenPanel"):Connect(function() if gui.Enabled and pg:GetAttribute("OpenPanel") ~= "maze" then gui.Enabled = false end end)
ev.OnClientEvent:Connect(function(info)
	if type(info) ~= "table" then return end
	local paid = tonumber(info.acorns) or 0
	note.Text = "The bamboo grows a new maze every day. Come back tomorrow and find your way through again!"
	sum.Text = paid > 0 and string.format("+%d acorns are in your purse.", paid) or "You've had today's maze prize already."
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < 30 do
			local daily = pg:FindFirstChild("DailyGui"); local dcard = daily and daily:FindFirstChild("DailyCard")
			local dailyUp = daily ~= nil and daily.Enabled and dcard ~= nil and dcard.Visible
			if pg:GetAttribute("OpenPanel") == nil and not dailyUp then pg:SetAttribute("OpenPanel", "maze"); gui.Enabled = true; return end
			task.wait(1)
		end
	end)
end)
]==]
client.Parent = maze
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after mazereward1") end)
print(string.format("QQ MAZEREWARD1 DONE: BambooMaze.RewardAcorns %d (once a day, the Daily's day), MazeEvent + MazeReward (server) + MazeFinishClient (client card)", maze:GetAttribute("RewardAcorns")))
