-- PortoGateClient (Oct 8 2026): Porto's gates and walls for this player, like France (Boundary GateClient + BoundaryOpen).
-- A gate opens once this player has found Need squirrels in the area it leads out of (NeedArea, e.g. porto_harbour; the
-- server keeps Found_porto_<area>): its Block stops blocking, its leaves swing (or its rope is put away) with a creak, and
-- the walls with the same NeedArea stop blocking. Only this player's copy changes, so players at different stages each get
-- the right Porto.
-- v2 (Oct 8 2026, Shannon on her phone: the floating sign over a gate "is very big and hidden under everything and moves
-- when you move"): the note is one small card fixed on the screen just under the top row of buttons, for the gate you are
-- near and for the "walked back" message (PortoGateBounce from the server). It steps aside while the map or the squirrel
-- panel is open, so it never covers them.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local root = script.Parent
local NEED = root:GetAttribute("Need") or 10
local NL = string.char(10)
local NAMES = {porto_harbour = "The Harbour", porto_borgo = "Via della Piazza", porto_groves = "The Groves"}
local TOTAL = {}
pcall(function()
	local Registry = require(workspace:WaitForChild("SquirrelScripts"):WaitForChild("SquirrelRegistry"))
	for _, e in ipairs(Registry.squirrels) do if e.map == "porto" and e.area then local k = "porto_" .. e.area TOTAL[k] = (TOTAL[k] or 0) + 1 end end
end)
local function found(area) return player:GetAttribute("Found_" .. area) or 0 end
local function isOpen(area) return root:GetAttribute("Enabled") == false or found(area) >= NEED end

-- ---------------------------------------------------------------- the walls
local walls = root:WaitForChild("Walls")
local function applyWall(p)
	local a = p:IsA("BasePart") and p:GetAttribute("NeedArea")
	if a then p.CanCollide = not isOpen(a) end
end
local function refreshWalls() for _, p in ipairs(walls:GetDescendants()) do applyWall(p) end end
walls.DescendantAdded:Connect(applyWall)

-- ---------------------------------------------------------------- the note card
local pg = player:WaitForChild("PlayerGui")
for _, old in ipairs(pg:GetChildren()) do if old.Name == "PortoGateNote" then old:Destroy() end end
local gui = Instance.new("ScreenGui") gui.Name = "PortoGateNote" gui.ResetOnSpawn = false gui.IgnoreGuiInset = true gui.DisplayOrder = 7 gui.Parent = pg
local card = Instance.new("Frame") card.Name = "Card" card.AnchorPoint = Vector2.new(0.5, 0) card.BackgroundColor3 = Color3.fromRGB(38, 30, 52)
card.BackgroundTransparency = 0.12 card.BorderSizePixel = 0 card.Visible = false card.Parent = gui
local cc = Instance.new("UICorner") cc.CornerRadius = UDim.new(0, 12) cc.Parent = card
local cs = Instance.new("UIStroke") cs.Color = Color3.fromRGB(240, 200, 90) cs.Thickness = 2 cs.Parent = card
local txt = Instance.new("TextLabel") txt.Name = "Text" txt.BackgroundTransparency = 1 txt.Size = UDim2.new(1, -20, 1, -8) txt.Position = UDim2.fromOffset(10, 4)
txt.Font = Enum.Font.FredokaOne txt.TextColor3 = Color3.fromRGB(255, 246, 220) txt.TextWrapped = true txt.RichText = true txt.Parent = card
local GuiService = game:GetService("GuiService")
-- the lowest edge of whatever sits along the top of the screen above where the card goes (title pill, top buttons)
local function topRowBottom(x0, x1)
	local inset = GuiService:GetGuiInset().Y
	local bottom = 0
	for _, sg in ipairs(pg:GetChildren()) do
		if sg:IsA("ScreenGui") and sg.Enabled and sg ~= gui then
			for _, g in ipairs(sg:GetDescendants()) do
				if g:IsA("GuiObject") and g.Visible and g.AbsoluteSize.Y > 4 and g.AbsoluteSize.Y < 90 then
					local vis = true
					local a = g.Parent
					while a and a ~= sg do if a:IsA("GuiObject") and not a.Visible then vis = false break end a = a.Parent end
					local y0 = g.AbsolutePosition.Y + inset
					local gx0, gx1 = g.AbsolutePosition.X, g.AbsolutePosition.X + g.AbsoluteSize.X
					if vis and y0 < 70 and gx1 > x0 and gx0 < x1 and (g.BackgroundTransparency < 1 or g:IsA("ImageLabel") or g:IsA("ImageButton") or (g:IsA("TextLabel") and g.Text ~= "")) then
						bottom = math.max(bottom, y0 + g.AbsoluteSize.Y)
					end
				end
			end
		end
	end
	return math.max(bottom, inset)
end
local function layout()
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local phone = vp.Y < 500
	local w = math.min(phone and 340 or 460, vp.X - 40)
	local h = phone and 50 or 62
	txt.TextSize = phone and 15 or 19
	local x0 = vp.X / 2 - w / 2
	card.Size = UDim2.fromOffset(w, h)
	card.Position = UDim2.fromOffset(vp.X / 2, topRowBottom(x0, x0 + w) + 8)
end
local owner, hideAt = nil, 0
local function panelOpen()
	local hb = pg:FindFirstChild("HudBar")
	local mp = hb and hb:FindFirstChild("MapPanel")
	local sh = pg:FindFirstChild("SquirrelHUD")
	local sp = sh and sh:FindFirstChild("Panel")
	return (mp and mp.Visible) or (sp and sp.Visible)
end
local function showCard(who, text, secs)
	owner = who
	txt.Text = text
	layout()
	card.Visible = not panelOpen()
	hideAt = os.clock() + secs
end
local function hideCard(who) if owner == who then card.Visible = false owner = nil end end
RunService.Heartbeat:Connect(function()
	if owner and (os.clock() > hideAt) then card.Visible = false owner = nil end
	if owner and card.Visible and panelOpen() then card.Visible = false end
end)
local function gold(t) return '<font color="#FFD65A">' .. t .. '</font>' end
player:GetAttributeChangedSignal("PortoGateBounce"):Connect(function()
	showCard("bounce", player:GetAttribute("PortoGateBounceText") or "", 4.5)
end)

-- ---------------------------------------------------------------- the gates
local function turn(leaf, ang)
	local hinge = leaf:GetAttribute("Hinge")
	if typeof(hinge) ~= "CFrame" or not leaf.Parent then return end
	leaf:PivotTo(hinge * (leaf:GetAttribute("Axis") == "Z" and CFrame.Angles(0, 0, ang) or CFrame.Angles(0, ang, 0)))
end
local function swing(leaf, from, to, dur)
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local a = math.clamp((os.clock() - t0) / dur, 0, 1)
		a = a * a * (3 - 2 * a)
		turn(leaf, from + (to - from) * a)
		if a >= 1 then conn:Disconnect() end
	end)
