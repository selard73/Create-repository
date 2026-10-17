-- bamboomaze1.lua (runner 7, Oct 17 2026): the bamboo maze at the far end of the tea field. Shannon: "a proper bamboo forest maze ...
-- the bamboo needs to be close enough together so that it makes solid walls, so you can't see through them, with twists and turns, some
-- wrong turns, and one entrance and one exit, like a corn maze, you have to find your way through it". Oct 16 decisions kept: one
-- Blender bamboo mesh replaces the 102 part-built clumps; a new layout each day.
-- The maze: 10 x 12 cells of 9 studs (6-stud corridors, walls 3 thick, ~24 tall + leaves), x 5377..5470, z -272.5..-161.5 on the flat
-- lawn (y 0). ENTRANCE in the south wall at x 5410, where the walkway arrives; EXIT in the north wall at x 5419, onto the ramp up to the
-- Volcano Lookout. A perfect maze (one way through, the rest dead ends), grown by a recursive backtracker from the entrance; each day
-- (09:00 UTC, as the Guardian day) 10 seeds are tried and the one with the LONGEST way through is used - the same for every server that
-- day.
-- This script (Studio EDIT on her word; a play-test preview runs the same code on the test server):
--  * retires TeaHills."Bamboo grove maze" (102 part clumps) and the Landscape "Bamboo clump"s inside the footprint to
--    ServerStorage.HudBackup.MazeReplaced (attribute MazeWasIn on each)
--  * shortens TeaHills."Volcano overlook".Walkway (the long one) to end at the entrance (attributes MazeWasSize / MazeWasCFrame)
--  * builds JapanMap.BambooMaze: Walls (every wall slot - 260 - a kit wall clone, variant and half-turn by slot), the two gates with
--    their boards, MazeLayout (ModuleScript), MazeServer (lays out the day's maze at server start: open slots go to
--    ServerStorage.BambooMazeSpare), MazeCamera (client: inside the maze the camera can't zoom out past 9, so nobody looks over)
--  * lays out today's maze in Edit too
-- Re-runnable (BambooMaze is rebuilt; the walkway's first size is kept). Output "QQ BAMBOOMAZE1".
-- Undo: delete JapanMap.BambooMaze + ServerStorage.BambooMazeSpare; HudBackup.MazeReplaced's models back to their MazeWasIn; the
-- walkway's Size / CFrame from its MazeWas* attributes.
local SS = game:GetService("ServerStorage")
local J = workspace:FindFirstChild("JapanMap")
local TH = J and J:FindFirstChild("TeaHills")
local KIT = SS:FindFirstChild("JapanGardenKit")
if not (J and TH and KIT) then print("QQ BAMBOOMAZE1 ABORT: JapanMap.TeaHills or ServerStorage.JapanGardenKit missing") return end
local VARIANTS = {"bamboo_wall_A", "bamboo_wall_B", "bamboo_wall_C"}
for _, n in ipairs({"bamboo_wall_A", "bamboo_wall_B", "bamboo_wall_C", "maze_gate"}) do
	if not KIT:FindFirstChild(n) then print("QQ BAMBOOMAZE1 ABORT: the kit has no Model '" .. n .. "' - import japan_kit14_bamboo_maze.fbx") return end
end
local X0, ZN, P, COLS, ROWS = 5378.5, -271, 9, 10, 12
local FX0, FX1, FZ0, FZ1 = X0 - 1.5, X0 + P * COLS + 1.5, ZN - 1.5, ZN + P * ROWS + 1.5      -- the footprint
local CORE_MID = 10.6                                                                         -- the core box's middle above the base (kit: y -0.3..21.5)
local BOARD_MID = 8.1                                                                         -- the gate board's middle above the base
local COL = {Bamboo_Core = Color3.new(0.15, 0.20, 0.11), Bamboo_LeafL = Color3.new(0.42, 0.62, 0.24), Bamboo_LeafD = Color3.new(0.25, 0.44, 0.16),
	Gate_Board = Color3.new(0.55, 0.38, 0.22), Gate_Rope = Color3.new(0.80, 0.72, 0.52)}
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local bak = hb:FindFirstChild("MazeReplaced") or Instance.new("Folder"); bak.Name = "MazeReplaced"; bak.Parent = hb
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before bamboomaze1") end)
local function key(p) return (p.Name:gsub("_[ABC]$", ""):gsub("%.%d+$", "")) end
-- ---------- 1. retire the part bamboo in the footprint ----------
local retired = 0
local function retire(m) m:SetAttribute("MazeWasIn", m.Parent:GetFullName()); m.Parent = bak; retired += 1 end
local grove = TH:FindFirstChild("Bamboo grove maze"); if grove then retire(grove) end
local land = J:FindFirstChild("Landscape")
if land then
	for _, c in ipairs(land:GetChildren()) do
		if c.Name == "Bamboo clump" and c:IsA("Model") then
			local cf = c:GetBoundingBox()
			if cf.X > FX0 - 3 and cf.X < FX1 + 3 and cf.Z > FZ0 - 3 and cf.Z < FZ1 + 3 then retire(c) end
		end
	end
end
-- ---------- 2. the walkway ends at the entrance ----------
local walk = "not found"
local ov = TH:FindFirstChild("Volcano overlook")
if ov then
	for _, w in ipairs(ov:GetChildren()) do
		if w:IsA("BasePart") and w.Name == "Walkway" and (w:GetAttribute("MazeWasSize") or w.Size).Z > 150 then
			if not w:GetAttribute("MazeWasSize") then w:SetAttribute("MazeWasSize", w.Size); w:SetAttribute("MazeWasCFrame", w.CFrame) end
			local was, wcf = w:GetAttribute("MazeWasSize"), w:GetAttribute("MazeWasCFrame")
			local south = wcf.Z + was.Z / 2                                                   -- its south end (-83) stays
			local north = FZ1                                                                 -- now ends at the maze's south wall
			w.Size = Vector3.new(was.X, was.Y, south - north)
			w.CFrame = CFrame.new(wcf.X, wcf.Y, (south + north) / 2) * (wcf - wcf.Position)
			walk = string.format("Walkway now z %.1f..%.1f (was %.1f long)", north, south, was.Z)
		end
	end
end
-- ---------- 3. the maze model ----------
local old = J:FindFirstChild("BambooMaze"); if old then old:Destroy() end
local oldSpare = SS:FindFirstChild("BambooMazeSpare"); if oldSpare then oldSpare:Destroy() end
local maze = Instance.new("Model"); maze.Name = "BambooMaze"
local walls = Instance.new("Folder"); walls.Name = "Walls"; walls.Parent = maze
local spare = Instance.new("Folder"); spare.Name = "BambooMazeSpare"
maze:SetAttribute("Footprint", Vector3.new(FX0, FZ0, 0)); maze:SetAttribute("FootprintMax", Vector3.new(FX1, FZ1, 0))
local function prep(src, partName, mid)
	for _, p in ipairs(src:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true end end
	local ref
	for _, d in ipairs(src:GetDescendants()) do if d:IsA("BasePart") and key(d) == partName then ref = d end end   -- (kit names carry the variant: Bamboo_Core_A)
	if not ref then error("the kit's " .. src.Name .. " has no " .. partName) end
	local R = (ref and ref.Size.Z > ref.Size.X) and CFrame.Angles(0, math.pi / 2, 0) or CFrame.new()   -- the kit runs along X; undo a quarter turn if the import made one
	src.WorldPivot = CFrame.new(ref.Position - Vector3.new(0, mid, 0)) * R
end
for _, n in ipairs(VARIANTS) do prep(KIT[n], "Bamboo_Core", CORE_MID) end
prep(KIT.maze_gate, "Gate_Board", BOARD_MID)
local function dress(m)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			local k = key(p)
			p.Anchored = true; p.CanTouch = false
			if k == "Bamboo_Core" then
				p.Material = Enum.Material.SmoothPlastic; p.Color = COL[k]; p.CanCollide = true; p.CanQuery = true; p.CastShadow = true
			elseif k == "Bamboo_Culm" or k == "Gate_Culm" then
				p.Material = Enum.Material.SmoothPlastic; p.Color = Color3.new(1, 1, 1); p.CanCollide = false; p.CanQuery = false; p.CastShadow = true
			else
				p.Material = (k == "Gate_Board") and Enum.Material.Wood or Enum.Material.SmoothPlastic
				p.Color = COL[k] or p.Color; p.CanCollide = false; p.CanQuery = false; p.CastShadow = (k ~= "Bamboo_LeafL" and k ~= "Bamboo_LeafD")
				if k == "Bamboo_LeafL" or k == "Bamboo_LeafD" then pcall(function() p.DoubleSided = true end) end
			end
		end
	end
end
local nslots = 0
local function slot(name, x, z, alongZ, n)
	local v = VARIANTS[(n * 7 + 3) % 3 + 1]
	local m = KIT[v]:Clone(); m.Name = name
	local yaw = (alongZ and math.pi / 2 or 0) + ((n * 5) % 2 == 1 and math.pi or 0)
	m:PivotTo(CFrame.new(x, 0, z) * CFrame.Angles(0, yaw, 0))
	dress(m)
	m.Parent = walls; nslots += 1
end
local n = 0
for j = 0, ROWS do for c = 0, COLS - 1 do n += 1; slot(string.format("H_%d_%d", c, j), X0 + P * c + P / 2, ZN + P * j, false, n) end end
for i = 0, COLS do for r = 0, ROWS - 1 do n += 1; slot(string.format("V_%d_%d", i, r), X0 + P * i, ZN + P * r + P / 2, true, n) end end
-- the gates: the entrance takes H_3_12's place (south wall), the exit H_4_0's (north wall)
local GATES = {{slotName = "H_3_12", name = "EntranceGate", outside = "Back", outText = "竹の迷路\nBAMBOO MAZE · ENTRANCE", inText = "ENTRANCE · 入口"},
	{slotName = "H_4_0", name = "ExitGate", outside = "Front", outText = "BAMBOO MAZE · EXIT", inText = "EXIT · 出口"}}
for _, g in ipairs(GATES) do
	local s = walls:FindFirstChild(g.slotName)
	local pos = s:GetPivot().Position
	s:Destroy(); nslots -= 1
	local m = KIT.maze_gate:Clone(); m.Name = g.name
	m:PivotTo(CFrame.new(pos.X, 0, pos.Z))
	dress(m)
	local board = m:FindFirstChild("Gate_Board", true)
	for _, face in ipairs({"Front", "Back"}) do
		local sg = Instance.new("SurfaceGui"); sg.Name = "Sign" .. face; sg.Face = Enum.NormalId[face]
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 60; sg.LightInfluence = 0.6
		local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.Size = UDim2.fromScale(0.92, 0.84); t.Position = UDim2.fromScale(0.04, 0.08)
		t.Font = Enum.Font.GothamBold; t.TextScaled = true; t.TextColor3 = Color3.fromRGB(250, 244, 228)
		t.Text = (face == g.outside) and g.outText or g.inText; t.Parent = sg
		sg.Parent = board
	end
	m.Parent = maze
end
-- ---------- 4. the scripts ----------
local layout = Instance.new("ModuleScript"); layout.Name = "MazeLayout"
layout.Source = [==[
-- the bamboo maze's daily layout (bamboomaze1.lua): 10 x 12 cells; a recursive backtracker from the entrance cell; of 10 seeds a day
-- the one with the longest way from the entrance to the exit. open["H_c_j"] / open["V_i_r"] = a passage through that wall slot.
local M = {}
M.COLS, M.ROWS = 10, 12
M.ENTRY = {3, 11}                       -- the cell inside the entrance (south wall slot H_3_12)
M.EXIT = {4, 0}                         -- the cell inside the exit (north wall slot H_4_0)
function M.day() return (os.time() - 9 * 3600) // 86400 end
local function wallBetween(a, b)       -- the wall slot between two neighbouring cells
	if a[1] == b[1] then return string.format("H_%d_%d", a[1], math.max(a[2], b[2])) end
	return string.format("V_%d_%d", math.max(a[1], b[1]), a[2])
end
local function grow(seed)
	local rnd = Random.new(seed)
	local seen, open = {}, {}
	local function id(c) return c[1] * 100 + c[2] end
	local stack = {M.ENTRY}; seen[id(M.ENTRY)] = true
	local guard = 0
	while #stack > 0 do
		guard += 1; if guard > 10000 then error("maze grow ran away") end
		local cur = stack[#stack]
		local nb = {}
		for _, d in ipairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do
			local c = {cur[1] + d[1], cur[2] + d[2]}
			if c[1] >= 0 and c[1] < M.COLS and c[2] >= 0 and c[2] < M.ROWS and not seen[id(c)] then table.insert(nb, c) end
		end
		if #nb == 0 then table.remove(stack) else
			local c = nb[rnd:NextInteger(1, #nb)]
			open[wallBetween(cur, c)] = true; seen[id(c)] = true; table.insert(stack, c)
		end
	end
	-- the way through: breadth-first from the entrance
	local prev, q, head = {[id(M.ENTRY)] = false}, {M.ENTRY}, 1
	while head <= #q do
		local cur = q[head]; head += 1
		for _, d in ipairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do
			local c = {cur[1] + d[1], cur[2] + d[2]}
			if c[1] >= 0 and c[1] < M.COLS and c[2] >= 0 and c[2] < M.ROWS and prev[id(c)] == nil and open[wallBetween(cur, c)] then
				prev[id(c)] = cur; table.insert(q, c)
			end
		end
	end
	local len, c = 0, M.EXIT
	while c and len < 1000 do len += 1; c = prev[id(c)] or nil end
	return open, len
end
function M.best(day)
	local bestOpen, bestLen, bestSeed = nil, -1, nil
	for k = 0, 9 do
		local open, len = grow(day * 16 + k)
		if len > bestLen then bestOpen, bestLen, bestSeed = open, len, day * 16 + k end
	end
	return bestOpen, bestLen, bestSeed
end
-- move the wall slots: perimeter always up (but the two gates' slots, which are gone), inner walls up unless open today
function M.apply(walls, spare, open)
	local up, down = 0, 0
	local all = {}
	for _, m in ipairs(walls:GetChildren()) do table.insert(all, m) end
	for _, m in ipairs(spare:GetChildren()) do table.insert(all, m) end
	for _, m in ipairs(all) do
		local kind, a, b = m.Name:match("^([HV])_(%d+)_(%d+)$")
		if kind then
			a, b = tonumber(a), tonumber(b)
			local inner = (kind == "H" and b > 0 and b < M.ROWS) or (kind == "V" and a > 0 and a < M.COLS)
			local isOpen = inner and open[m.Name] == true
			local want = isOpen and spare or walls
			if m.Parent ~= want then m.Parent = want end
			if isOpen then down += 1 else up += 1 end
		end
	end
	return up, down
end
return M
]==]
layout.Parent = maze
local server = Instance.new("Script"); server.Name = "MazeServer"; server.RunContext = Enum.RunContext.Server
server.Source = [==[
-- lays out the day's bamboo maze when the server starts (bamboomaze1.lua); the same layout on every server that day
local SS = game:GetService("ServerStorage")
local maze = script.Parent
local L = require(maze:WaitForChild("MazeLayout"))
local walls = maze:WaitForChild("Walls")
local spare = SS:FindFirstChild("BambooMazeSpare")
if not spare then spare = Instance.new("Folder"); spare.Name = "BambooMazeSpare"; spare.Parent = SS end
local day = L.day()
local open, len, seed = L.best(day)
local up, down = L.apply(walls, spare, open)
maze:SetAttribute("LayoutDay", day); maze:SetAttribute("LayoutSeed", seed); maze:SetAttribute("WayThrough", len)
print(string.format("BambooMaze: day %d (seed %d): %d walls up, %d open; the way through is %d cells", day, seed, up, down, len))
]==]
server.Parent = maze
local cam = Instance.new("Script"); cam.Name = "MazeCamera"; cam.RunContext = Enum.RunContext.Client
cam.Source = string.format([==[
-- inside the bamboo maze the camera can't zoom out past 9 studs, so nobody looks over the walls (bamboomaze1.lua). The player's own
-- setting is kept in an attribute and given back on the way out (safe if this script runs twice).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer
local X0, X1, Z0, Z1, MAXZ = %.1f, %.1f, %.1f, %.1f, 9
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt; if acc < 0.2 then return end; acc = 0
	local ch = lp.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local p = hrp and hrp.Position
	local inside = p ~= nil and p.X > X0 and p.X < X1 and p.Z > Z0 and p.Z < Z1 and p.Y < 30
	local saved = lp:GetAttribute("MazeCamSaved")
	if inside and saved == nil then
		lp:SetAttribute("MazeCamSaved", lp.CameraMaxZoomDistance)
		lp.CameraMaxZoomDistance = math.min(lp.CameraMaxZoomDistance, MAXZ)
	elseif not inside and saved ~= nil then
		lp.CameraMaxZoomDistance = saved
		lp:SetAttribute("MazeCamSaved", nil)
	end
end)
]==], FX0, FX1, FZ0, FZ1)
cam.Parent = maze
maze.Parent = J
spare.Parent = SS
-- ---------- 5. today's layout in Edit too ----------
local L = require(layout)
local day = L.day()
local open, len, seed = L.best(day)
local up, down = L.apply(walls, spare, open)
maze:SetAttribute("LayoutDay", day); maze:SetAttribute("LayoutSeed", seed); maze:SetAttribute("WayThrough", len)
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after bamboomaze1") end)
print(string.format("QQ BAMBOOMAZE1 retired %d part-bamboo models -> HudBackup.MazeReplaced; %s", retired, walk))
print(string.format("QQ BAMBOOMAZE1 DONE: BambooMaze %d wall slots + 2 gates at x %.1f..%.1f, z %.1f..%.1f; today (day %d, seed %d): %d walls up, %d open, the way through %d cells; MazeServer lays out each day, MazeCamera holds the zoom at 9 inside",
	nslots, FX0, FX1, FZ0, FZ1, day, seed, up, down, len))
