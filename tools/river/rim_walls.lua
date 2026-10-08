-- v4 read-only: rim walls (no Opens) as world + viewport segments for the current camera
local function P(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end print("QQ " .. table.concat(t, " | ")) end
local cam = workspace.CurrentCamera
for _, w in ipairs(workspace:GetDescendants()) do
	if w:IsA("BasePart") and w.Name == "Wall" and w.Size.Y > 100 and w:GetAttribute("Opens") == nil then
		local a = w.CFrame * Vector3.new(-w.Size.X / 2, 0, 0)
		local b = w.CFrame * Vector3.new(w.Size.X / 2, 0, 0)
		local va, vb = cam:WorldToViewportPoint(Vector3.new(a.X, 0, a.Z)), cam:WorldToViewportPoint(Vector3.new(b.X, 0, b.Z))
		P("rim", w:GetFullName(), math.floor(a.X), math.floor(a.Z), math.floor(b.X), math.floor(b.Z), math.floor(va.X), math.floor(va.Y), math.floor(vb.X), math.floor(vb.Y))
	end
end
P("DONE4")
