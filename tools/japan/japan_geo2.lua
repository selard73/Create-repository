-- japan_geo2.lua (job 106 round 2): Studio EDIT mode, after japan_geo1. From runner 7's three findings and the probe106b numbers:
-- (1) the paler rectangle in the near water was a DEPTH change - Codex's sea basin bed is y -26..-35, our fill's sand bed -58: the deep
--     water below y -30 across the fill becomes sand, so the bed is one depth;
-- (2) the sea's hard edge at the horizon: the water is carried on to z 1300 and x 7800 (the island's north shore is at z ~450, so the
--     edge moves 850 studs out, into the fog - FogEnd 1100), and beyond that flat water-coloured parts run to 3000 studs so no edge
--     shows anywhere;
-- (3) the canal's bright end face: the water ends at the manifest box (z -221) under the north bridge with dry foundation (y 0) beyond,
--     so a stone WEIR goes across the canal there - the water ends against stone, as a canal should;
-- (4) the lake stair's dark band is its own shadow: CastShadow off on the treads. Logged in HudBackup.JapanGeo2_log. "QQ GEO2".
if game:GetService("RunService"):IsRunning() then print("QQ GEO2 ABORT - Play mode") return end
local HttpService = game:GetService("HttpService")
local SS = game:GetService("ServerStorage")
local T = workspace.Terrain
local J = workspace:FindFirstChild("JapanMap")
if not J then print("QQ GEO2 ABORT - no workspace.JapanMap") return end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before JapanGeo2") end)
local log = {}
local function say(fmt, ...) print("QQ GEO2 " .. string.format(fmt, ...)) end
-- the channel writer from geo1: air -> water up to an exact level, or air -> a solid
local function fillAir(x1, y1, z1, x2, y2, z2, mat, level)
	local cells = 0
	local step = 256
	local gy1, gy2 = math.floor(y1 / 4) * 4, math.ceil(y2 / 4) * 4
	local gx1, gx2, gz1, gz2 = math.floor(x1 / 4) * 4, math.ceil(x2 / 4) * 4, math.floor(z1 / 4) * 4, math.ceil(z2 / 4) * 4
	local water = (mat == Enum.Material.Water)
	for cx = gx1, gx2 - 0.01, step do
		for cz = gz1, gz2 - 0.01, step do
			local r = Region3.new(Vector3.new(cx, gy1, cz), Vector3.new(math.min(cx + step, gx2), gy2, math.min(cz + step, gz2)))
			local ch = T:ReadVoxelChannels(r, 4, {"SolidMaterial", "SolidOccupancy", "LiquidOccupancy"})
			local SM, SO, LO = ch.SolidMaterial, ch.SolidOccupancy, ch.LiquidOccupancy
			local changed = false
			for ix = 1, #SO do
				for iy = 1, #SO[ix] do
					local share = math.clamp((level - (gy1 + (iy - 1) * 4)) / 4, 0, 1)
					if share > 0.05 then
						for iz = 1, #SO[ix][iy] do
							if SO[ix][iy][iz] == 0 and LO[ix][iy][iz] == 0 then
								if water then LO[ix][iy][iz] = share else SM[ix][iy][iz] = mat; SO[ix][iy][iz] = share end
								changed = true; cells += 1
							end
						end
					end
				end
			end
			if changed then
				if water then T:WriteVoxelChannels(r, 4, {LiquidOccupancy = LO}) else T:WriteVoxelChannels(r, 4, {SolidMaterial = SM, SolidOccupancy = SO}) end
			end
			task.wait()
		end
	end
	return cells
end
-- (1) the bed: deep water (below BED) becomes sand across the fill box
local BED = -30
local function raiseBed(x1, z1, x2, z2)
	local cells = 0
	local step = 256
	local gy1, gy2 = -64, BED
	for cx = math.floor(x1 / 4) * 4, x2 - 0.01, step do
		for cz = math.floor(z1 / 4) * 4, z2 - 0.01, step do
			local r = Region3.new(Vector3.new(cx, gy1, cz), Vector3.new(math.min(cx + step, math.ceil(x2 / 4) * 4), gy2, math.min(cz + step, math.ceil(z2 / 4) * 4)))
			local ch = T:ReadVoxelChannels(r, 4, {"SolidMaterial", "SolidOccupancy", "LiquidOccupancy"})
			local SM, SO, LO = ch.SolidMaterial, ch.SolidOccupancy, ch.LiquidOccupancy
			local changed = false
			for ix = 1, #SO do for iy = 1, #SO[ix] do for iz = 1, #SO[ix][iy] do
				if SO[ix][iy][iz] == 0 and LO[ix][iy][iz] > 0 then SM[ix][iy][iz] = Enum.Material.Sand; SO[ix][iy][iz] = 1; LO[ix][iy][iz] = 0; changed = true; cells += 1 end
			end end end
			if changed then T:WriteVoxelChannels(r, 4, {SolidMaterial = SM, SolidOccupancy = SO, LiquidOccupancy = LO}) end
			task.wait()
		end
	end
	return cells
