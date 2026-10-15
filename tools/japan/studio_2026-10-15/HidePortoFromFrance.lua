-- HidePortoFromFrance (Oct 7 2026, Shannon: "we made the French scenery invisible when you are looking from the Italian
-- side, but you can still see the Italian side from the French side"): the mirror of HideFranceFromPorto. While you are
-- inside the French map (north of its south walls, z > -260) nothing of Porto Nocciola is drawn for you: everything in
-- workspace.PortoNocciola, plus anything south of z -560 (the Porto squirrels, the whales, the luggage cart on the shore,
-- the pizza dough ...) - parts, signs (Surface/Billboard GUIs) and effects. Restored as soon as you go south of z -270,
-- i.e. into the gorge, so the boat ride still sees Porto below the falls. Never hidden: workspace.SouthGorge (the ridge,
-- the gorge, the aqueduct, the falls), characters. Terrain cannot be hidden.
local Players = game:GetService('Players')
local player = Players.LocalPlayer
local LINE_Z = -560          -- south of this line is Porto
local IN_FRANCE_Z = -260     -- hide when you are north of this (inside the French map)
local OUT_Z = -270           -- show again once you are south of this (in the gorge or beyond)
local function skipRoots() return {workspace:FindFirstChild('SouthGorge'), workspace.CurrentCamera} end
local hidden = {}
local active = false
local function posOf(inst)
	if inst:IsA('BasePart') then return inst.Position end
	local p = inst.Parent
	if inst:IsA('SurfaceGui') or inst:IsA('BillboardGui') then local a = inst.Adornee or p if a and a:IsA('BasePart') then return a.Position end if a and a:IsA('Attachment') then return a.WorldPosition end return nil end
	if p and p:IsA('BasePart') then return p.Position end
	if p and p:IsA('Attachment') then return p.WorldPosition end
	return nil
end
local EFFECT = {ParticleEmitter = true, Beam = true, Trail = true, Fire = true, Smoke = true, Sparkles = true, PointLight = true, SpotLight = true, SurfaceLight = true}
local function skipped(inst, roots)
	local japan=workspace:FindFirstChild("JapanMap")
	if japan and inst:IsDescendantOf(japan) then return true end

	for _, r in ipairs(roots) do if r and inst:IsDescendantOf(r) then return true end end
	local m = inst:FindFirstAncestorOfClass('Model')
	while m do if m:FindFirstChildOfClass('Humanoid') then return true end m = m.Parent and m.Parent:FindFirstAncestorOfClass('Model') end
	return false
end
local function hideOne(inst, roots, porto)
	if hidden[inst] ~= nil then return end
	local isPart = inst:IsA('BasePart')
	local isGui = inst:IsA('SurfaceGui') or inst:IsA('BillboardGui')
	local isFx = EFFECT[inst.ClassName]
	if not (isPart or isGui or isFx) then return end
	if not (porto and inst:IsDescendantOf(porto)) then
		local p = posOf(inst)
		if not p or p.Z >= LINE_Z then return end
	end
	if skipped(inst, roots) then return end
	if isPart then hidden[inst] = inst.LocalTransparencyModifier inst.LocalTransparencyModifier = 1
	else hidden[inst] = inst.Enabled inst.Enabled = false end
end
local function hideAll()
	local roots, porto = skipRoots(), workspace:FindFirstChild('PortoNocciola')
	for i, inst in ipairs(workspace:GetDescendants()) do
		if not active then break end
		hideOne(inst, roots, porto)
		if i % 3000 == 0 then task.wait() end
	end
end
local function restoreAll()
	for inst, prev in pairs(hidden) do
		if inst.Parent then
			if inst:IsA('BasePart') then inst.LocalTransparencyModifier = prev else inst.Enabled = prev end
		end
	end
	hidden = {}
end
workspace.DescendantAdded:Connect(function(inst)
	if active then task.defer(function() if active then hideOne(inst, skipRoots(), workspace:FindFirstChild('PortoNocciola')) end end) end
end)
while true do
	task.wait(0.5)
	local c = player.Character
	local r = c and c:FindFirstChild('HumanoidRootPart')
	if r then
		local z = r.Position.Z
		if not active and z > IN_FRANCE_Z then active = true task.spawn(hideAll)
		elseif active and z < OUT_Z then active = false restoreAll() end
	end
end
