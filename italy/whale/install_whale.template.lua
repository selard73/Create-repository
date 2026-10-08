-- Oct 7 2026: the Porto Nocciola whale. First run: expects the Import 3D result (Model 'whale_color' with MeshPart 'Whale'
-- + bones) somewhere under workspace. Later runs (patch mode): finds workspace.PortoWhale and only updates the settings + script.
-- Tagged output: QW@ lines.
local LENGTH   = %LENGTH%          -- studs nose to flukes
local WATER_Y  = %WATER_Y%         -- sea surface
local ROUTE    = "%ROUTE%"         -- "x,z;x,z;..." closed loop, from the survey
local BLOW_AT  = "%BLOW_AT%"       -- waypoint numbers where it pauses to blow
local SPEED    = %SPEED%           -- studs/s
local BLOW_DUR = %BLOW_DUR%        -- seconds per blow pause
local SOUND_ID = "%SOUND_ID%"      -- her pick (rbxassetid://...), "" = no sound yet
local BED_Y    = %BED_Y%           -- nil, or the sea bed: the belly stays above it
local SRC = [==[
%CLIENT%
]==]

-- route safety: every waypoint and the midpoints between them must be over water, or nothing is touched
do
	local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Include rp.FilterDescendantsInstances = {workspace.Terrain} rp.IgnoreWater = false
	local wp = {}
	for x, z in string.gmatch(ROUTE, "([-%d%.]+),([-%d%.]+)") do table.insert(wp, Vector3.new(tonumber(x), 0, tonumber(z))) end
	local bad = 0
	for i, p in ipairs(wp) do
		local q = wp[(i % #wp) + 1]
		for _, s in ipairs({p, (p + q) / 2}) do
			local h = workspace:Raycast(Vector3.new(s.X, 20, s.Z), Vector3.new(0, -150, 0), rp)
			local ok = h and h.Material == Enum.Material.Water
			if not ok then bad += 1 warn(string.format('QW@ROUTE_LAND %.0f,%.0f -> %s', s.X, s.Z, h and tostring(h.Material) or 'nothing')) end
		end
	end
	if #wp > 0 and bad > 0 then warn('QW@ABORT route touches land at ' .. bad .. ' point(s); fix ROUTE first') return end
	if #wp > 0 then warn('QW@ROUTE ok: ' .. #wp .. ' waypoints over water') end
end

local existing = workspace:FindFirstChild('PortoWhale')
local imported = workspace:FindFirstChild('whale_color', true)
if imported and imported:IsA('MeshPart') then imported = imported.Parent end
local model, mesh
if imported and imported:FindFirstChild('Whale', true) then
	model = imported
	mesh = model:FindFirstChild('Whale', true)
elseif existing then
	model = existing
	mesh = model:FindFirstChildWhichIsA('MeshPart', true)
else
	warn('QW@ABORT nothing to install: import whale_color.fbx first (Import 3D) or have a PortoWhale') return
end
local fresh = (model ~= existing)
local bones = {}
for _, b in ipairs(mesh:GetDescendants()) do if b:IsA('Bone') then bones[b.Name] = b end end
for _, need in ipairs({'Root', 'Head', 'Flukes', 'FlipperL', 'FlipperR'}) do
	if not bones[need] then warn('QW@ABORT missing bone', need) return end
end

-- which way the nose and the back point inside the mesh (object space)
local function obj(b) return mesh.CFrame:PointToObjectSpace(b.WorldPosition) end
local fwd = (obj(bones.Head) - obj(bones.Flukes)).Unit
local sz = mesh.Size
local up = Vector3.new(1, 0, 0)
if sz.Y <= sz.X and sz.Y <= sz.Z then up = Vector3.new(0, 1, 0) elseif sz.Z <= sz.X and sz.Z <= sz.Y then up = Vector3.new(0, 0, 1) end
up = (up - fwd * up:Dot(fwd)).Unit
if (obj(bones.FlipperL) - obj(bones.Root)):Dot(up) > 0 then up = -up end   -- flippers hang below the spine
local back = -fwd
local right = up:Cross(back)
local function along(v) return math.abs(v.X) * sz.X + math.abs(v.Y) * sz.Y + math.abs(v.Z) * sz.Z end
warn('QW@AXES fwd', fwd, 'up', up, 'size', sz, 'length now', along(fwd))

if fresh then
	if existing then existing.Name = 'PortoWhale_old' existing.Parent = game:GetService('ServerStorage') warn('QW@ old PortoWhale parked in ServerStorage') end
	model.Name = 'PortoWhale'
	model.Parent = workspace
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA('BasePart') then d.Anchored = true d.CanCollide = false d.CanQuery = false d.CanTouch = false d.CastShadow = false end
	end
	model:ScaleTo(model:GetScale() * LENGTH / along(fwd))
	sz = mesh.Size
	warn('QW@SCALED length', along(fwd), 'height', along(up))
end

model:SetAttribute('FwdObj', fwd) model:SetAttribute('UpObj', up)
model:SetAttribute('WaterY', WATER_Y) model:SetAttribute('Route', ROUTE) model:SetAttribute('BlowAt', BLOW_AT)
model:SetAttribute('Speed', SPEED) model:SetAttribute('BlowDur', BLOW_DUR)
if BED_Y then model:SetAttribute('BedY', BED_Y) else model:SetAttribute('BedY', nil) end

-- blowhole: top of the head (Blender 0.436 toward the nose, 0.321 up, on a 1.901-long whale)
local k = along(fwd) / 1.901
local att = mesh:FindFirstChild('Blowhole') or Instance.new('Attachment')
att.Name = 'Blowhole'
att.CFrame = CFrame.fromMatrix(fwd * (0.436 * k) + up * (0.321 * k), right, up, back)
att.Parent = mesh
local pe = att:FindFirstChild('Spout') or Instance.new('ParticleEmitter')
-- Spout v3 (Oct 7): a gentle, graceful plume. Round soft particles, no stretching, slower with drag so the top softens; dense so it reads as one stream.
pe.Name = 'Spout'
pe.Texture = 'rbxasset://textures/particles/smoke_main.dds'
pe.Color = ColorSequence.new(Color3.fromRGB(235, 246, 255))
pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.0 * k / 31.6), NumberSequenceKeypoint.new(0.4, 2.0 * k / 31.6), NumberSequenceKeypoint.new(1, 3.2 * k / 31.6)})
pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.5, 0.45), NumberSequenceKeypoint.new(1, 1)})
pe.Lifetime = NumberRange.new(1.6, 1.9)
pe.Speed = NumberRange.new(28 * k / 31.6, 32 * k / 31.6)      -- apex ~ 9-12 studs with the drag
pe.Acceleration = Vector3.new(0, -34, 0)
pe.Drag = 0.6
pe.SpreadAngle = Vector2.new(3, 3)
pe.EmissionDirection = Enum.NormalId.Top
pe.Orientation = Enum.ParticleOrientation.FacingCamera
pe.Squash = NumberSequence.new(0)
pe.Rate = 90
pe.LightEmission = 0.15
pe.LightInfluence = 0.7
pe.Rotation = NumberRange.new(-180, 180) pe.RotSpeed = NumberRange.new(-20, 20)
pe.Enabled = false
pe.Parent = att
local snd = att:FindFirstChild('Blow') or Instance.new('Sound')
snd.Name = 'Blow' snd.SoundId = SOUND_ID snd.Volume = 1.2
snd.RollOffMode = Enum.RollOffMode.InverseTapered snd.RollOffMinDistance = 60 snd.RollOffMaxDistance = 900
snd.Parent = att

-- the client script
local sc = model:FindFirstChild('WhaleClient')
if not sc then sc = Instance.new('Script') sc.Name = 'WhaleClient' sc.RunContext = Enum.RunContext.Client sc.Parent = model end
sc.Source = SRC

-- park it at the first route point so it is not sitting at the origin in edit mode
local x, z = string.match(ROUTE, "([-%d%.]+),([-%d%.]+)")
if x then
	local p = Vector3.new(tonumber(x), WATER_Y - along(up) / 2 + 0.2 * along(up), tonumber(z))
	local x2, z2 = string.match(ROUTE, "[-%d%.]+,[-%d%.]+;([-%d%.]+),([-%d%.]+)")
	local look = x2 and Vector3.new(tonumber(x2), p.Y, tonumber(z2)) or p + Vector3.new(0, 0, -1)
	mesh.CFrame = CFrame.lookAt(p, look) * CFrame.fromMatrix(Vector3.zero, right, up, back):Inverse()
end
warn('QW@OK', fresh and 'installed' or 'patched', 'length', along(fwd), 'height', along(up), 'route points', select(2, ROUTE:gsub(';', '')) + 1, 'blow at', BLOW_AT)
