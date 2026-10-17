-- wayfinding1.lua (runner 7, Oct 17 2026): Japan signs, so the bullet train is the obvious way across and every walk has a pointer.
-- Shannon chose "make the train obvious, fill the empty lawns with the planned features, then trim the margins" for "the map feels
-- too big". Kit japan_kit18_wayfinding.fbx (gen_wayfinding.py): sign_post, sign_finger, nobori_banner, map_board - the words go on as
-- SurfaceGuis here. Builds JapanMap.Wayfinding:
--  * fingerposts (a post + one finger per destination, each turned to point at it, the distance in m on it, words on both faces):
--    at the arrival court, the garden bridge's west end, the bamboo maze entrance, the palace court by the pond
--  * a roofed map board at the arrival court: the island drawn in UI with the train line, its three stations, the places, "you are here"
--  * two tall indigo nobori banners at each station's lawn-side corners ("駅 STATION / 新幹線 BULLET TRAIN"), seen from far off
-- Everything stands on the ground found by a ray (the kit and transparent parts skipped); anything a post would overlap is reported.
-- Re-runnable (Wayfinding is rebuilt). Output "QQ WAYFINDING1". Undo: delete JapanMap.Wayfinding.
local SS = game:GetService("ServerStorage")
local J = workspace:FindFirstChild("JapanMap")
local KIT = SS:FindFirstChild("JapanGardenKit")
if not (J and KIT) then print("QQ WAYFINDING1 ABORT: JapanMap or ServerStorage.JapanGardenKit missing") return end
for _, n in ipairs({"sign_post", "sign_finger", "nobori_banner", "map_board"}) do
	if not KIT:FindFirstChild(n) then print("QQ WAYFINDING1 ABORT: the kit has no Model '" .. n .. "' - import japan_kit18_wayfinding.fbx") return end
end
local function key(p) return (p.Name:gsub("%.%d+$", "")) end
local function find(m, name) for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") and key(d) == name then return d end end end
if not (find(KIT.sign_finger, "Finger_Board") and find(KIT.sign_finger, "Finger_Tip") and find(KIT.nobori_banner, "Nobori_Cloth") and find(KIT.map_board, "Board_Face")) then
	print("QQ WAYFINDING1 ABORT: a kit piece is missing a part (Finger_Board / Finger_Tip / Nobori_Cloth / Board_Face)") return
