-- v11 read-only: squirrels (and props) near the river - feet vs the ground under them now; camera on the spy
local function P(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end print("QQ " .. table.concat(t, " | ")) end
local function r2(v) return math.floor(v * 100 + 0.5) / 100 end
for _, m in ipairs(workspace:GetChildren()) do
	if m:IsA("Model") and m.Name:find("_color") then
		local cf, sz = m:GetBoundingBox()
		local p = cf.Position
		if p.X > 125 and p.X < 225 and p.Z > -230 and p.Z < 30 then
			local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {m}
			local out = {}
			for _, o in ipairs({{0, 0}, {-0.6, 0}, {0.6, 0}, {0, -0.6}, {0, 0.6}}) do
				local h = workspace:Raycast(Vector3.new(p.X + o[1], p.Y + 4, p.Z + o[2]), Vector3.new(0, -20, 0), rp)
				out[#out + 1] = h and (h.Instance.Name .. "@" .. r2(h.Position.Y)) or "none"
			end
			-- the mesh's real underside: raycast up from below into the model
			local ip = RaycastParams.new(); ip.FilterType = Enum.RaycastFilterType.Include; ip.FilterDescendantsInstances = {m}
			local up = workspace:Raycast(Vector3.new(p.X, p.Y - 10, p.Z), Vector3.new(0, 20, 0), ip)
			P("sq", m.Name, r2(p.X), r2(p.Z), "bboxBottom", r2(p.Y - sz.Y / 2), "feet", up and r2(up.Position.Y) or "?", table.concat(out, " "))
		end
	end
end
local spy = workspace:FindFirstChild("spy_squirrel_color")
if spy then
	local cf = spy:GetBoundingBox()
	local cam = workspace.CurrentCamera
	cam.FieldOfView = 50
	cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(-9, 3, 6), cf.Position + Vector3.new(0, -0.8, 0))
end
P("DONE11")
