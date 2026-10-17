-- shopfront_mikan1.lua (runner 7, Oct 17 2026): the Mikan greengrocer's FRONT, from Shannon's grocery-store photo (SHOPFRONTS.md #2).
-- The front today (x 6011..6013 back wall, counters out to the lane at x 6001, lane floor 0.46): 13 "Canvas panel"s + 2 "Awning
-- bracket"s + the "Awning front rail" (a canvas canopy 15 out over the lane) - retired to HudBackup.MikanFrontReplaced (attribute
-- MikanWasIn). Kept: the tiled shop roof, counters, vegetables, noren, the 2 paper lanterns, the signs. Added (kit japan_kit21_mikan_front.fbx):
--  * front_awning: a 30-wide grey-tiled awning on a timber frame, wall edge under the shop roof (10.4), 11 deep, posts on the lane
--  * sign_board on the awning's front beam, centred ("八百屋 みかん" / "MIKAN GREENGROCER" as a SurfaceGui)
--  * jar_shelf x2 against the back wall at both ends of the open front
--  * basket_bench x2 on the lane in front of the counters; potted_bamboo x2 at the posts; andon_sign at the south corner;
--    side_banner x2 hanging from the awning at both ends
-- Everything on the lane floor by a ray; the kit's facing checked by the awning's posts (they must be on the lane side).
-- Re-runnable (JapanMap.ShopFronts.Mikan is rebuilt). Output "QQ MIKANFRONT1". Undo: delete ShopFronts.Mikan; HudBackup.MikanFrontReplaced back.
local SS = game:GetService("ServerStorage")
local J = workspace:FindFirstChild("JapanMap")
local M = J and J:FindFirstChild("Outdoor market revision")
local shop = M and M:FindFirstChild("Mikan greengrocer")
local KIT = SS:FindFirstChild("JapanGardenKit")
if not (shop and KIT) then print("QQ MIKANFRONT1 ABORT: the Mikan greengrocer or ServerStorage.JapanGardenKit missing") return end
local PIECES = {"front_awning", "sign_board", "jar_shelf", "basket_bench", "potted_bamboo", "andon_sign", "side_banner"}
for _, n in ipairs(PIECES) do if not KIT:FindFirstChild(n) then print("QQ MIKANFRONT1 ABORT: the kit has no Model '" .. n .. "' - import japan_kit21_mikan_front.fbx") return end end
local function key(p) return (p.Name:gsub("%.%d+$", "")) end
local cf, sz = shop:GetBoundingBox()
local WALL_X = cf.X - sz.X / 2 + 1.5                                                     -- the back wall of the open front (the cedar posts at 6012.7)
local CZ = cf.Z
local OUT = -1                                                                           -- the lane is at -x
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {KIT}
local function ground(x, z)
	local o = Vector3.new(x, 20, z)
	for _ = 1, 8 do
		local h = workspace:Raycast(o, Vector3.new(0, -40, 0), rp)
		if not h then return 0.46 end
		if h.Instance == workspace.Terrain or h.Instance.CanCollide then return h.Position.Y end
		o = h.Position - Vector3.new(0, 0.05, 0)
	end
	return 0.46
end
local C = Color3.fromRGB
local LOOK = {Awn_Tile = {Enum.Material.Slate, C(74, 74, 82)}, Awn_Wood = {Enum.Material.Wood, C(107, 77, 46)}, Sign_Frame = {Enum.Material.Wood, C(56, 38, 26)}, Sign_Panel = {Enum.Material.Wood, C(133, 92, 51)},
	Shelf_Wood = {Enum.Material.Wood, C(102, 71, 43)}, Jar_Amber = {Enum.Material.Glass, C(204, 133, 46)}, Jar_Cream = {Enum.Material.SmoothPlastic, C(230, 214, 168)}, Jar_Red = {Enum.Material.Glass, C(128, 36, 31)}, Jar_Lid = {Enum.Material.Fabric, C(217, 204, 179)},
	Bench_Wood = {Enum.Material.Wood, C(133, 97, 56)}, Basket_Weave = {Enum.Material.Fabric, C(184, 148, 87)}, Goods_Orange = {Enum.Material.SmoothPlastic, C(235, 133, 36)}, Goods_Green = {Enum.Material.SmoothPlastic, C(107, 158, 66)}, Goods_Pink = {Enum.Material.SmoothPlastic, C(230, 158, 179)},
	Pot_Clay = {Enum.Material.Slate, C(92, 66, 51)}, Bam_Culm = {Enum.Material.SmoothPlastic, C(133, 158, 77)}, Bam_Leaf = {Enum.Material.Grass, C(92, 148, 61)},
	Andon_Wood = {Enum.Material.Wood, C(71, 51, 33)}, Andon_Paper = {Enum.Material.Neon, C(245, 235, 204)}, Banner_Rod = {Enum.Material.Wood, C(76, 54, 36)}, Banner_Cloth = {Enum.Material.Fabric, C(41, 48, 97)}, Banner_Crest = {Enum.Material.SmoothPlastic, C(242, 240, 230)}}
local NOCOLLIDE = {Awn_Tile = true, Awn_Wood = false, Bam_Leaf = true, Bam_Culm = true, Banner_Rod = true, Banner_Cloth = true, Banner_Crest = true, Sign_Frame = true, Sign_Panel = true, Jar_Amber = true, Jar_Cream = true, Jar_Red = true, Jar_Lid = true, Goods_Orange = true, Goods_Green = true, Goods_Pink = true, Andon_Paper = true}
local function dress(m)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			local k = key(p); local lk = LOOK[k] or {Enum.Material.Wood, C(92, 69, 46)}
			p.Anchored = true; p.CanTouch = false; p.CastShadow = (k ~= "Bam_Leaf"); p.Material = lk[1]; p.Color = lk[2]
			p.CanCollide = not NOCOLLIDE[k]; p.CanQuery = p.CanCollide
			if k == "Bam_Leaf" then pcall(function() p.DoubleSided = true end) end
		end
	end
