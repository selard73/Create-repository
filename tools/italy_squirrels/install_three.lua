-- Beppe, Gino, Nonno Reti install (Oct 3 2026 night). Needs <id>_color + _gray imported. Not published.
local CH = game:GetService('ChangeHistoryService')
local reg = workspace.SquirrelScripts.SquirrelRegistry
local twins = workspace:FindFirstChild('SquirrelTwins')
local E = {
	{id = 'fishmonger_squirrel', name = 'Beppe the Fishmonger', spot = Vector3.new(245.2, 0, -645), look = Vector3.new(238, 0, -620),
	 bio = "Opens his stall at dawn and starts shouting prices before the sun is fully up. The seagulls have learned his whole sales pitch and now join in on the chorus.",
	 feet = {{-0.85, -0.82}, {0.32, -0.82}, {-0.85, 0.45}, {0.32, 0.45}}},
	{id = 'deckhand_squirrel', name = 'Gino the Deck Hand', spot = Vector3.new(202.6, 0, -669.8), look = Vector3.new(229, 0, -669.8),
	 bio = "Swabs the deck of the Azzurra six times a day, even on days she never leaves the harbour. Knows forty sailor's knots and has tied most of them in his own tail by accident.",
	 feet = {{-0.52, -0.74}, {-0.21, -0.46}, {0.72, -0.50}, {1.0, -0.19}, {-0.52, -0.46}, {1.0, -0.50}}},
	{id = 'netmender_squirrel', name = 'Nonno Reti', spot = Vector3.new(257.8, 0, -635.8), look = Vector3.new(240, 0, -636),
	 bio = "Has mended every net in the harbour at least twice and remembers each hole by name. Swears the biggest one was made by a whale. The fishermen say it was Beppe.",
	 feet = {{-0.82, -1.48}, {0.59, -1.48}, {-0.82, 0.31}, {0.59, 0.31}}},
}
local rs = reg.Source
local anchor = 'waits very politely while you drip."},\n'
assert(select(2, rs:gsub(anchor:gsub('%p', '%%%0'), '')) == 1, 'registry anchor')
local add = ''
for _, e in ipairs(E) do
	assert(not rs:find(e.id, 1, true), 'already in registry: ' .. e.id)
	add = add .. string.format('\t\t{id = "%s",      map = "porto", name = "%s",\n\t\t bio = "%s"},\n', e.id, e.name, e.bio)
end
local exclude = {workspace:FindFirstChild('ComingSoonWall')}
for _, e in ipairs(E) do table.insert(exclude, workspace:FindFirstChild(e.id .. '_color')); table.insert(exclude, workspace:FindFirstChild(e.id .. '_gray')) end
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = exclude
for _, e in ipairs(E) do
	local col, gry = workspace:FindFirstChild(e.id .. '_color'), workspace:FindFirstChild(e.id .. '_gray')
	assert(col and gry, 'missing import ' .. e.id)
	local cm, gm = col.Squirrel, gry.Squirrel
	cm:SetAttribute('ColorTexture', cm.TextureID); cm:SetAttribute('GrayTexture', gm.TextureID)
	if twins then gry.Parent = twins; gry:PivotTo(gry:GetPivot() + Vector3.new(0, -400 - gry:GetPivot().Y, 0)) else gry:Destroy() end
	local Bn = {}; for _, d in ipairs(col:GetDescendants()) do if d:IsA('Bone') then Bn[d.Name] = d end end
	-- upright (imports arrive tipped), then yaw about world Y until the head faces the look point
	local rel = cm.CFrame:Inverse() * col:GetPivot(); col:PivotTo(CFrame.new(cm.Position) * rel)
	local want = (e.look - e.spot) * Vector3.new(1, 0, 1)
	for i = 1, 2 do
		local face = (Bn.Head.WorldPosition - cm.Position) * Vector3.new(1, 0, 1)
		local a = math.atan2(want.X, want.Z) - math.atan2(face.X, face.Z)
		local c = CFrame.new(cm.Position); col:PivotTo(c * CFrame.Angles(0, a, 0) * c:Inverse() * col:GetPivot())
	end
	local hit = workspace:Raycast(e.spot + Vector3.new(0, 40, 0), Vector3.new(0, -120, 0), rp); assert(hit, 'ground ' .. e.id)
	col:PivotTo(col:GetPivot() + Vector3.new(e.spot.X - cm.Position.X, hit.Position.Y + 0.02 - (cm.Position.Y - cm.Size.Y / 2), e.spot.Z - cm.Position.Z))
	-- feet check at game size (3.4 tall, scaled about the centre, bottom kept)
	local hl = cm.CFrame:PointToObjectSpace(Bn.Head.WorldPosition); local tl = cm.CFrame:PointToObjectSpace(Bn.Tail1.WorldPosition)
	local sz, sx, k = hl.Z < 0 and 1 or -1, tl.X < 0 and 1 or -1, 3.4 / cm.Size.Y
	local R = cm.CFrame - cm.Position; local bottom = cm.Position.Y - cm.Size.Y / 2
	local out = ''
	for _, f in ipairs(e.feet) do
		local w = Vector3.new(cm.Position.X, 0, cm.Position.Z) + R:VectorToWorldSpace(Vector3.new(sx * f[1], 0, sz * f[2]) * k)
		local h = workspace:Raycast(Vector3.new(w.X, bottom + 3, w.Z), Vector3.new(0, -10, 0), rp)
		out = out .. string.format(' %.2f', h and (bottom - h.Position.Y) or 99)
	end
	print('PLACED', e.id, 'bottom', string.format('%.2f', bottom), 'on', hit.Instance.Name, 'foot gaps', out, 'ori', cm.Orientation)
end
local newSrc = rs:gsub((anchor:gsub('%p', '%%%0')), ((anchor .. add):gsub('%%', '%%%%')))
assert(newSrc:find('Nonno Reti', 1, true), 'registry write')
reg.Source = newSrc
CH:SetWaypoint('Beppe, Gino, Nonno Reti')
print('THREE_OK')
