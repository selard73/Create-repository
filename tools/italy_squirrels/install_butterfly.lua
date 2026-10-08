-- Oct 7 2026 (night): Butterfly Catcher Squirrel (butterfly_squirrel, Meshy "Scout's Butterfly Catcher"; she), The Groves 14 of 15.
-- Her picks: the windflower patch of the Prato dei Fiori meadow (~555,2,-1105), between the Drone Flyer and the keeper's cottage,
-- facing the meadow path; bio 3 as "her"; three little butterflies (blue, orange, yellow) built from Parts in
-- workspace.PortoNocciola["Butterfly Catcher's butterflies"], fluttering round her net in play (client Script Flutter; CentreLocal
-- in her mesh's edit-size local studs, like the drone). Running pose: one foot on the ground.
-- Folded in Oct 8 from fix_oct7_feet_ids_butterflies.lua: NoHeadAnim, rounded disc wings + the matching Flutter. Registry after the Guitarist (or the
-- Sea Glass Collector if the Guitarist is not in yet).
local LOG = {}
local function log(...) local t = {} for i = 1, select('#', ...) do t[#t + 1] = tostring(select(i, ...)) end LOG[#LOG + 1] = table.concat(t, ' ') end
local id = 'butterfly_squirrel'
local col, gry = workspace:FindFirstChild(id .. '_color'), workspace:FindFirstChild(id .. '_gray')
if not (col and gry) then return 'QM@ABORT missing import ' .. tostring(col) .. ' ' .. tostring(gry) end
local cm, gm = col.Squirrel, gry.Squirrel
local Bn = {} for _, x in ipairs(col:GetDescendants()) do if x:IsA('Bone') then Bn[x.Name] = x end end
if not (Bn.Head and Bn.Tail2) then return 'QM@ABORT no Head/Tail2 bone' end
local rel = cm.CFrame:Inverse() * col:GetPivot() col:PivotTo(CFrame.new(cm.Position) * rel)
local function axes()
	local tl = cm.CFrame:PointToObjectSpace(Bn.Tail2.WorldPosition)
	return tl.Z > 0 and 1 or -1, tl.X < 0 and 1 or -1
end
local function face(want)
	for i = 1, 3 do
		local sz = axes()
		local R = cm.CFrame - cm.Position
		local fwd = R:VectorToWorldSpace(Vector3.new(0, 0, -sz)) * Vector3.new(1, 0, 1)
		local ang = math.atan2(want.X, want.Z) - math.atan2(fwd.X, fwd.Z)
		local c = CFrame.new(cm.Position) col:PivotTo(c * CFrame.Angles(0, ang, 0) * c:Inverse() * col:GetPivot())
	end
end
local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Exclude
rp.FilterDescendantsInstances = {col, gry, workspace:FindFirstChild('SquirrelTwins'), workspace:FindFirstChild('Zones')}
rp.IgnoreWater = false
local function ground(p) local q = workspace:Raycast(Vector3.new(p.X, 30, p.Z), Vector3.new(0, -40, 0), rp) return q and q.Position.Y, q and q.Instance end
local SPOT = Vector3.new(555, 0, -1105)
local WANT = Vector3.new(-0.85, 0, 0.53)  -- toward the meadow path
-- feet (feet_probe, model units)
local feet = {{-0.34, -0.02}, {-0.11, -0.02}, {-0.34, 0.24}, {-0.11, 0.24}, {-0.22, 0.08}}
local FC = {-0.22, 0.08}
local k = 3.4 / cm.Size.Y
face(WANT)
local sz, sx = axes()
local R = cm.CFrame - cm.Position
local function W(bx, by) return R:VectorToWorldSpace(Vector3.new(sx * bx, 0, sz * by) * k) end
local fc = W(FC[1], FC[2])
local best
for dx = -0.6, 0.6, 0.2 do for dz = -0.6, 0.6, 0.2 do
	local c = SPOT + Vector3.new(dx, 0, dz)
	local hi, lo, ok = -1e9, 1e9, true
	for _, f in ipairs(feet) do
		local w = c + W(f[1] - FC[1], f[2] - FC[2])
		local y, inst = ground(w)
		if not y or (inst == workspace.Terrain and y < -52.5) then ok = false break end   -- every fin on the beach, none in the water
		hi = math.max(hi, y) lo = math.min(lo, y)
	end
	if ok then
		local score = (hi - lo) * 10 + math.abs(dx) + math.abs(dz)
		if not best or score < best.s then best = {s = score, c = c, y = hi, spread = hi - lo} end
	end
end end
if not best then return 'QM@ABORT no footing near ' .. tostring(SPOT) end
local L = Vector3.new(best.c.X, best.y, best.c.Z)
col:PivotTo(col:GetPivot() + Vector3.new(L.X - fc.X - cm.Position.X, L.Y + 0.02 - (cm.Position.Y - cm.Size.Y / 2), L.Z - fc.Z - cm.Position.Z))
cm.RenderFidelity = Enum.RenderFidelity.Precise gm.RenderFidelity = Enum.RenderFidelity.Precise
cm:SetAttribute('ColorTexture', cm.TextureID) cm:SetAttribute('GrayTexture', gm.TextureID)
col:SetAttribute('NoHeadAnim', true)   -- her face pulled on head turns (Oct 7 flag)
local twins = workspace:FindFirstChild('SquirrelTwins')
if twins then gry.Parent = twins gry:PivotTo(gry:GetPivot() + Vector3.new(0, -400 - gry:GetPivot().Y, 0)) end
log('QM@BUTTERFLY feet centre', L, 'spread', best.spread, 'facing', R:VectorToWorldSpace(Vector3.new(0, 0, -sz)), 'sx', sx, 'sz', sz)
game:GetService('ChangeHistoryService'):SetWaypoint('Butterfly Catcher placed')

-- three little butterflies round her net
do
	local old = workspace.PortoNocciola:FindFirstChild("Butterfly Catcher's butterflies") if old then old:Destroy() end
	local holder = Instance.new('Folder') holder.Name = "Butterfly Catcher's butterflies"
	local centreLocal = Vector3.new(sx * 0.5, 2.1 - cm.Size.Y / 2, sz * -0.5)     -- just in front of and above the net hoop (edit-size studs)
	local centre = cm.CFrame:PointToWorldSpace(centreLocal)
	local cols = {Color3.fromRGB(70, 140, 235), Color3.fromRGB(245, 150, 40), Color3.fromRGB(250, 215, 60)}
	local function part(name, size, colour, parent)
		local p = Instance.new('Part') p.Name = name p.Size = size p.Color = colour p.Material = Enum.Material.SmoothPlastic
		p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false p.CastShadow = false
		p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth p.Parent = parent return p
	end
	for n = 1, 3 do
		local m = Instance.new('Model') m.Name = 'Butterfly' .. n
		local body = part('Body', Vector3.new(0.05, 0.05, 0.26), Color3.fromRGB(45, 35, 30), m)
		local at = CFrame.new(centre + Vector3.new(math.cos(n * 2.1), 0.2 * n, math.sin(n * 2.1)))
		body.CFrame = at
		-- rounded wings (her flag: not flying books): a flat disc = Cylinder part with its axis turned up, fore + hind per side
		for _, side in ipairs({-1, 1}) do
			local fore = part(side < 0 and 'LeftFore' or 'RightFore', Vector3.new(0.02, 0.3, 0.3), cols[n], m)
			fore.Shape = Enum.PartType.Cylinder fore:SetAttribute('Side', side) fore:SetAttribute('OX', 0.14) fore:SetAttribute('OZ', -0.05)
			local hind = part(side < 0 and 'LeftHind' or 'RightHind', Vector3.new(0.02, 0.2, 0.2), cols[n]:Lerp(Color3.new(1, 1, 1), 0.25), m)
			hind.Shape = Enum.PartType.Cylinder hind:SetAttribute('Side', side) hind:SetAttribute('OX', 0.1) hind:SetAttribute('OZ', 0.1)
			for _, w in ipairs({fore, hind}) do
				w.CFrame = at * CFrame.new(side * w:GetAttribute('OX'), 0, w:GetAttribute('OZ')) * CFrame.Angles(0, 0, math.pi / 2)
			end
		end
		m.PrimaryPart = body
		m:SetAttribute('Phase', n * 2.1) m:SetAttribute('Radius', 0.9 + 0.35 * n) m:SetAttribute('Speed', 0.8 + 0.25 * n)
		m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		m.Parent = holder
	end
	holder:SetAttribute('Squirrel', id .. '_color')
	holder:SetAttribute('CentreLocal', centreLocal)
	holder:SetAttribute('EditSizeY', cm.Size.Y)
	holder:SetAttribute('Rest', centre)
	holder:SetAttribute('Built', 'Oct 7 2026 butterflies for the Butterfly Catcher (butterfly_squirrel)')
	local scr = Instance.new('Script') scr.Name = 'Flutter' scr.RunContext = Enum.RunContext.Client
	scr.Source = [==[
-- Oct 7 2026: the Butterfly Catcher's butterflies. Each client flutters its own copies round a point by her net: CentreLocal
-- (attribute) = that point in her mesh's local studs at Studio size (EditSizeY), scaled with her in play.
-- StreamingEnabled: the butterflies may stream in after this script starts, so the list is rebuilt until all three are here.
-- Wings: rounded discs (fore + hind each side; attributes Side, OX, OZ) hinged on the body (Shannon: not flying books).
local RunService = game:GetService("RunService")
local holder = script.Parent
local cm, lastLook, lastScan = nil, -10, -10
local flies = {}
local function scan()
	flies = {}
	for _, m in ipairs(holder:GetChildren()) do
		local b = m:FindFirstChild("Body")
		if m:IsA("Model") and b then
			local wings = {}
			for _, w in ipairs(m:GetChildren()) do if w:GetAttribute("Side") then table.insert(wings, w) end end
			if #wings == 4 then
				table.insert(flies, {body = b, wings = wings, ph = m:GetAttribute("Phase") or 0,
					rad = m:GetAttribute("Radius") or 1.2, sp = m:GetAttribute("Speed") or 1})
			end
		end
	end
end
local function findHer()
	local sq = workspace:FindFirstChild(holder:GetAttribute("Squirrel") or "butterfly_squirrel_color")
	cm = sq and sq:FindFirstChild("Squirrel")
end
local function pathAt(f, a)
	return Vector3.new(math.cos(a) * f.rad, 0.45 * math.sin(a * 2.3), math.sin(a * 1.3) * f.rad * 0.8)
end
local TURN = CFrame.Angles(0, 0, math.pi / 2)   -- a cylinder's axis is X: turned up, the disc lies flat
RunService.RenderStepped:Connect(function()
	local now = os.clock()
	if #flies < 3 and now - lastScan > 1 then lastScan = now scan() end
	if (not cm or not cm.Parent) and now - lastLook > 2 then lastLook = now findHer() end
	local base = holder:GetAttribute("Rest")
	local cl, editY = holder:GetAttribute("CentreLocal"), holder:GetAttribute("EditSizeY")
	if cm and cm.Parent and cl and editY then base = cm.CFrame:PointToWorldSpace(cl * (cm.Size.Y / editY)) end
	if not base then return end
	local cam = workspace.CurrentCamera
	if not cam or (cam.CFrame.Position - base).Magnitude > 120 then return end
	for _, f in ipairs(flies) do
		if f.body.Parent then
			local a = now * 0.9 * f.sp + f.ph
			local p = base + pathAt(f, a) + Vector3.new(0, 0.12 * math.sin(now * 9 + f.ph), 0)
			local dir = (pathAt(f, a + 0.05) - pathAt(f, a)) * Vector3.new(1, 0, 1)
			local cf = dir.Magnitude > 1e-4 and CFrame.lookAt(p, p + dir) or CFrame.new(p)
			local flap = 0.1 + 1.25 * (0.5 + 0.5 * math.sin(now * 14 + f.ph))   -- wings sweep from nearly flat to nearly upright
			f.body.CFrame = cf
			for _, w in ipairs(f.wings) do
				local side = w:GetAttribute("Side")
				w.CFrame = cf * CFrame.Angles(0, 0, side * flap) * CFrame.new(side * w:GetAttribute("OX"), 0, w:GetAttribute("OZ")) * TURN
			end
		else
			lastScan = -10 flies = {}
			break
		end
	end
end)
]==]
	scr.Parent = holder
	holder.Parent = workspace.PortoNocciola
	log('QM@BUTTERFLY flies centre', centre)
	game:GetService('ChangeHistoryService'):SetWaypoint('Butterfly Catcher butterflies')
end

local reg = workspace.SquirrelScripts.SquirrelRegistry
local rs = reg.Source
local a, b = rs:find('He plays it very well, and very often."},\n', 1, true)
if not a then a, b = rs:find('still looking for the purple one."},\n', 1, true) end
if not a or rs:find('butterfly_squirrel', 1, true) then log('QM@REG_SKIP anchor/dup', a) return table.concat(LOG, '\n') end
local add = '\t\t{id = "butterfly_squirrel",     map = "porto", area = "groves", name = "Butterfly Catcher Squirrel",\n\t\t bio = "Has never caught a single butterfly. Her net has caught three hats and a sandwich."},\n'
reg.Source = rs:sub(1, b) .. add .. rs:sub(b + 1)
game:GetService('ChangeHistoryService'):SetWaypoint('Butterfly Catcher registry')
local n = 0 for _ in reg.Source:gmatch('area = "groves"') do n += 1 end
log('QM@REG groves entries', n)
local m = Instance.new('ModuleScript') m.Source = reg.Source m.Parent = game.ServerStorage
local okp, res = pcall(require, m) m:Destroy()
log('QM@REG parse', okp, okp and #res.squirrels or res)
return table.concat(LOG, '\n')
