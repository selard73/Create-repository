local Players = game:GetService("Players")
local PPS = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local F = script.Parent
local ev = F:WaitForChild("ChapelEvent")
local room = F:WaitForChild("Room")
local function v3(prefix) return Vector3.new(F:GetAttribute(prefix .. "X"), F:GetAttribute(prefix .. "Y"), F:GetAttribute(prefix .. "Z")) end

-- inside, the camera cannot be scrolled out through the walls: a short zoom leash, given back at the door (or on respawn)
local savedZoom = {}
local function leash(player, on)
	if on then
		if savedZoom[player] == nil then savedZoom[player] = player.CameraMaxZoomDistance end
		player.CameraMaxZoomDistance = F:GetAttribute("InsideZoom") or 18
	elseif savedZoom[player] ~= nil then
		player.CameraMaxZoomDistance = savedZoom[player]; savedZoom[player] = nil
	end
end
local function watch(player) player.CharacterAdded:Connect(function() leash(player, false) end) end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(p) savedZoom[p] = nil end)

-- the doors: fade, move, unfade (the client draws the fade; the server moves the character while it is dark)
local moving = {}
local function through(player, toInside)
	if moving[player] then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp then return end
	moving[player] = true
	local fade = F:GetAttribute("FadeSeconds") or 0.45
	ev:FireClient(player, "fade", fade, toInside)
	task.delay(fade + 0.05, function()
		if char.Parent and hrp.Parent then
			if hum and hum.SeatPart then hum.Sit = false end
			local p = toInside and v3("In") or v3("Out")
			local look = toInside and Vector3.new(F:GetAttribute("InLookX"), 0, F:GetAttribute("InLookZ")) or Vector3.new(F:GetAttribute("OutLookX"), 0, F:GetAttribute("OutLookZ"))
			char:PivotTo(CFrame.lookAt(p, p + look))
			char:SetAttribute("InChapel", toInside or nil)
			leash(player, toInside)
		end
		task.wait(0.15)
		ev:FireClient(player, "unfade", fade)
		moving[player] = nil
	end)
end

-- the votive candles: each prompt lights the next dark one, for everyone, for CandleSeconds
local votive = room:WaitForChild("Votive")
local flames = {}
for _, d in ipairs(votive:GetChildren()) do if d.Name:match("^VotiveFlame") then flames[#flames + 1] = d end end
table.sort(flames, function(a, b) return tonumber(a.Name:match("%d+")) < tonumber(b.Name:match("%d+")) end)
local litUntil = {}
local function setLit(fl, on)
	fl.Transparency = on and 0 or 1
	local l = fl:FindFirstChildOfClass("PointLight"); if l then l.Enabled = on end
end
local function lightOne(player)
	local now = os.clock()
	local pick
	for _, fl in ipairs(flames) do if (litUntil[fl] or 0) < now then pick = fl break end end
	if not pick then                                                   -- all lit: the one that has burned longest is renewed
		for _, fl in ipairs(flames) do if not pick or litUntil[fl] < litUntil[pick] then pick = fl end end
	end
	local secs = F:GetAttribute("CandleSeconds") or 120
	litUntil[pick] = now + secs
	setLit(pick, true)
	ev:FireClient(player, "candle")
	task.delay(secs + 0.1, function() if (litUntil[pick] or 0) <= os.clock() then setLit(pick, false) end end)
end

-- the bell: out of the belfry for everyone near the chapel, and in here; the rope gives
local bellAt = 0
local rope = room:WaitForChild("BellRope")
local function ring(player)
	if os.clock() - bellAt < 4 then return end
	bellAt = os.clock()
	local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(player,"church",{}) end
	local id, vol = F:GetAttribute("BellSound") or "rbxassetid://9113804436", F:GetAttribute("BellVolume") or 0.8
	for _, where in ipairs({F:FindFirstChild("BellVoice"), rope:FindFirstChild("Hole")}) do
		if where then
			local s = Instance.new("Sound"); s.SoundId = id; s.Volume = vol; s.RollOffMaxDistance = where.Name == "BellVoice" and 260 or 80
			s.RollOffMinDistance = 12; s.Parent = where; s:Play()
			game:GetService("Debris"):AddItem(s, 12)
		end
	end
	-- the rope and its sally go down a stud and a half and come back
	local parts = {}
	for _, p in ipairs(rope:GetChildren()) do if p:IsA("BasePart") and p.Name ~= "Hole" and p.Name ~= "RopePad" then parts[#parts + 1] = p end end
	for _, p in ipairs(parts) do
		local home = p:GetAttribute("Home") or p.CFrame
		p:SetAttribute("Home", home)
		local tw = TweenService:Create(p, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {CFrame = home * CFrame.new(0, -1.5, 0)})
		tw:Play()
	end
end

PPS.PromptTriggered:Connect(function(prompt, player)
	if not prompt:IsDescendantOf(F) then return end
	if prompt.Name == "EnterPrompt" then through(player, true)
	elseif prompt.Name == "ExitPrompt" then through(player, false)
	elseif prompt.Name == "CandlePrompt" then lightOne(player)
	elseif prompt.Name == "BellPrompt" then ring(player)
	end
end)
print("ChapelServer: ready")
