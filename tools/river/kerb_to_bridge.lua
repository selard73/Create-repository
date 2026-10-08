-- v75 (+ the Rue de Noisette sign made solid) run the forest-side white kerbs right up to the bridge deck's sides (measured), cap only under the deck itself
local function P(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end print("QQ " .. table.concat(t, " | ")) end
local Q = workspace.River.Quay
local bridge = workspace.Village.Props.bridge
local bps = {}
for _, d in ipairs(bridge:GetDescendants()) do if d:IsA("BasePart") and d.Transparency < 1 then bps[#bps + 1] = d end end
local ip = RaycastParams.new(); ip.FilterType = Enum.RaycastFilterType.Include; ip.FilterDescendantsInstances = bps
-- the deck's footprint over the kerb (x 142.6..144.5), anything below y 2
local zmin, zmax = math.huge, -math.huge
for x = 142.6, 144.5, 0.3 do
	for z = -128, -112, 0.1 do
		local h = workspace:Raycast(Vector3.new(x, -2, z), Vector3.new(0, 4, 0), ip)
		if h then zmin = math.min(zmin, z); zmax = math.max(zmax, z) end
	end
end
P("deck z over the kerb", zmin, zmax)
if zmin == math.huge then P("STOP no deck found") return end
local CHS = game:GetService("ChangeHistoryService")
local rec = CHS:TryBeginRecording("KerbToBridge")
local function span(p) return p.Position.Z - p.Size.Z / 2, p.Position.Z + p.Size.Z / 2 end
local function setZ(p, z0, z1)
	p.Size = Vector3.new(p.Size.X, p.Size.Y, z1 - z0)
	p.CFrame = CFrame.new(p.Position.X, p.Position.Y, (z0 + z1) / 2)
end
local a, b = zmin - 0.02, zmax + 0.02
for _, p in ipairs(Q:GetChildren()) do
	if p.Name == "KerbW" or p.Name == "KerbSkirtW" then
		local z0, z1 = span(p)
		if z1 < -120 then setZ(p, z0, a) else setZ(p, b, z1) end
	elseif p.Name == "CapW" then
		setZ(p, a, b)
	end
end
local solid = 0
for _, d in ipairs(workspace:GetDescendants()) do
	if d.Name == "SignVillage" and d.Parent and d.Parent.Name == "Gates" then
		for _, p in ipairs(d:GetDescendants()) do
			if p:IsA("BasePart") and p.Transparency < 1 then p.CanCollide = true; solid += 1 end
		end
	end
end
P("sign parts solid", solid)
if rec then CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Commit) end
P("kerbs now end at", string.format("%.2f / %.2f", a, b))
local cam = workspace.CurrentCamera
cam.FieldOfView = 55
cam.CFrame = CFrame.lookAt(Vector3.new(150, 1.8, -131), Vector3.new(144, 0.3, -122))
task.wait(4)
cam.CFrame = CFrame.lookAt(Vector3.new(150, 1.8, -109), Vector3.new(144, 0.3, -118))
task.wait(4)
cam.CFrame = CFrame.lookAt(Vector3.new(138, 2.2, -130), Vector3.new(144, 0.4, -121))
