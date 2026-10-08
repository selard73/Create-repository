-- v3 top-down editor camera over the river (moves only the Studio camera) + prints viewport points for the picture
local function P(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end print("QQ " .. table.concat(t, " | ")) end
local cam = workspace.CurrentCamera
P("oldcam", tostring(cam.CFrame), cam.FieldOfView)
local vs = cam.ViewportSize
local aspect = vs.X / vs.Y
local cx, cz, halfW = 175, -95, 300   -- screen horizontal = world z
cam.FieldOfView = 20
local hfov = 2 * math.atan(math.tan(math.rad(10)) * aspect)
local dist = halfW / math.tan(hfov / 2)
cam.CFrame = CFrame.lookAt(Vector3.new(cx, dist, cz), Vector3.new(cx, 0, cz), Vector3.new(1, 0, 0))
P("vs", vs.X, vs.Y, "dist", math.floor(dist))
local function pt(tag, x, z)
	local v = cam:WorldToViewportPoint(Vector3.new(x, 0.2, z))
	P("pt", tag, math.floor(v.X), math.floor(v.Y), x, z)
end
local cl = {{192.5,-266},{186.5,-246},{173,-226},{160.5,-206},{156,-186},{155.8,-166},{155.5,-146},{155.5,-126},{155.8,-106},{155.8,-86},{156,-66},{156.8,-46},{164,-26},{178,-6},{190,14},{190.8,34},{177.5,54}}
for i, c in ipairs(cl) do pt("cl" .. i, c[1], c[2]) end
local function bb(tag, inst)
	if not inst then P("missing", tag) return end
	local cf, sz = inst:GetBoundingBox()
	pt(tag, cf.Position.X, cf.Position.Z)
	P("bb", tag, math.floor(cf.Position.X), math.floor(cf.Position.Z), math.floor(sz.X), math.floor(sz.Z))
end
local props = workspace.Village.Props
bb("bridge", props:FindFirstChild("bridge"))
bb("gallery", workspace:FindFirstChild("PortraitGallery"))
for _, d in ipairs(props:GetChildren()) do if d.Name:lower():find("bridge") then local cf = d:GetBoundingBox() P("bridgeall", d.Name, math.floor(cf.Position.X), math.floor(cf.Position.Z)) end end
pt("spawnV", 196, -36); pt("painter", 187.5, -19.6); pt("lagoon", 114, -180); pt("fish", 165.6, -55)
pt("forestSpawn", 3, 1); pt("square", 260, -95)

for _, w in ipairs(workspace.Boundary.Walls:GetChildren()) do
	if w:IsA("BasePart") and w:GetAttribute("Opens") == nil then
		local a = w.CFrame * Vector3.new(-w.Size.X / 2, 0, 0)
		local b = w.CFrame * Vector3.new(w.Size.X / 2, 0, 0)
		local va, vb = cam:WorldToViewportPoint(Vector3.new(a.X, 0, a.Z)), cam:WorldToViewportPoint(Vector3.new(b.X, 0, b.Z))
		P("rim", w.Name, math.floor(a.X), math.floor(a.Z), math.floor(b.X), math.floor(b.Z), math.floor(va.X), math.floor(va.Y), math.floor(vb.X), math.floor(vb.Y))
	end
end
P("DONE3")
