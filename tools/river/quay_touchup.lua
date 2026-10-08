-- v69 forest-side quay touch-up: the white kerb reaches down into the ground on the land side (no stone wall showing
-- from the forest), and a white capstone runs under the bridge deck, just below the planks (measured)
local function P(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end print("QQ " .. table.concat(t, " | ")) end
local Q = workspace.River:FindFirstChild("Quay")
if not Q then P("STOP no quay") return end
local bridge = workspace.Village.Props:FindFirstChild("bridge")
local bp = {}
for _, d in ipairs(bridge:GetDescendants()) do if d:IsA("BasePart") then bp[#bp + 1] = d end end
local ip = RaycastParams.new(); ip.FilterType = Enum.RaycastFilterType.Include; ip.FilterDescendantsInstances = bp
local low = math.huge
for x = 142.6, 144.6, 0.25 do
	for z = -124.5, -115.5, 0.75 do
		local h = workspace:Raycast(Vector3.new(x, -2, z), Vector3.new(0, 8, 0), ip)
		if h then low = math.min(low, h.Position.Y) end
	end
end
P("deck underside min over the wall", low)
local capTop = math.clamp(low - 0.04, 0.32, 0.75)
local CHS = game:GetService("ChangeHistoryService")
local rec = CHS:TryBeginRecording("QuayTouchup")
local kerbCol, n = nil, 0
for _, p in ipairs(Q:GetChildren()) do
	if p.Name == "KerbW" then
		kerbCol = p.Color
		local top = p.Position.Y + p.Size.Y / 2
		local newBottom = -1.0
		p.Size = Vector3.new(p.Size.X, top - newBottom, p.Size.Z)
		p.CFrame = CFrame.new(p.Position.X, (top + newBottom) / 2, p.Position.Z)
		n += 1
	elseif p.Name == "CapW" then p:Destroy() end
end
local cap = Instance.new("Part"); cap.Name = "CapW"; cap.Anchored = true
cap.Material = Enum.Material.Limestone; cap.Color = kerbCol or Color3.fromRGB(196, 186, 168)
cap.TopSurface = Enum.SurfaceType.Smooth; cap.BottomSurface = Enum.SurfaceType.Smooth
local x0, x1, z0, z1, y0 = 143.95, 144.5, -125, -115, -1.0
cap.Size = Vector3.new(x1 - x0, capTop - y0, z1 - z0)
cap.CFrame = CFrame.new((x0 + x1) / 2, (capTop + y0) / 2, (z0 + z1) / 2)
cap.Parent = Q
if rec then CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Commit) end
P("kerbs deepened", n, "cap top", string.format("%.2f", capTop))
local cam = workspace.CurrentCamera
cam.FieldOfView = 55
cam.CFrame = CFrame.lookAt(Vector3.new(152, 1.5, -132), Vector3.new(144, 0, -121))
task.wait(4)
cam.CFrame = CFrame.lookAt(Vector3.new(132, 2.5, -134), Vector3.new(144, 0.3, -122))