end
local YMIN = {side_banner = 1.7}
for _, n in ipairs(PIECES) do
	local src = KIT[n]
	for _, p in ipairs(src:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true end end
	local c, s = src:GetBoundingBox()
	src.WorldPivot = CFrame.new(c.X, c.Y - s.Y / 2 - (YMIN[n] or 0), c.Z)                  -- the pivot at the piece's ground line
end
-- the kit's facing: in the awning the posts (Awn_Wood's lowest part) lie on the +z (lane) side of the tile's wall edge
local flipped
do
	local a = KIT.front_awning
	local c = a:GetBoundingBox()
	local tile
	for _, p in ipairs(a:GetDescendants()) do if p:IsA("BasePart") and key(p) == "Awn_Tile" then tile = p end end
	flipped = tile and (tile.Position.Z > c.Position.Z) or false                           -- the tile's centre sits nearer the wall (z ~5) than the posts (z 10): if it is on the +z side of the box centre the import turned it
end
local KITR = flipped and CFrame.Angles(0, math.pi, 0) or CFrame.new()
local baseYaw = (OUT > 0) and math.pi / 2 or -math.pi / 2                                 -- local +z -> world OUT
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local bak = hb:FindFirstChild("MikanFrontReplaced") or Instance.new("Folder"); bak.Name = "MikanFrontReplaced"; bak.Parent = hb
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before mikanfront1") end)
local retired = 0
for _, p in ipairs(shop:GetDescendants()) do
	if p:IsA("BasePart") and (p.Name == "Canvas panel" or p.Name == "Awning bracket" or p.Name == "Awning front rail") then
		p:SetAttribute("MikanWasIn", p.Parent:GetFullName()); p.Parent = bak; retired += 1
	end
end
local SF = J:FindFirstChild("ShopFronts") or Instance.new("Folder"); SF.Name = "ShopFronts"; SF.Parent = J
local old = SF:FindFirstChild("Mikan"); if old then old:Destroy() end
local F = Instance.new("Folder"); F.Name = "Mikan"
local n = 0
local function place(name, piece, outFromWall, z, yaw, y)
	local m = KIT[piece]:Clone(); m.Name = name
	local gx = WALL_X + OUT * outFromWall
	local gy = y or ground(gx, z)
	m:PivotTo(CFrame.new(gx, gy, z) * CFrame.Angles(0, baseYaw + (yaw or 0), 0) * KITR)
	dress(m); m.Parent = F; n += 1
	return m
end
local awn = place("Awning", "front_awning", 0.0, CZ, 0, 0.46)
-- the sign on the front beam: the beam is 11 out at y 8.1..8.6 - the sign hangs under it, centred
local sign = place("Sign", "sign_board", 10.5, CZ, 0, 5.6)
do
	local panel
	for _, p in ipairs(sign:GetDescendants()) do if p:IsA("BasePart") and key(p) == "Sign_Panel" then panel = p end end
	if panel then
		local faces = {}
		local s = panel.Size
		if s.Z <= s.X and s.Z <= s.Y then faces = {Enum.NormalId.Front, Enum.NormalId.Back} elseif s.X <= s.Y then faces = {Enum.NormalId.Right, Enum.NormalId.Left} else faces = {Enum.NormalId.Top, Enum.NormalId.Bottom} end
		for _, face in ipairs(faces) do
			local sg = Instance.new("SurfaceGui"); sg.Face = face; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 50; sg.LightInfluence = 0.6; sg.Parent = panel
			local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.Size = UDim2.fromScale(0.92, 0.8); t.Position = UDim2.fromScale(0.04, 0.1); t.Font = Enum.Font.Antique; t.TextScaled = true; t.TextColor3 = C(245, 230, 190); t.Text = "八百屋 みかん  ·  MIKAN GREENGROCER"; t.Parent = sg
		end
	end
end
place("ShelfS", "jar_shelf", 0.9, CZ - 11.5, 0); place("ShelfN", "jar_shelf", 0.9, CZ + 11.5, 0)
place("BenchS", "basket_bench", 12.5, CZ - 6.0, 0); place("BenchN", "basket_bench", 12.5, CZ + 6.0, 0)
place("BambooS", "potted_bamboo", 10.2, CZ - 15.2, 0); place("BambooN", "potted_bamboo", 10.2, CZ + 15.2, 0)
place("Andon", "andon_sign", 13.2, CZ - 14.0, 0)
place("BannerS", "side_banner", 2.5, CZ - 14.3, 0, 0.46); place("BannerN", "side_banner", 2.5, CZ + 14.3, 0, 0.46)
F.Parent = SF
task.wait()
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after mikanfront1") end)
local acf, asz = awn:GetBoundingBox()
print(string.format("QQ MIKANFRONT1 DONE: %d pieces in JapanMap.ShopFronts.Mikan (kit %s); awning box x %.1f..%.1f y %.1f..%.1f z %.0f..%.0f; %d canvas parts -> HudBackup.MikanFrontReplaced",
	n, flipped and "turned back" or "as imported", acf.X - asz.X / 2, acf.X + asz.X / 2, acf.Y - asz.Y / 2, acf.Y + asz.Y / 2, acf.Z - asz.Z / 2, acf.Z + asz.Z / 2, retired))
