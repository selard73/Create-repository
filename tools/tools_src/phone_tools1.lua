-- tools_src/phone_tools1 (job 71): EDIT mode. The slingshot and the binoculars on a phone (touch mode by PreferredInput,
-- switching when a finger arrives; the HOLD button at the bottom middle), the acorn goes where you look away from every
-- hoop (Porto) and the note says so; the Daily card and the Daily Question pick their phone layout the same way.
-- Four exact-string patches (the job 70 exports), each compiled before writing; originals ->
-- ServerStorage.HudBackup.<Name>_pre_phone1. workspace.Hoop gets HoopRange 150. Output lines "QQ PHONE".
if game:GetService("RunService"):IsRunning() then warn("QQ PHONE ABORT - Play mode") return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local JOBS = {
	{name = "SlingClient", get = function() return game:GetService("ServerStorage"):FindFirstChild("SlingshotTool") and game:GetService("ServerStorage").SlingshotTool:FindFirstChild("SlingClient") end, n = 16373, backup = "SlingClient_pre_phone1", pairs = {{[===[
local touchAim = (UIS.TouchEnabled and not UIS.MouseEnabled) or workspace.Hoop:GetAttribute("ForceTouch") == true   -- a phone: hold a button, the shot aims itself; a mouse aims with the cursor
if touchAim then tool.ManualActivationOnly = true end          -- so a tap on the screen (or a camera drag) is not a shot
]===], [===[
local function touchNow()   -- a phone? PreferredInput knows (MouseEnabled can read true on a touch phone - Shannon, Oct 10: no HOLD button, binoculars dead)
	local ok, pi = pcall(function() return UIS.PreferredInput end)
	if ok and pi ~= nil then return pi == Enum.PreferredInput.Touch end
	return UIS.TouchEnabled and not UIS.MouseEnabled
end
local touchAim = touchNow() or workspace.Hoop:GetAttribute("ForceTouch") == true   -- a phone: hold a button, the shot aims itself; a mouse aims with the cursor
if touchAim then tool.ManualActivationOnly = true end          -- so a tap on the screen (or a camera drag) is not a shot
]===]}, {[===[
local hold = Instance.new("TextButton"); hold.Name = "Shoot"; hold.AnchorPoint = Vector2.new(1, 1); hold.Position = UDim2.new(1, -26, 1, -150)
hold.Size = UDim2.fromOffset(150, 150); hold.BackgroundColor3 = C(255, 202, 62); hold.BackgroundTransparency = 0.08; hold.BorderSizePixel = 0
]===], [===[
local hold = Instance.new("TextButton"); hold.Name = "Shoot"; hold.AnchorPoint = Vector2.new(0.5, 1); hold.Position = UDim2.new(0.5, 0, 1, -34)   -- bottom middle: clear of Roblox's capture bar, the jump button and the thumbstick (Oct 10)
hold.Size = UDim2.fromOffset(130, 130); hold.BackgroundColor3 = C(255, 202, 62); hold.BackgroundTransparency = 0.08; hold.BorderSizePixel = 0
]===]}, {[===[
		say(touchAim and "Hold the big button to draw - longer goes further - let go to shoot. It flies at the nearest hoop."
			or "Put the cursor on the hoop. Hold to draw - longer goes further - let go to shoot.", false, 4.5)
	end
end
]===], [===[
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root or nearestHoopDist(root.Position) > (workspace.Hoop:GetAttribute("HoopRange") or 150) then
			-- away from every hoop (Porto): the acorn simply goes where you look (Shannon, Oct 10: the hoop note "does not apply in the Italy map")
			say(touchAim and "Hold the big button to draw - longer goes further - let go and the acorn flies where you are looking."
				or "Hold to draw - longer goes further - let go to shoot where the cursor points.", false, 4.5)
		else
			say(touchAim and "Hold the big button to draw - longer goes further - let go to shoot. It flies at the nearest hoop."
				or "Put the cursor on the hoop. Hold to draw - longer goes further - let go to shoot.", false, 4.5)
		end
	end
end
]===]}, {[===[
		dir = (best and best.Magnitude > 0.1) and best.Unit or workspace.CurrentCamera.CFrame.LookVector
]===], [===[
		if best and best.Magnitude > 0.1 and bestD <= (workspace.Hoop:GetAttribute("HoopRange") or 150) then dir = best.Unit
		else
			-- away from every hoop (Porto): where you are looking - at the spot in the middle of the screen when there is one within reach, else a lob that way (Oct 10)
			local cam = workspace.CurrentCamera
			dir = cam.CFrame.LookVector
			if not kind then
				local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
				local skip = {player.Character}
				local dl = workspace:FindFirstChild("SlingDraw_local"); if dl then table.insert(skip, dl) end
				rp.FilterDescendantsInstances = skip
				local hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 120, rp)
				if hit then kind, point = "point", hit.Position end
			end
		end
]===]}, {[===[
UIS.InputEnded:Connect(function(io)                              -- a finger that slid off the button still lets go
	if charging and touchAim and io.UserInputType == Enum.UserInputType.Touch then hold.BackgroundColor3 = C(255, 202, 62); endDraw() end
end)
]===], [===[
UIS.InputEnded:Connect(function(io)                              -- a finger that slid off the button still lets go
	if charging and touchAim and io.UserInputType == Enum.UserInputType.Touch then hold.BackgroundColor3 = C(255, 202, 62); endDraw() end
end)
UIS.LastInputTypeChanged:Connect(function(t)                     -- a finger arriving later: the phone way from then on (Oct 10)
	if t == Enum.UserInputType.Touch and not touchAim and not charging then
		touchAim = true; tool.ManualActivationOnly = true; hold.Visible = true
		if gui.Enabled then helpLine() end
	end
end)
]===]}}},
	{name = "BinocularsClient", get = function() return game:GetService("ServerStorage"):FindFirstChild("BinocularsTool") and game:GetService("ServerStorage").BinocularsTool:FindFirstChild("BinocularsClient") end, n = 7981, backup = "BinocularsClient_pre_phone1", pairs = {{[===[
local touch = UIS.TouchEnabled and not UIS.MouseEnabled       -- a phone toggles; a mouse holds
]===], [===[
local function touchNow()   -- a phone? PreferredInput knows (MouseEnabled can read true on a touch phone - Shannon, Oct 10: no HOLD button, binoculars dead)
	local ok, pi = pcall(function() return UIS.PreferredInput end)
	if ok and pi ~= nil then return pi == Enum.PreferredInput.Touch end
	return UIS.TouchEnabled and not UIS.MouseEnabled
end
local touch = touchNow()       -- a phone toggles; a mouse holds
UIS.LastInputTypeChanged:Connect(function(t)   -- and it follows the last thing used: a finger means toggle, a mouse means hold (Oct 10)
	if t == Enum.UserInputType.Touch then touch = true elseif t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.MouseMovement then touch = touchNow() end
end)
]===]}}},
	{name = "DailyClient", get = function() return workspace:FindFirstChild("Daily") and workspace.Daily:FindFirstChild("DailyClient") end, n = 14785, backup = "DailyClient_pre_phone1", pairs = {{[===[
local phone = UIS.TouchEnabled and not UIS.MouseEnabled
]===], [===[
local phone = (function() local ok, pi = pcall(function() return UIS.PreferredInput end); if ok and pi ~= nil then return pi == Enum.PreferredInput.Touch end; return UIS.TouchEnabled and not UIS.MouseEnabled end)()   -- (PreferredInput: MouseEnabled can read true on a touch phone - Oct 10)
]===]}}},
	{name = "QuestionClient", get = function() return workspace:FindFirstChild("DailyQuestion") and workspace.DailyQuestion:FindFirstChild("QuestionClient") end, n = 28363, backup = "QuestionClient_pre_phone1", pairs = {{[===[
local PHONE = UIS.TouchEnabled and not UIS.MouseEnabled
]===], [===[
local PHONE = (function() local ok, pi = pcall(function() return UIS.PreferredInput end); if ok and pi ~= nil then return pi == Enum.PreferredInput.Touch end; return UIS.TouchEnabled and not UIS.MouseEnabled end)()   -- (PreferredInput: MouseEnabled can read true on a touch phone - Oct 10)
]===]}}},
}
-- everything is checked before anything is written
local plan = {}
for _, j in ipairs(JOBS) do
	local s = j.get()
	if not (s and s:IsA("LuaSourceContainer")) then warn("QQ PHONE ABORT - " .. j.name .. " not found; nothing changed") return end
	if #s.Source ~= j.n then warn(string.format("QQ PHONE ABORT - %s is %d chars, expected %d (not the job 70 export, or already patched); nothing changed", j.name, #s.Source, j.n)) return end
	local o = s.Source
	for i, p in ipairs(j.pairs) do
		local a, b = o:find(p[1], 1, true)
		if not a then warn("QQ PHONE ABORT - " .. j.name .. " find " .. i .. " not found; nothing changed") return end
		if o:find(p[1], b + 1, true) then warn("QQ PHONE ABORT - " .. j.name .. " find " .. i .. " matches more than once; nothing changed") return end
		o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
	end
	local f, err = loadstring(o)
	if not f then warn("QQ PHONE ABORT - patched " .. j.name .. " does not compile: " .. tostring(err) .. "; nothing changed") return end
	table.insert(plan, {script = s, text = o, job = j})
end
local report = {}
for _, p in ipairs(plan) do
	local old = backup:FindFirstChild(p.job.backup); if old then old:Destroy() end
	local c = p.script:Clone(); c.Name = p.job.backup; c.Enabled = false; c.Parent = backup
	p.script.Source = p.text
	table.insert(report, string.format("%s %d -> %d", p.job.name, p.job.n, #p.script.Source))
end
local H = workspace:FindFirstChild("Hoop"); if H then H:SetAttribute("HoopRange", 150) end
game:GetService("ChangeHistoryService"):SetWaypoint("Phone tools patched")
print("QQ PHONE DONE: " .. table.concat(report, "; ") .. "; backups ServerStorage.HudBackup.*_pre_phone1; Hoop.HoopRange 150")
