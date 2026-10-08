-- Oct 6 2026: The Fat Lady Squirrel (operasinger_squirrel) by Fontana del Limone in Piazza del Limone
local id = 'operasinger_squirrel'
local col, gry = workspace:FindFirstChild(id .. '_color'), workspace:FindFirstChild(id .. '_gray')
if not (col and gry) then
	warn('QS@ABORT missing import', col, gry)
	return
end

-- Default placement: South side of fountain on Piazza del Limone paving, facing south into the open piazza
local SPOT = Vector3.new(464.0, -12.0, -803.0)
local WANT = Vector3.new(0, 0, -1) -- facing toward the open piazza

local cm, gm = col.Squirrel, gry.Squirrel
local Bn = {} for _, x in ipairs(col:GetDescendants()) do if x:IsA('Bone') then Bn[x.Name] = x end end

-- Normalize pivot to identity rotation upright
local rel = cm.CFrame:Inverse() * col:GetPivot()
col:PivotTo(CFrame.new(cm.Position) * rel)

local function sz_()
	local hl = cm.CFrame:PointToObjectSpace(Bn.Head.WorldPosition)
	return hl.Z < 0 and 1 or -1
end

-- Rotate around world Y to face WANT
for i = 1, 3 do
	local sz = sz_()
	local R = cm.CFrame - cm.Position
	local fwd = R:VectorToWorldSpace(Vector3.new(0, 0, -sz)) * Vector3.new(1, 0, 1)
	local ang = math.atan2(WANT.X, WANT.Z) - math.atan2(fwd.X, fwd.Z)
	local c = CFrame.new(cm.Position)
	col:PivotTo(c * CFrame.Angles(0, ang, 0) * c:Inverse() * col:GetPivot())
end

local sz = sz_()
local R = cm.CFrame - cm.Position
local k = 3.4 / cm.Size.Y
-- Centered stance
local fc = R:VectorToWorldSpace(Vector3.new(0, 0, sz * -0.3) * k)

-- Raycast down to find ground level under feet
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Exclude
rp.FilterDescendantsInstances = {col, gry, workspace:FindFirstChild('SquirrelTwins')}
local hit = workspace:Raycast(Vector3.new(SPOT.X, -5, SPOT.Z), Vector3.new(0, -15, 0), rp)
local groundY = hit and hit.Position.Y or -12.0

col:PivotTo(col:GetPivot() + Vector3.new(SPOT.X - fc.X - cm.Position.X, groundY + 0.02 - (cm.Position.Y - cm.Size.Y / 2), SPOT.Z - fc.Z - cm.Position.Z))

-- Wire textures
cm:SetAttribute('ColorTexture', cm.TextureID)
cm:SetAttribute('GrayTexture', gm.TextureID)

-- Gray twin
local twins = workspace:FindFirstChild('SquirrelTwins')
if twins then
	gry.Parent = twins
	gry:PivotTo(gry:GetPivot() + Vector3.new(0, -400 - gry:GetPivot().Y, 0))
end

-- Registry entry
local reg = workspace.SquirrelScripts.SquirrelRegistry
local rs = reg.Source
if not rs:find(id, 1, true) then
	local anchor = 'map = "porto"'
	local lastPorto = 1
	while true do
		local found = rs:find(anchor, lastPorto + 1, true)
		if not found then break end
		lastPorto = found
	end
	local lineEnd = rs:find('\n', lastPorto, true)
	local entryEnd = rs:find('},\n', lineEnd, true)
	if entryEnd then
		local insertPos = entryEnd + 3
		local newEntry = string.format('\t\t{id = "%s",    map = "porto", name = "The Fat Lady Squirrel",\n\t\t bio = "The show isn\'t over until she sings. The problem is, she never stops."},\n', id)
		reg.Source = rs:sub(1, insertPos - 1) .. newEntry .. rs:sub(insertPos)
	end
end

local cam = workspace.CurrentCamera
local t = cm.Position + Vector3.new(0, 1.2, 0)
cam.Focus = CFrame.new(t)
cam.CFrame = CFrame.lookAt(cm.Position + WANT * 7 + Vector3.new(1.5, 2.0, 0), t)

game:GetService('ChangeHistoryService'):SetWaypoint('Install ' .. id)
warn('QS@OK installed', id, 'at', cm.Position, 'sole', cm.Position.Y - cm.Size.Y / 2)

