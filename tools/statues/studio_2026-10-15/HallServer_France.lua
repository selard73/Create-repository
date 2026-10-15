-- HallServer: the statues for the Hall of Fame - made once each (the ChampionServer's own MakeStatue, out of sight well
-- below the hall), kept in ReplicatedStorage.HallStatues, handed to whoever asks; the saluting squirrel, once; the
-- waiting acorn while there is no Keeper yet
local RS = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local F = script.Parent
local CH = workspace:WaitForChild("Champion")
local makeStatue = CH:WaitForChild("MakeStatue")
local makeSquirrel = CH:WaitForChild("MakeSquirrel")
local fn = F:WaitForChild("HallStatue")
local store = RS:FindFirstChild("HallStatues")
if not store then store = Instance.new("Folder"); store.Name = "HallStatues"; store.Parent = RS end
for _, o in ipairs(store:GetChildren()) do o:Destroy() end
local SPOT, SQ, LOOK = F:GetAttribute("FigureSpot"), F:GetAttribute("SquirrelSpot"), F:GetAttribute("Look")
local DROP = 300                                                     -- made this far below the hall, out of sight
local function list()
	local ok, t = pcall(function() return HttpService:JSONDecode(CH:GetAttribute("HallJson") or "[]") end)
	return (ok and type(t) == "table") and t or {}
end
local function entry(no) for _, e in ipairs(list()) do if e.no == no then return e end end return nil end
-- on its feet: the lowest corner of the visible feet (never the invisible root - Shannon's baby avatar floated)
local function feetLow(m)
	local low = math.huge
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and (d.Name == "LeftFoot" or d.Name == "RightFoot") and d.Transparency < 0.95 then
			local h = d.Size / 2
			for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
				low = math.min(low, (d.CFrame * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)).Y)
			end end end
		end
	end
	if low == math.huge then local cf, s = m:GetBoundingBox(); low = cf.Y - s.Y / 2 end
	return low
end
local function visibleTop(m)
	local top = -math.huge
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency < 0.95 then
			local h = d.Size / 2
			for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
				top = math.max(top, (d.CFrame * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)).Y)
			end end end
		end
	end
	return top
end
local cache, used, busy, building = {}, {}, {}, false
local function build(no)
	if cache[no] and cache[no].Parent then used[no] = os.clock(); return cache[no] end
	while busy[no] do task.wait(0.2) end
	if cache[no] and cache[no].Parent then return cache[no] end
	local e = entry(no)
	if not e then return nil end
	busy[no] = true
	while building do task.wait(0.2) end
	building = true
	local stage = F:FindFirstChild("Staging")
	if not stage then stage = Instance.new("Folder"); stage.Name = "Staging"; stage.Parent = F end
	local low = Vector3.new(SPOT.X, SPOT.Y - DROP, SPOT.Z)
	local ok, fig, acorn = pcall(function()
		return makeStatue:Invoke({uid = e.uid, name = e.name, no = e.no, day = e.day}, {x = low.X, top = low.Y, z = low.Z, parent = stage, name = "Figure", scale = F:GetAttribute("Scale") or 1.25, look = LOOK})
	end)
	local m
	if ok and fig then
		m = Instance.new("Model"); m.Name = "No_" .. tostring(no)
		fig.Parent = m
		if acorn then acorn.Parent = m end
		m.WorldPivot = (m:GetBoundingBox())                              -- (a new Model's pivot is the world origin)
		-- never taller than the frame: the whole statue, acorn and all, scaled down if its top would touch the gilding
		local maxH = F:GetAttribute("MaxHeight") or 9.2
		local h = visibleTop(m) - feetLow(m)
		if h > maxH then pcall(function() m:ScaleTo(m:GetScale() * maxH / h) end) end
		-- back on its feet in the middle of its spot, then up into the frame
		local cf = m:GetBoundingBox()
		m:PivotTo(m:GetPivot() + Vector3.new(low.X - cf.X, low.Y - feetLow(m), low.Z - cf.Z) + Vector3.new(0, DROP, 0))
		m.Parent = store
		cache[no] = m; used[no] = os.clock()
		-- keep the forty seen most recently
		local n = 0
		for _ in pairs(cache) do n += 1 end
		if n > 40 then
			local oldest, ot
			for k, t in pairs(used) do if cache[k] and (not ot or t < ot) then oldest, ot = k, t end end
			if oldest and oldest ~= no then cache[oldest]:Destroy(); cache[oldest] = nil; used[oldest] = nil end
		end
	else
		warn("HallServer: no statue for No. " .. tostring(no) .. ": " .. tostring(fig))
	end
	building = false
	busy[no] = nil
	return m
end
fn.OnServerInvoke = function(player, no)
	no = tonumber(no)
	if not no then return nil end
	local m = build(math.floor(no))
	return m and m.Name or nil
end
-- the squirrel, saluting, the same for everyone
task.spawn(function()
	if F:FindFirstChild("Squirrel") then return end
	pcall(function()
		makeSquirrel:Invoke({x = SQ.X, y = SQ.Y, z = SQ.Z, tx = SPOT.X, tz = SPOT.Z, parent = F, name = "Squirrel", scale = F:GetAttribute("SquirrelScale") or 1.2})
	end)
end)
-- the acorn that waits on the plinth while there is no Keeper; the newest statue made ahead of anyone asking
local function refresh()
	local l = list()
	local waiting = F:FindFirstChild("WaitingAcorn")
	if #l == 0 and not waiting then
		local tpl = ServerStorage:FindFirstChild("ChampionAcorn")
		if tpl then
			local a = tpl:Clone(); a.Name = "WaitingAcorn"
			local _, size = a:GetBoundingBox()
			if size.Y > 0 then pcall(function() a:ScaleTo(a:GetScale() * 2.2 / size.Y) end) end
			local cf, s2 = a:GetBoundingBox()
			a:PivotTo(a:GetPivot() + Vector3.new(SPOT.X - cf.X, SPOT.Y - (cf.Y - s2.Y / 2), SPOT.Z - cf.Z))
			a.Parent = F
		end
	elseif #l > 0 and waiting then
		waiting:Destroy()
	end
	if #l > 0 then task.spawn(build, l[#l].no) end
end
CH:GetAttributeChangedSignal("HallJson"):Connect(refresh)
refresh()
print("HallServer: ready - " .. #list() .. " Keepers in the hall")
