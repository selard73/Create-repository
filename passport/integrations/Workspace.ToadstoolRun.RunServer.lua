local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local F = script.Parent
local T = workspace:WaitForChild("Trampolines")
local bounced = T:WaitForChild("Bounced")
local ev = F:WaitForChild("RunEvent")
local awardAcorns = RS:WaitForChild("AwardAcorns")

local runs = {}                                      -- player -> {last = order reached, t = time of the last bounce}
local hinted = {}                                    -- player -> when they were last told where the run starts

local function total() return T:GetAttribute("VineyardHops") or 0 end
local function ends()
	if F:GetAttribute("Start") == "bottom" then return total(), 1 end
	return 1, total()
end
local function stop(player, why)
	if not runs[player] then return end
	runs[player] = nil
	player:SetAttribute("ToadRun", nil)
	if why then ev:FireClient(player, why) end
end

bounced.OnServerEvent:Connect(function(player, model)
	if typeof(model) ~= "Instance" or not model:IsA("Model") or model.Parent ~= T or model:GetAttribute("Line") ~= "vineyard" then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local at = model:GetPivot().Position
	if Vector3.new(hrp.Position.X - at.X, 0, hrp.Position.Z - at.Z).Magnitude > 2.8 * (model:GetAttribute("Scale") or 1.3) + 6 then return end
	local o, now = model:GetAttribute("Order"), os.clock()
	local s, f = ends()
	local dir = (f > s) and 1 or -1
	local r = runs[player]
	if r and now - r.t > (F:GetAttribute("MaxGap") or 2.4) then stop(player, "fell"); r = nil end   -- that long without a bounce: they came down somewhere
	if o == s then
		if r then r.t = now; if r.last ~= s then r.last = s; player:SetAttribute("ToadRun", 1) end return end
		runs[player] = {last = s, t = now}
		player:SetAttribute("ToadRun", 1)
		ev:FireClient(player, "start", total())
		return
	end
	if not r then
		if o == f and (not hinted[player] or now - hinted[player] > 20) then hinted[player] = now; ev:FireClient(player, "startshere") end
		return
	end
	r.t = now
	if (o - r.last) * dir > 0 then r.last = o; player:SetAttribute("ToadRun", math.abs(o - s) + 1) end
	if o == f then
		runs[player] = nil
		player:SetAttribute("ToadRun", nil)
		hinted[player] = now                                               -- you go on bouncing on the finish cap: no "it starts up by the chapel" over the cheering
		local n = F:GetAttribute("Reward") or 10
		awardAcorns:Fire(player, n)                                       -- SquirrelSetup's ledger saves it
		player:SetAttribute("Acorns", (tonumber(player:GetAttribute("Acorns")) or 0) + n)
		local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(player,"toadstool",{prize=n}) end
		ev:FireClient(player, "done", n)
	end
end)
ev.OnServerEvent:Connect(function(player, what)
	if what == "fell" then stop(player, "fell") end
end)
-- a run that has gone quiet ended on the ground, whether or not the player's screen said so
task.spawn(function()
	while true do
		task.wait(0.25)
		local now, gap = os.clock(), F:GetAttribute("MaxGap") or 2.4
		for player, r in pairs(runs) do if now - r.t > gap then stop(player, "fell") end end
	end
end)
Players.PlayerRemoving:Connect(function(p) runs[p] = nil; hinted[p] = nil end)
