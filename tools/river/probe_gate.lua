-- v64 read-only: the parts of the Gates folder by the bridge (x 125..150, z -135..-105) + ground under each
local function P(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end print("QQ " .. table.concat(t, " | ")) end
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {workspace.Terrain}; rp.IgnoreWater = true
for _, g in ipairs(workspace:GetDescendants()) do
	if g.Name == "Gates" then
		for _, c in ipairs(g:GetChildren()) do
			local cf, s
			if c:IsA("Model") then cf, s = c:GetBoundingBox() elseif c:IsA("BasePart") then cf, s = c.CFrame, c.Size end
			if cf and cf.Position.X > 120 and cf.Position.X < 155 and cf.Position.Z > -140 and cf.Position.Z < -100 then
				local p = cf.Position
				local h = workspace:Raycast(Vector3.new(p.X, 10, p.Z), Vector3.new(0, -30, 0), rp)
				P("gate", c:GetFullName(), c.ClassName, string.format("%.1f,%.2f,%.1f", p.X, p.Y, p.Z), string.format("%.1f,%.1f,%.1f", s.X, s.Y, s.Z), "ground", h and string.format("%.2f", h.Position.Y) or "-")
			end
		end
	end
end
for x = 136, 150, 1 do
	local h = workspace:Raycast(Vector3.new(x, 10, -120), Vector3.new(0, -30, 0), rp)
	P("gz", x, h and string.format("%.2f", h.Position.Y) or "-")
end
local cam = workspace.CurrentCamera
cam.CFrame = CFrame.lookAt(Vector3.new(135, 6, -106), Vector3.new(143, 0, -120))
