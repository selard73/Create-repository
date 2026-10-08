-- v1 river survey (READ-ONLY): river parts, centre line, ground under it, what touches it, boundary crossings
local function P(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end print("QQ " .. table.concat(t, " | ")) end
local function r1(v) return math.floor(v * 10 + 0.5) / 10 end
local function V(v) return r1(v.X) .. "," .. r1(v.Y) .. "," .. r1(v.Z) end

-- 1. river parts
local river = {}
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("BasePart") then
		local n = d.Name:lower()
		local pn = d.Parent and d.Parent.Name:lower() or ""
		if n:find("river") or pn:find("river") or n == "bankl" or n == "bankr" then
			river[#river + 1] = d
			P("rpart", d:GetFullName(), d.ClassName, "size", V(d.Size), "pos", V(d.Position), "mat", d.Material.Name, "col", d.Color:ToHex(), "tr", d.Transparency, "cc", d.CanCollide, d:IsA("MeshPart") and d.CollisionFidelity.Name or "")
		end
	end
end
local mn, mx = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9)
for _, p in ipairs(river) do
	local cf, s = p.CFrame, p.Size / 2
	for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
		local w = cf * Vector3.new(sx * s.X, sy * s.Y, sz * s.Z)
		mn = Vector3.new(math.min(mn.X, w.X), math.min(mn.Y, w.Y), math.min(mn.Z, w.Z))
		mx = Vector3.new(math.max(mx.X, w.X), math.max(mx.Y, w.Y), math.max(mx.Z, w.Z))
	end end end
end
P("rbbox", V(mn), V(mx))
if #river == 0 then P("DONE") return end

-- 2. centre line: march along the long axis, raycast down across the short axis, record hits per part
local longX = (mx.X - mn.X) > (mx.Z - mn.Z)
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = river
local L0, L1 = longX and mn.X or mn.Z, longX and mx.X or mx.Z
local S0, S1 = longX and mn.Z or mn.X, longX and mx.Z or mx.X
for a = L0, L1, 20 do
	local segs, cur = {}, nil
	for b = S0 - 2, S1 + 2, 0.5 do
		local o = longX and Vector3.new(a, 60, b) or Vector3.new(b, 60, a)
		local h = workspace:Raycast(o, Vector3.new(0, -120, 0), rp)
		local nm = h and h.Instance.Name or nil
		if nm ~= (cur and cur.n) then
			if cur then cur.b1 = b - 0.5; segs[#segs + 1] = cur end
			cur = nm and {n = nm, b0 = b, y = h.Position.Y} or nil
		end
	end
	if cur then cur.b1 = S1 + 2; segs[#segs + 1] = cur end
	local t = {}
	for _, s in ipairs(segs) do t[#t + 1] = s.n .. "[" .. r1(s.b0) .. ".." .. r1(s.b1) .. " y" .. r1(s.y) .. "]" end
	P("cl", longX and "x" or "z", r1(a), table.concat(t, " "))
end

-- 3. ground under the river + things that touch it (anything whose bbox overlaps the river bbox, grouped by top model)
local ex = RaycastParams.new(); ex.FilterType = Enum.RaycastFilterType.Exclude; ex.FilterDescendantsInstances = river
local grounds = {}
for a = L0, L1, 40 do
	local mid = (S0 + S1) / 2
	for _, b in ipairs({S0 + 10, mid, S1 - 10}) do
		local o = longX and Vector3.new(a, 3, b) or Vector3.new(b, 3, a)
		local h = workspace:Raycast(o, Vector3.new(0, -50, 0), ex)
		if h then local k = h.Instance:GetFullName(); grounds[k] = (grounds[k] or 0) + 1 end
	end
end
for k, n in pairs(grounds) do
	local inst = nil
	P("ground", k, n)
end
local function topOf(d)
	local o = d
	while o.Parent and o.Parent ~= workspace and o.Parent.Parent ~= workspace do o = o.Parent end
	return o
end
local near = {}
local pad = 1
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("BasePart") and not table.find(river, d) and d.Size.Magnitude < 800 then
		local p = d.Position
		if p.X > mn.X - pad and p.X < mx.X + pad and p.Z > mn.Z - pad and p.Z < mx.Z + pad and p.Y < 60 then
			-- only if it is actually over/near the river footprint: raycast down at its centre hits river?
			local h = workspace:Raycast(Vector3.new(p.X, 60, p.Z), Vector3.new(0, -120, 0), rp)
			if h then
				local t = topOf(d)
				local k = t:GetFullName()
				near[k] = near[k] or {n = 0, mn = p, mx = p, ex = d:GetFullName()}
				local e = near[k]; e.n += 1
				e.mn = Vector3.new(math.min(e.mn.X, p.X), math.min(e.mn.Y, p.Y), math.min(e.mn.Z, p.Z))
				e.mx = Vector3.new(math.max(e.mx.X, p.X), math.max(e.mx.Y, p.Y), math.max(e.mx.Z, p.Z))
			end
		end
	end
end
for k, e in pairs(near) do P("over", k, e.n, V(e.mn), V(e.mx), e.ex) end

-- 4. boundary walls tagged Opens, lagoon water facts, map extents of the big folders
for _, d in ipairs(workspace:GetDescendants()) do
	if d:GetAttribute("Opens") ~= nil and d:IsA("BasePart") then P("opens", d:GetFullName(), V(d.Position), V(d.Size)) end
end
local T = workspace.Terrain
P("water", T.WaterColor:ToHex(), T.WaterTransparency, T.WaterWaveSize, T.WaterWaveSpeed, T.WaterReflectance)
for _, c in ipairs(workspace:GetChildren()) do
	if c:IsA("Model") or c:IsA("Folder") then
		local ok, cf, sz = pcall(function() if c:IsA("Model") then return c:GetBoundingBox() end end)
		if ok and cf then P("top", c.Name, c.ClassName, V(cf.Position), V(sz)) else P("top", c.Name, c.ClassName) end
	elseif c:IsA("BasePart") then P("toppart", c.Name, V(c.Position), V(c.Size)) end
end
P("DONE")
