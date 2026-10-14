-- HallClient (workspace.HallOfGuardians, RunContext Client): this player's own view of the Belvedere dei Guardiani - the newest
-- Guardian of the Harbour first, Older and Newer with the two buttons, the pedestal's plaque with name, date and count (the
-- French hall's mechanism in the Italian style). The statue shown is a copy, on this screen only, of the one HallServer made.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local _player = Players.LocalPlayer
local F = script.Parent
local fn = F:WaitForChild("HallStatue")
local store = RS:WaitForChild("HallStatues")
local function ordinal(n)
	n = math.floor(tonumber(n) or 0)
	local m100, m10, s = n % 100, n % 10, "th"
	if m100 < 11 or m100 > 13 then
		if m10 == 1 then s = "st" elseif m10 == 2 then s = "nd" elseif m10 == 3 then s = "rd" end
	end
	return tostring(n) .. s
end
local function dateOf(e)                                               -- the lighthouse plaque's own rule: the day's noon, else the moment
	local t = tonumber(e.day) and (tonumber(e.day) * 86400 + 43200) or tonumber(e.t)
	return t and os.date("!%b %d, %Y", t) or ""
end
local function list()
	local ok, t = pcall(function() return HttpService:JSONDecode(F:GetAttribute("HallJson") or "[]") end)
	return (ok and type(t) == "table") and t or {}
end
local function total() local K = workspace:FindFirstChild("PortoKeeper"); return (K and tonumber(K:GetAttribute("Need"))) or tonumber(F:GetAttribute("Total")) or 44 end
local view = workspace:FindFirstChild("HallView_local")                 -- (one folder, reused if this script ran before)
if not view then view = Instance.new("Folder"); view.Name = "HallView_local"; view.Parent = workspace end
view:ClearAllChildren()
local keepers, idx, shownNo = {}, 0, nil
local want = 0                                                         -- the newest request (older ones are dropped)
local function words()
	local ped = F:FindFirstChild("Pedestal")
	local tile = ped and ped:FindFirstChild("Tile")
	return tile and tile:FindFirstChild("Words")
end
local function setPlaque()
	local w = words()
	if not w then return end
	local e = keepers[idx]
	if e then
		w.Title.Text = ordinal(e.no):upper() .. " GUARDIAN"
		w.Who.Text = tostring(e.name or "?")
		w.When.Text = "All " .. tostring(e.total or total()) .. " squirrels, " .. dateOf(e) .. "  \u{B7}  " .. tostring(idx) .. " of " .. tostring(#keepers)
	else
		w.Title.Text = "THIS COULD BE YOU"
		w.Who.Text = "Guardian No. 1"
		w.When.Text = "Find all " .. tostring(total()) .. " squirrels of Porto Nocciola"
	end
end
local function setButtons()
	for _, b in ipairs({{name = "Older", on = idx > 1}, {name = "Newer", on = idx < #keepers}}) do
		local m = F:FindFirstChild(b.name)
		local disc = m and m:FindFirstChild("Button")
		if disc then disc.Transparency = b.on and 0 or 0.55 end
	end
end
local function show()
	setPlaque(); setButtons()
	local e = keepers[idx]
	if not e then
		view:ClearAllChildren(); shownNo = nil
		return
	end
	if shownNo == e.no and #view:GetChildren() > 0 then return end
	want += 1
	local mine = want
	task.spawn(function()
		local ok, name = pcall(function() return fn:InvokeServer(e.no) end)
		if mine ~= want then return end                                  -- (scrolled on while it was being made)
		local src = ok and name and store:WaitForChild(name, 20)
		if mine ~= want then return end
		view:ClearAllChildren()
		if src then
			local c = src:Clone()
			c.Parent = view
			shownNo = e.no
		end
	end)
end
local function step(d)
	local n = math.clamp(idx + d, math.min(1, #keepers), #keepers)
	if n ~= idx then idx = n; show() end
end
local function hookButtons()
	for _, b in ipairs({{name = "Older", d = -1}, {name = "Newer", d = 1}}) do
		local m = F:WaitForChild(b.name)
		local function hook(p)
			local cd = p:IsA("BasePart") and p:FindFirstChildOfClass("ClickDetector")
			if cd and not cd:GetAttribute("Hooked") then
				cd:SetAttribute("Hooked", true)
				cd.MouseClick:Connect(function() step(b.d) end)
			end
		end
		for _, p in ipairs(m:GetChildren()) do hook(p) end
		m.ChildAdded:Connect(function(p) task.defer(hook, p) end)          -- (streamed in later)
	end
end
local function reload()
	local atNewest = (idx == #keepers)
	keepers = list()
	if atNewest or idx > #keepers or idx == 0 then idx = #keepers end   -- a new Guardian: the belvedere moves on to them
	show()
end
task.spawn(hookButtons)
F:GetAttributeChangedSignal("HallJson"):Connect(reload)
F:GetAttributeChangedSignal("Rebuild"):Connect(function() shownNo = nil; view:ClearAllChildren(); task.delay(1, show) end)   -- (a rebuild on the server: fetch the statue again)
F.DescendantAdded:Connect(function(d) if d.Name == "Words" then task.defer(setPlaque) elseif d.Name == "Button" then task.defer(setButtons) end end)
reload()