end

local done = {}
local function setupGate(g)
	if done[g] or not g:GetAttribute("NeedArea") then return end
	done[g] = true
	local area = g:GetAttribute("NeedArea")
	local toName = g:GetAttribute("ToName") or "the next area"
	local fromName = g:GetAttribute("FromName") or NAMES[area] or area
	local block = g:WaitForChild("Block", 10)
	local leaves = {}
	for _, c in ipairs(g:GetChildren()) do if c:IsA("Model") and c:GetAttribute("Hinge") then table.insert(leaves, c) end end
	local open = nil
	local noteText = ""
	local function refresh()
		local n = found(area)
		local ok = isOpen(area)
		if ok then
			noteText = "The way to " .. toName .. " is open!" .. NL .. gold(string.format("%d / %d found in %s", n, TOTAL[area] or n, fromName))
		else
			noteText = string.format("Find %d squirrels in %s to open this gate", NEED, fromName) .. NL .. gold(string.format("%d / %d found so far", n, NEED))
		end
		if owner == g then txt.Text = noteText end
		if ok ~= open then
			local first = (open == nil)
			open = ok
			if block then block.CanCollide = not ok end
			for _, leaf in ipairs(leaves) do
				local a = leaf:GetAttribute("OpenAngle") or 0
				if first then turn(leaf, ok and a or 0) else swing(leaf, ok and 0 or a, ok and a or 0, 1.3) end
			end
			for _, c in ipairs(g:GetChildren()) do          -- a rope (and its board) is unhooked and put away when the gate opens
				if c:GetAttribute("Hide") then
					for _, d in ipairs(c:GetDescendants()) do
						if d:IsA("BasePart") then d.Transparency = ok and 1 or 0 elseif d:IsA("SurfaceGui") then d.Enabled = not ok end
					end
				end
			end
			if ok and not first and block then
				local s = Instance.new("Sound") s.SoundId = "rbxassetid://1845415163" s.Volume = 0.45 s.RollOffMaxDistance = 60 s.Parent = block s:Play() Debris:AddItem(s, 5)
			end
		end
	end
	player:GetAttributeChangedSignal("Found_" .. area):Connect(refresh)
	root:GetAttributeChangedSignal("Enabled"):Connect(refresh)
	refresh()
	-- the note: shown as you come near (for a closed gate every time, for an open one the first time) and gone a few
	-- seconds later or when you walk away
	local near, told = false, (open == true)
	task.spawn(function()
		while g.Parent do
			task.wait(0.25)
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local ref = block and block.Position or g:GetPivot().Position
			local d = hrp and (hrp.Position - ref).Magnitude or 1e9
			if not near and d < 24 then
				near = true
				if not open or not told then
					showCard(g, noteText, 6)
					if open then told = true end
				end
			elseif near and d > 36 then
				near = false hideCard(g)
			end
		end
	end)
end
local gates = root:WaitForChild("Gates")
for _, g in ipairs(gates:GetChildren()) do task.spawn(setupGate, g) end
gates.ChildAdded:Connect(function(g) task.defer(setupGate, g) end)
for _, a in ipairs({"porto_harbour", "porto_borgo"}) do player:GetAttributeChangedSignal("Found_" .. a):Connect(refreshWalls) end
root:GetAttributeChangedSignal("Enabled"):Connect(refreshWalls)
refreshWalls()
player.CharacterAdded:Connect(function() task.delay(0.5, refreshWalls) end)
