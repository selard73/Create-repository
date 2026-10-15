-- HallClient: this player's own view of the Hall of Fame - the newest Keeper first, older and newer with the buttons
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local F = script.Parent
local CH = workspace:WaitForChild("Champion")
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
local function dateOf(day) return os.date("!%B %d, %Y", (tonumber(day) or 0) * 86400 + 12 * 3600) end
local function list()
	local ok, t = pcall(function() return HttpService:JSONDecode(CH:GetAttribute("HallJson") or "[]") end)
	return (ok and type(t) == "table") and t or {}
end
local view = Instance.new("Folder"); view.Name = "HallView_local"; view.Parent = workspace
local keepers, idx, shownNo = {}, 0, nil
local want = 0                                                       -- the newest request (older ones are dropped)
local function words()
	local stand = F:FindFirstChild("PlaqueStand")
	local plaque = stand and stand:FindFirstChild("Plaque")
	return plaque and plaque:FindFirstChild("Words")
end
local function setPlaque()
	local w = words()
	if not w then return end
	local e = keepers[idx]
	if e then
		w.Title.Text = "THE " .. ordinal(e.no):upper() .. " GRAND KEEPER"
		w.Sub.Text = "OF THE GREAT ACORN"
		w.Who.Text = tostring(e.name or "?")
		w.When.Text = "First to find all " .. tostring(e.total or 44) .. " squirrels on " .. dateOf(e.day)
		w.Count.Text = string.format("%d of %d", idx, #keepers)
	else
		w.Title.Text = "THE GRAND KEEPERS"
		w.Sub.Text = "OF THE GREAT ACORN"
		w.Who.Text = "No Keeper yet"
		w.When.Text = "Be the first to find every squirrel in a day - your statue will stand here"
		w.Count.Text = ""
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
		local src = ok and name and store:WaitForChild(name, 15)
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
	if atNewest or idx > #keepers or idx == 0 then idx = #keepers end   -- a new Keeper: the hall moves on to them
	show()
end
task.spawn(hookButtons)
CH:GetAttributeChangedSignal("HallJson"):Connect(reload)
F.DescendantAdded:Connect(function(d) if d.Name == "Words" then task.defer(setPlaque) elseif d.Name == "Button" then task.defer(setButtons) end end)
reload()