end
local SEA = -6
local X1, X2, Z1, Z2 = 4750, 7400, -1500, 900          -- geo1's box
local NX2, NZ2 = 7800, 1300                             -- round 2: farther out east and north
local bedCells = raiseBed(X1, Z1, X2, Z2)
say("the bed: %d deep water cells below y %d became sand (one depth with Codex's basin, bed -26..-35)", bedCells, BED)
-- (2) more sea: the new bands, sand bed at BED then water to the surface
local bandN = fillAir(X1, BED - 4, Z2, NX2, BED, NZ2, Enum.Material.Sand, BED) + fillAir(X2, BED - 4, Z1, NX2, BED, Z2, Enum.Material.Sand, BED)
local seaN = fillAir(X1, BED, Z2, NX2, SEA, NZ2, Enum.Material.Water, SEA) + fillAir(X2, BED, Z1, NX2, SEA, Z2, Enum.Material.Water, SEA)
say("more sea: north band z %d..%d and east band x %d..%d - %d sand cells, %d water cells", Z2, NZ2, X2, NX2, bandN, seaN)
-- the horizon: flat water-coloured parts beyond the terrain water, 0.4 under its surface, out to 3000 studs
local HF = J:FindFirstChild("Horizon sea") or Instance.new("Folder"); HF.Name = "Horizon sea"; HF.Parent = J
HF:ClearAllChildren()
local wc = T.WaterColor
local function plane(cx, cz, sx, sz)
	local p = Instance.new("Part"); p.Name = "HorizonSea"; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.Size = Vector3.new(sx, 1, sz); p.CFrame = CFrame.new(cx, SEA - 0.9, cz); p.Material = Enum.Material.SmoothPlastic
	p.Color = wc; p.Reflectance = 0.35; p.Transparency = 0.05; p.CastShadow = false; p.Parent = HF
end
local FAR_X, FAR_Z1, FAR_Z2 = 9400, -2800, 2800
plane((X1 + NX2) / 2, (NZ2 - 20 + FAR_Z2) / 2, NX2 - X1, FAR_Z2 - (NZ2 - 20))            -- north
plane((X1 + NX2) / 2, (FAR_Z1 + Z1 + 20) / 2, NX2 - X1, (Z1 + 20) - FAR_Z1)             -- south
plane((NX2 - 20 + FAR_X) / 2, (FAR_Z1 + FAR_Z2) / 2, FAR_X - (NX2 - 20), FAR_Z2 - FAR_Z1)  -- east
say("the horizon: three flat sea parts (colour %s) to x %d and z %d..%d, 0.4 under the water's surface", tostring(wc), FAR_X, FAR_Z1, FAR_Z2)
-- (3) the canal's weir at its north end (the water's end at z -221 under the north bridge; dry foundation beyond)
local WF = J:FindFirstChild("Canal weir") or Instance.new("Folder"); WF.Name = "Canal weir"; WF.Parent = J
WF:ClearAllChildren()
local STONE = Color3.fromRGB(128, 122, 112)
local function stone(cx, cy, cz, sx, sy, sz, name)
	local p = Instance.new("Part"); p.Name = name; p.Anchored = true; p.CanCollide = true; p.Size = Vector3.new(sx, sy, sz); p.CFrame = CFrame.new(cx, cy, cz)
	p.Material = Enum.Material.Slate; p.Color = STONE; p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth; p.Parent = WF
	return p
end
stone(6101, -0.6, -222.5, 30, 5.2, 3, "Weir")                     -- y -3.2..2.0, across the canal (x 6086..6116), 0.7 above the water (1.3)
stone(6101, 2.3, -221.2, 30, 0.6, 1.2, "Weir lip")               -- the lip the water meets
for i = 0, 5 do stone(6088 + i * 5.2, 2.45, -222.6, 2.4, 0.9, 1.6, "Weir stone") end   -- a row of capstones
say("the canal's north end: a stone weir across x 6086..6116 at z -221..-224 (top y 2.0, the water at 1.3 ends against it)")
-- (4) the lake stair's shadow
local shadows = 0
for _, p in ipairs(J:GetDescendants()) do
	if p:IsA("BasePart") and (p.Name == "Lake swim exit tread" or p.Name == "Continuous underwater stair support" or p.Name == "Promenade approach tread") and p.CastShadow then p.CastShadow = false; shadows += 1 end
end
say("lake stair: CastShadow off on %d parts", shadows)
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local lv = hb:FindFirstChild("JapanGeo2_log") or Instance.new("StringValue"); lv.Name = "JapanGeo2_log"; lv.Parent = hb
log.bed = {level = BED, cells = bedCells}; log.sea = {x2 = NX2, z2 = NZ2, sand = bandN, water = seaN}; log.horizon = {FAR_X, FAR_Z1, FAR_Z2}; log.weir = "JapanMap.Canal weir"; log.shadows = shadows
lv.Value = HttpService:JSONEncode(log)
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after JapanGeo2") end)
say("DONE: bed raised, sea extended, horizon parts, the canal weir, the stair's shadow off (log HudBackup.JapanGeo2_log)")
