-- Oct 7 2026 late (her yes + her flags): (1) squirrels sank ~0.15-0.2 studs at play start (SquirrelSetup measured the "bottom"
-- with GetBoundingBox, which follows the pivot's axes - turned on imported squirrels) -> world-aligned box of the parts;
-- (2) the four Oct 6 squirrels' gray twins carried GrayTexture and were set up as squirrels first, so the visible ones got
-- "<id>_2" and finds never counted -> twins stay twins + saved "_2" finds load as the real id; (3) Butterfly Catcher's face
-- pulled on head turns -> NoHeadAnim; (4) the butterflies looked like flying books -> rounded fore/hind wings.
local LOG = {}
local function log(...) local t = {} for i = 1, select('#', ...) do t[#t + 1] = tostring(select(i, ...)) end LOG[#LOG + 1] = table.concat(t, ' ') end
local function patch(script, old, new, label)
	local src = script.Source
	local a = src:find(old, 1, true)
	if not a then log('ANCHOR MISSING', label) return false end
	script.Source = src:sub(1, a - 1) .. new .. src:sub(a + #old)
	log('patched', label)
	return true
end
local setup = workspace.SquirrelScripts.SquirrelSetup

-- (2a) gray twins that carry a GrayTexture attribute stay twins
patch(setup, 'if mesh:GetAttribute("GrayTexture") then table.insert(colours, mesh)',
	'if mesh:GetAttribute("GrayTexture") and not isGray(mesh) then table.insert(colours, mesh)', 'twins stay twins')

-- (2b) saved "<id>_2" finds load as <id>
patch(setup, 'for _, id in ipairs(data.found) do t[(tostring(id):gsub("_color$", ""))] = true end',
	'for _, id in ipairs(data.found) do\n'
	.. '\t\t\t\t\tlocal sid = (tostring(id):gsub("_color$", ""))\n'
	.. '\t\t\t\t\tif not byId[sid] then local base = sid:match("^(.-)_%d+$") if base and byId[base] then sid = base end end   -- Oct 7 2026: "pogo_squirrel_2" finds (twin mix-up) count as pogo_squirrel\n'
	.. '\t\t\t\t\tt[sid] = true\n'
	.. '\t\t\t\tend', 'saved _2 finds')

-- (1) feet stay where they were placed when the squirrel is scaled to game size
patch(setup,
	'\t\tlocal cf0, sz0 = model:GetBoundingBox()\n'
	.. '\t\tlocal bottom = cf0.Position.Y - sz0.Y / 2\n'
	.. '\t\tmodel:ScaleTo(model:GetScale() * targetH / mesh.Size.Y)\n'
	.. '\t\tlocal cf1, sz1 = model:GetBoundingBox()\n'
	.. '\t\tmodel:PivotTo(model:GetPivot() + Vector3.new(cf0.Position.X - cf1.Position.X, bottom - (cf1.Position.Y - sz1.Y / 2), cf0.Position.Z - cf1.Position.Z))\n',
	'\t\t-- Oct 7 2026: a world-aligned box of the parts (GetBoundingBox follows the pivot\'s axes, turned on imported squirrels, so\n'
	.. '\t\t-- they sank 0.15-0.2 studs: Shannon saw the keeper\'s feet in the lighthouse\'s stone)\n'
	.. '\t\tlocal function worldBox(m)\n'
	.. '\t\t\tlocal lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)\n'
	.. '\t\t\tfor _, p in ipairs(m:GetDescendants()) do\n'
	.. '\t\t\t\tif p:IsA("BasePart") then\n'
	.. '\t\t\t\t\tlocal cf, s = p.CFrame, p.Size / 2\n'
	.. '\t\t\t\t\tlocal e = Vector3.new(\n'
	.. '\t\t\t\t\t\tmath.abs(cf.RightVector.X) * s.X + math.abs(cf.UpVector.X) * s.Y + math.abs(cf.LookVector.X) * s.Z,\n'
	.. '\t\t\t\t\t\tmath.abs(cf.RightVector.Y) * s.X + math.abs(cf.UpVector.Y) * s.Y + math.abs(cf.LookVector.Y) * s.Z,\n'
	.. '\t\t\t\t\t\tmath.abs(cf.RightVector.Z) * s.X + math.abs(cf.UpVector.Z) * s.Y + math.abs(cf.LookVector.Z) * s.Z)\n'
	.. '\t\t\t\t\tlo = lo:Min(cf.Position - e) hi = hi:Max(cf.Position + e)\n'
	.. '\t\t\t\tend\n'
	.. '\t\t\tend\n'
	.. '\t\t\treturn lo, hi\n'
	.. '\t\tend\n'
	.. '\t\tlocal lo0, hi0 = worldBox(model)\n'
	.. '\t\tmodel:ScaleTo(model:GetScale() * targetH / mesh.Size.Y)\n'
	.. '\t\tlocal lo1, hi1 = worldBox(model)\n'
	.. '\t\tlocal c0, c1 = (lo0 + hi0) / 2, (lo1 + hi1) / 2\n'
	.. '\t\tmodel:PivotTo(model:GetPivot() + Vector3.new(c0.X - c1.X, lo0.Y - lo1.Y, c0.Z - c1.Z))\n', 'feet level')

-- parse check SquirrelSetup
do
	local m = Instance.new('ModuleScript') m.Source = 'if true then return 0 end\n' .. setup.Source m.Parent = game.ServerStorage
	local ok, err = pcall(require, m) m:Destroy()
	log('SquirrelSetup parse', ok, err)
end
-- no registry id may contain "gray" (the twin rule relies on it)
do
	local Reg = require(workspace.SquirrelScripts.SquirrelRegistry)
	local bad = {}
	for _, e in ipairs(Reg.squirrels) do if e.id:lower():find('gray') then bad[#bad + 1] = e.id end end
	log('registry ids with gray:', #bad, table.concat(bad, ','))
end

-- (3) Butterfly Catcher: head stays still
local bf = workspace:FindFirstChild('butterfly_squirrel_color')
if bf then bf:SetAttribute('NoHeadAnim', true) log('butterfly NoHeadAnim', bf:GetAttribute('NoHeadAnim')) end

-- (4) rounded butterfly wings: each wing = a flat disc (Cylinder part, axis turned to vertical), two per side
local holder = workspace.PortoNocciola:FindFirstChild("Butterfly Catcher's butterflies")
if holder then
	local cols = {Color3.fromRGB(70, 140, 235), Color3.fromRGB(245, 150, 40), Color3.fromRGB(250, 215, 60)}
	local function disc(name, d, colour, parent)
		local p = Instance.new('Part') p.Name = name p.Shape = Enum.PartType.Cylinder p.Size = Vector3.new(0.02, d, d)
		p.Color = colour p.Material = Enum.Material.SmoothPlastic
		p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false p.CastShadow = false p.Parent = parent
		return p
	end
	for _, m in ipairs(holder:GetChildren()) do
		if m:IsA('Model') then
			local n = tonumber(m.Name:match('%d+')) or 1
			for _, old in ipairs(m:GetChildren()) do if old.Name ~= 'Body' then old:Destroy() end end
			local body = m.Body
			body.Size = Vector3.new(0.05, 0.05, 0.26)
			for _, side in ipairs({-1, 1}) do
				local fore = disc(side < 0 and 'LeftFore' or 'RightFore', 0.3, cols[n], m)
				fore:SetAttribute('Side', side) fore:SetAttribute('OX', 0.14) fore:SetAttribute('OZ', -0.05)
				local hind = disc(side < 0 and 'LeftHind' or 'RightHind', 0.2, cols[n]:Lerp(Color3.new(1, 1, 1), 0.25), m)
				hind:SetAttribute('Side', side) hind:SetAttribute('OX', 0.1) hind:SetAttribute('OZ', 0.1)
				for _, w in ipairs({fore, hind}) do
					w.CFrame = body.CFrame * CFrame.new(side * w:GetAttribute('OX'), 0, w:GetAttribute('OZ')) * CFrame.Angles(0, 0, math.pi / 2)
				end
			end
		end
	end
	holder.Flutter.Source = [==[
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
	local m = Instance.new('ModuleScript') m.Source = 'if true then return 0 end\n' .. holder.Flutter.Source m.Parent = game.ServerStorage
	local ok, err = pcall(require, m) m:Destroy()
	log('Flutter parse', ok, err, 'wings per butterfly', #holder.Butterfly1:GetChildren() - 1)
end
-- (5) the drone: a little in front of the Drone Flyer, not over his head (her flag): 4 studs ahead, ~1.5 above his head (game size)
do
	local d = workspace.PortoNocciola:FindFirstChild("Drone Flyer's drone")
	local pilot = workspace:FindFirstChild('droneflyer_squirrel_color')
	if d and pilot then
		local cmD = pilot.Squirrel
		local kE = 3.4 / 2.4
		local old = d:GetAttribute('HoverLocal')
		local fwdSign = (old and old.Z < 0) and -1 or 1                 -- keep the side the installer found to be his front
		local hl = Vector3.new(0, 3.2 / kE, fwdSign * 4.0 / kE)
		d:SetAttribute('HoverLocal', hl)
		local dm = d:FindFirstChild('Drone')
		if dm then dm.CFrame = CFrame.new(cmD.CFrame:PointToWorldSpace(hl)) * CFrame.Angles(0, d:GetAttribute('Yaw') or 0, 0) end
		log('drone HoverLocal', old, '->', hl, 'at', dm and dm.Position)
	end
end
game:GetService('ChangeHistoryService'):SetWaypoint('Oct 7 fixes: feet level, _2 ids, butterfly head + wings')
return table.concat(LOG, '\n')