end
local STATIONS = {["Tea Hills"] = Vector3.new(5630, 0, 151), ["Lantern Street"] = Vector3.new(6000, 0, 151), ["Palace Grounds"] = Vector3.new(6379, 0, 151)}
local PLACES = {
	train_LS = {"Bullet train · Lantern St. station", STATIONS["Lantern Street"]}, train_TH = {"Bullet train · Tea Hills station", STATIONS["Tea Hills"]},
	train_PG = {"Bullet train · Palace station", STATIONS["Palace Grounds"]},
	palace = {"Palace & koi pond", Vector3.new(6322, 0, 21)}, market = {"Lantern Street market", Vector3.new(5960, 0, -50)},
	canal = {"Canal garden", Vector3.new(6101, 0, -100)}, church = {"Church", Vector3.new(6115, 0, -262)},
	maze = {"Tea Hills · bamboo maze", Vector3.new(5420, 0, -210)}, lookout = {"Volcano lookout", Vector3.new(5425, 0, -310)},
}
local POSTS = {
	{name = "Arrival", at = Vector3.new(6137, 0, 214), fingers = {"train_LS", "palace", "market", "canal", "maze"}},
	{name = "GardenBridge", at = Vector3.new(6070, 0, -209), fingers = {"church", "palace", "train_LS", "maze"}},
	{name = "MazeGate", at = Vector3.new(5419, 0, -148), fingers = {"train_TH", "market", "canal", "lookout"}},
	{name = "PalaceCourt", at = Vector3.new(6336, 0, -42), fingers = {"train_PG", "canal", "market", "maze"}},
}
local BOARD_AT, BOARD_FACES = Vector3.new(6127, 0, 209), Vector3.new(6145, 0, 222)
local FINGER_TOP, FINGER_STEP, FINGER_ARM = 7.6, 0.9, 2.55                               -- the top finger's height, the step down, the board's centre from the post axis
local C = Color3.fromRGB
local INK, CREAM, INDIGO = C(40, 30, 22), C(255, 246, 225), C(42, 50, 115)
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before wayfinding1") end)
local old = J:FindFirstChild("Wayfinding"); if old then old:Destroy() end
local F = Instance.new("Folder"); F.Name = "Wayfinding"
for _, n in ipairs({"sign_post", "sign_finger", "nobori_banner", "map_board"}) do
	for _, p in ipairs(KIT[n]:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true end end
end
-- the ground under a point: the first hit a player can stand on (Japan's lawns are invisible CanCollide floor parts at y 0 over
-- terrain at -6, so transparency says nothing here), the kit / Wayfinding skipped
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {F, KIT}
local function ground(x, z)
	local o = Vector3.new(x, 80, z)
	for _ = 1, 8 do
		local h = workspace:Raycast(o, Vector3.new(0, -120, 0), rp)
		if not h then return nil end
		if h.Instance == workspace.Terrain or h.Instance.CanCollide then return h.Position.Y, h.Instance end
		o = h.Position - Vector3.new(0, 0.05, 0)
	end
end
local function dress(m, map)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			local k = key(p)
			p.Anchored = true; p.CanTouch = false; p.CastShadow = true
			local d = map[k] or map.default
			p.Material = d[1]; p.Color = d[2]; p.CanCollide = d[3]; p.CanQuery = d[3]
		end
	end
end
local function thinFaces(p)                                                       -- the two big faces of a thin board
	local s = p.Size
	if s.Z <= s.X and s.Z <= s.Y then return Enum.NormalId.Front, Enum.NormalId.Back
	elseif s.X <= s.Y then return Enum.NormalId.Right, Enum.NormalId.Left
	else return Enum.NormalId.Top, Enum.NormalId.Bottom end
end
local function label(parent, text, size, colour, pos, sz, font)
	local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.Position = pos; t.Size = sz
	t.Font = font or Enum.Font.GothamBold; t.TextSize = size; t.TextScaled = size == 0; t.TextColor3 = colour; t.Text = text; t.TextWrapped = true
	t.Parent = parent; return t
end
local function gui(part, face, name, pps)
	local sg = Instance.new("SurfaceGui"); sg.Name = name; sg.Face = face; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = pps; sg.LightInfluence = 0.7; sg.AlwaysOnTop = false; sg.Parent = part; return sg
end
local function overlaps(m, gy)                                                    -- what a piece runs into, the ground it stands in excepted
	local op = OverlapParams.new(); op.FilterType = Enum.RaycastFilterType.Exclude; op.FilterDescendantsInstances = {F, KIT, workspace.Terrain}
	local hit = {}
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			for _, q in ipairs(workspace:GetPartsInPart(p, op)) do
				if q.Transparency < 0.95 and q.Position.Y + q.Size.Y / 2 > (gy or -1e9) + 0.05 then hit[q.Name] = true end
			end
		end
	end
	local t = {}; for k in pairs(hit) do table.insert(t, k) end
	return t
end
local report = {}
-- ---------- fingerposts ----------
local nposts, nfingers = 0, 0
for _, P in ipairs(POSTS) do
	local gy, gi = ground(P.at.X, P.at.Z)
	if not gy then table.insert(report, P.name .. ": NO GROUND - skipped") continue end
	local post = KIT.sign_post:Clone(); post.Name = "Post_" .. P.name
	do local cf, sz = post:GetBoundingBox(); post.WorldPivot = CFrame.new(cf.Position.X, cf.Y - sz.Y / 2 + 0.3, cf.Position.Z) end   -- the pivot at the footing's ground line (base -0.3)
	post:PivotTo(CFrame.new(P.at.X, gy, P.at.Z))
	dress(post, {Post_Wood = {Enum.Material.Wood, C(76, 54, 36), true}, Post_Stone = {Enum.Material.Slate, C(115, 112, 108), true}, default = {Enum.Material.Wood, C(76, 54, 36), true}})
	post.Parent = F; nposts += 1
	local ov = overlaps(post, gy)
	for i, id in ipairs(P.fingers) do
		local place = PLACES[id]
		local f = KIT.sign_finger:Clone(); f.Name = "Finger_" .. P.name .. "_" .. id
		local board, tip = find(f, "Finger_Board"), find(f, "Finger_Tip")
		local t = tip.Position - board.Position; t = Vector3.new(t.X, 0, t.Z).Unit
		f.WorldPivot = CFrame.new(board.Position - t * FINGER_ARM - Vector3.new(0, 0.4, 0))      -- the post axis at the board's bottom
		local d = place[2] - P.at; d = Vector3.new(d.X, 0, d.Z)
		local dist = math.floor(d.Magnitude / 10 + 0.5) * 10
		d = d.Unit
		local yaw = math.atan2(t:Cross(d).Y, t:Dot(d))
		f:PivotTo(CFrame.new(P.at.X, gy + FINGER_TOP - (i - 1) * FINGER_STEP, P.at.Z) * CFrame.Angles(0, yaw, 0))
		dress(f, {Finger_Board = {Enum.Material.Wood, C(150, 110, 68), false}, Finger_Tip = {Enum.Material.Wood, C(150, 110, 68), false}, Finger_Strap = {Enum.Material.Metal, C(46, 43, 40), false}, default = {Enum.Material.Wood, C(150, 110, 68), false}})
		local a, b = thinFaces(board)
		for _, face in ipairs({a, b}) do
			local sg = gui(board, face, "Words" .. face.Name, 50)
			label(sg, string.format("%s   %d m", place[1], dist), 0, INK, UDim2.fromScale(0.05, 0.12), UDim2.fromScale(0.86, 0.76))
		end
		f.Parent = F; nfingers += 1
	end
	table.insert(report, string.format("%s at (%.0f, %.2f, %.0f) on %s, %d fingers%s", P.name, P.at.X, gy, P.at.Z, gi and gi.Name or "?", #P.fingers, #ov > 0 and (" OVERLAPS " .. table.concat(ov, ", ")) or ""))
end
-- ---------- the map board ----------
do
	local gy, gi = ground(BOARD_AT.X, BOARD_AT.Z)
	if gy then
		local b = KIT.map_board:Clone(); b.Name = "MapBoard"
		do local cf, sz = b:GetBoundingBox(); b.WorldPivot = CFrame.new(cf.Position.X, cf.Y - sz.Y / 2 + 0.3, cf.Position.Z) end
		local face = find(b, "Board_Face")
		b:PivotTo(CFrame.new(BOARD_AT.X, gy, BOARD_AT.Z))
		-- turn it so a big face of the board looks at the arrival point
		local a, _ = thinFaces(face)
		local n0 = face.CFrame:VectorToWorldSpace(Vector3.FromNormalId(a)); n0 = Vector3.new(n0.X, 0, n0.Z).Unit
		local want = BOARD_FACES - BOARD_AT; want = Vector3.new(want.X, 0, want.Z).Unit
		local yaw = math.atan2(n0:Cross(want).Y, n0:Dot(want))
		b:PivotTo(CFrame.new(BOARD_AT.X, gy, BOARD_AT.Z) * CFrame.Angles(0, yaw, 0))
		dress(b, {Board_Wood = {Enum.Material.Wood, C(76, 54, 36), true}, Board_Face = {Enum.Material.SmoothPlastic, C(224, 209, 173), true}, Board_Roof = {Enum.Material.Slate, C(60, 60, 68), true}, default = {Enum.Material.Wood, C(76, 54, 36), true}})
		-- the map: world x 5350..6700 across, z 330 (north, top) .. -330 (bottom)
		local sg = gui(face, a, "Map", 50)
		local bg = Instance.new("Frame"); bg.Size = UDim2.fromScale(1, 1); bg.BackgroundColor3 = C(224, 209, 173); bg.BorderSizePixel = 0; bg.Parent = sg
		local function u(x) return 0.03 + 0.94 * (x - 5350) / 1350 end
		local function v(z) return 0.14 + 0.80 * (330 - z) / 660 end
		local sea = Instance.new("Frame"); sea.Position = UDim2.fromScale(0.02, 0.13); sea.Size = UDim2.fromScale(0.96, 0.83); sea.BackgroundColor3 = C(120, 170, 190); sea.BorderSizePixel = 0; sea.Parent = bg
		local isle = Instance.new("Frame"); isle.Position = UDim2.fromScale(u(5370), v(320)); isle.Size = UDim2.fromScale(u(6660) - u(5370), v(-330) - v(320)); isle.BackgroundColor3 = C(130, 170, 95); isle.BorderSizePixel = 0; isle.Parent = bg
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 18); c.Parent = isle end
		label(bg, "日本  ·  JAPAN", 22, INK, UDim2.fromScale(0.03, 0.01), UDim2.fromScale(0.5, 0.11))
		label(bg, "Ride the bullet train: Tea Hills → Lantern Street → Palace Grounds", 11, INK, UDim2.fromScale(0.36, 0.02), UDim2.fromScale(0.62, 0.1))
		local rail = Instance.new("Frame"); rail.Position = UDim2.fromScale(u(5450), v(181)); rail.Size = UDim2.new(u(6560) - u(5450), 0, 0, 3); rail.BackgroundColor3 = INDIGO; rail.BorderSizePixel = 0; rail.Parent = bg
		for name, pos in pairs(STATIONS) do
			local dot = Instance.new("Frame"); dot.AnchorPoint = Vector2.new(0.5, 0.5); dot.Position = UDim2.fromScale(u(pos.X), v(181)); dot.Size = UDim2.fromOffset(9, 9); dot.BackgroundColor3 = INDIGO; dot.BorderSizePixel = 0; dot.Parent = bg
			do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = dot end
			label(bg, name .. " station", 9, INDIGO, UDim2.fromScale(u(pos.X) - 0.09, v(181) - 0.1), UDim2.fromScale(0.18, 0.06))
		end
		for _, pl in ipairs({{"Tea Hills · bamboo maze", 5440, -210}, {"Volcano lookout", 5425, -305}, {"Lantern Street market", 5960, -50}, {"Canal garden", 6101, -80}, {"Church", 6115, -262}, {"Palace & koi pond", 6330, 0}, {"Arrival court", 6145, 240}}) do
			label(bg, pl[1], 9, INK, UDim2.fromScale(u(pl[2]) - 0.1, v(pl[3]) - 0.03), UDim2.fromScale(0.2, 0.06))
		end
		local here = Instance.new("Frame"); here.AnchorPoint = Vector2.new(0.5, 0.5); here.Position = UDim2.fromScale(u(6145), v(222)); here.Size = UDim2.fromOffset(11, 11); here.BackgroundColor3 = C(200, 40, 30); here.BorderSizePixel = 0; here.Parent = bg
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = here end
		label(bg, "you are here", 9, C(200, 40, 30), UDim2.fromScale(u(6145) + 0.02, v(222) - 0.03), UDim2.fromScale(0.2, 0.06))
		b.Parent = F
		local ov = overlaps(b, gy)
		table.insert(report, string.format("MapBoard at (%.0f, %.2f, %.0f) on %s%s", BOARD_AT.X, gy, BOARD_AT.Z, gi and gi.Name or "?", #ov > 0 and (" OVERLAPS " .. table.concat(ov, ", ")) or ""))
	else table.insert(report, "MapBoard: NO GROUND - skipped") end
end
-- ---------- station banners ----------
local nban = 0
local BANNER_SPOTS = {["Palace Grounds"] = {{6350, 141}, {6410, 141}}}                 -- a gatehouse roof fills z 108..126 there: the lawn strip in front of the platform
for name, pos in pairs(STATIONS) do
	for k, dx in ipairs({-34, 34}) do
		local x, z = pos.X + dx, 114                                                  -- 11 off the platform's edge, clear of its roof
		if BANNER_SPOTS[name] then x, z = BANNER_SPOTS[name][k][1], BANNER_SPOTS[name][k][2] end
		local gy, gi = ground(x, z)
		if gy then
			local n = KIT.nobori_banner:Clone(); n.Name = "Banner_" .. name:gsub(" ", "") .. (dx < 0 and "_W" or "_E")
			do local cf, sz = n:GetBoundingBox(); n.WorldPivot = CFrame.new(cf.Position.X, cf.Y - sz.Y / 2 + 0.3, cf.Position.Z) end
			n:PivotTo(CFrame.new(x, gy, z))
			dress(n, {Nobori_Pole = {Enum.Material.Wood, C(140, 150, 92), true}, Nobori_Cloth = {Enum.Material.Fabric, INDIGO, false}, Nobori_Base = {Enum.Material.Slate, C(104, 101, 97), true}, default = {Enum.Material.Wood, C(140, 150, 92), true}})
			local cloth = find(n, "Nobori_Cloth")
			local a, b = thinFaces(cloth)
			for _, face in ipairs({a, b}) do
				local sg = gui(cloth, face, "Words" .. face.Name, 40)
				label(sg, "駅", 0, CREAM, UDim2.fromScale(0.08, 0.04), UDim2.fromScale(0.84, 0.3))
				label(sg, "STATION", 0, CREAM, UDim2.fromScale(0.08, 0.36), UDim2.fromScale(0.84, 0.1))
				label(sg, "新幹線", 0, CREAM, UDim2.fromScale(0.08, 0.52), UDim2.fromScale(0.84, 0.14))
				label(sg, "BULLET TRAIN", 0, CREAM, UDim2.fromScale(0.08, 0.68), UDim2.fromScale(0.84, 0.09))
				label(sg, name:upper(), 0, CREAM, UDim2.fromScale(0.08, 0.82), UDim2.fromScale(0.84, 0.09))
			end
			n.Parent = F; nban += 1
			local ov = overlaps(n, gy)
			if #ov > 0 then table.insert(report, n.Name .. " OVERLAPS " .. table.concat(ov, ", ")) end
		else table.insert(report, name .. " banner at x " .. x .. ": NO GROUND - skipped") end
	end
end
F.Parent = J
task.wait()
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after wayfinding1") end)
for _, r in ipairs(report) do print("QQ WAYFINDING1 " .. r) end
print(string.format("QQ WAYFINDING1 DONE: %d fingerposts with %d fingers, 1 map board, %d station banners in JapanMap.Wayfinding", nposts, nfingers, nban))
