return function(d)
local task,os,F,Instance,game,TweenService,TweenInfo,workspace,Vector3,Vector2=d.task,d.os,d.F,d.Instance,d.game,d.TweenService,d.TweenInfo,d.workspace,d.Vector3,d.Vector2
local rocket=d.rocket
local SITES = {{240,-580,-48.625},{360,-600,-44.0234},{490,-640,-0.8497},
    {250,-800,-52.9219},{370,-810,-40.2748},{490,-840,16.5684},
    {250,-1010,-52.9219},{365,-1070,-52.9219},{490,-1130,1.4023}}
local showing = false
local function fireworks(secs)
	if showing then return end
	showing = true
	local id = "rbxassetid://9114447178" -- same show audio as France; visuals do not depend on audio
	if id and id ~= "" then
		local s = Instance.new("Sound"); s.Name = "ItalyFireworkShow"; s.SoundId = id; s.Looped = true; s.Volume = F:GetAttribute("FireworkVolume") or 0.6
		s.Parent = game:GetService("SoundService"); pcall(function() s:Play() end)
		task.delay(secs + 1, function()
			local t = TweenService:Create(s, TweenInfo.new(2), {Volume = 0}); t:Play()
			t.Completed:Connect(function() s:Destroy() end)
		end)
	end
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < secs do
			-- most of the show goes up over whichever map this screen is looking at; now and then one over a far map
			local cam = workspace.CurrentCamera
			local here = cam and cam.CFrame.Position or Vector3.zero
			local order = {}
			for k, st in ipairs(SITES) do order[k] = {s = st, d = (Vector2.new(st[1], st[2]) - Vector2.new(here.X, here.Z)).Magnitude} end
			table.sort(order, function(a, b) return a.d < b.d end)
			for k, chance in ipairs({1, 0.8, 0.55}) do
				if math.random() < chance then local st = order[k].s; rocket(st[1], st[2], st[3]) end
			end
			if math.random() < 0.25 then local st = order[math.random(4, #order)].s; rocket(st[1], st[2], st[3]) end
			task.wait(0.35 + math.random() * 0.2)
		end
		showing = false
	end)
end



return fireworks
end
