-- pondfix1.lua (runner 7, Oct 17 2026): the palace koi pond done the canal's way. Shannon: "fix the pond by the royal palace the same
-- way we fixed this waterway". The canal got cut-stone walls in the palace flagstone with a cut-stone coping, a flat dark bed, clear
-- teal water and koi swimming under the surface. The pond (PalaceGrounds."Koi pond set piece", centre (6322, 21.5), water 3.9) had a
-- rounded rock rim (BlenderScenery."Sculpted terrain".JP_Koi_Pond_Shore) over a ragged hole in the court mesh, a sand bowl down to
-- -12, and 8 part koi floating ON the water. This script:
--  * retires the rock rim and the part koi to ServerStorage.HudBackup.PondReplaced (attribute PondWasIn on each)
--  * terrain (backup HudBackup.PondTerrain_pre1, first run only): a flat Slate bed at 0 (3.9 of water) inside r 42; the water row
--    [0..4] kept as water only in cells whose centre is within r 37.6: terrain water rounds off over its outermost cell, so it is
--    flat only inside squares of four water-cell centres - out to r 32, the wall's water face (round 1's face at 35 showed a jagged
--    dark strip) - and it reaches r 40.3 at worst, inside the wall's 40.5 back; the old sand rim above 0 cleared out to r 44
--  * places the kit Model "pond_ring" (gen_pond.py, round 2) as PondRing: the wall (water face r 32, ledge 4.1) and the paving out to r 49.2 in
--    the palace flagstone (Pavement + JM_PhotographicPath, white - the court's own), the coping slabs in the canal's cut stone; all
--    solid, PreciseConvexDecomposition set on the placed parts (a kit setting does not reach clones made in the same call)
--  * PondLife: 10 of Shannon's Meshy koi (kit koi_meshy, 2.4 long, Atomic) circling in slow meanders, their tops 0.2 under the
--    surface (PondLifeScript, client-side, synced by server time)
--  * StarterPlayerScripts.JapanWaterAppearance: the canal's teal water (40,104,112 / 0.68 / 0.2) also round the pond (marker
--    PONDWATER1; backup HudBackup.JapanWaterAppearance_pre_pondwater1). A running client keeps its old copy until it rejoins.
-- Re-runnable (PondRing and PondLife are rebuilt; the terrain backup is kept from the first run). Output "QQ PONDFIX1".
-- Undo: PondRing + PondLife -> delete; HudBackup.PondReplaced's two back to their PondWasIn; Terrain:PasteRegion(HudBackup.PondTerrain_pre1,
-- Vector3int16.new(1567, -4, -8), true); JapanWaterAppearance.Source from HudBackup.JapanWaterAppearance_pre_pondwater1.
local SS = game:GetService("ServerStorage")
local T = workspace.Terrain
local CX, CZ, WATER = 6322, 21.5, 3.9
local R_THR, R_BED, R_CLEAR = 37.6, 42, 44
local KOI_N, KOI_TOP_UNDER, KOI_LONG = 10, 0.2, 2.4
local KIT = SS:FindFirstChild("JapanGardenKit")
local J = workspace:FindFirstChild("JapanMap")
local PG = J and J:FindFirstChild("PalaceGrounds")
local POND = PG and PG:FindFirstChild("Koi pond set piece")
if not (KIT and POND) then print("QQ PONDFIX1 ABORT: ServerStorage.JapanGardenKit or JapanMap.PalaceGrounds.'Koi pond set piece' missing") return end
local SRC = KIT:FindFirstChild("pond_ring")
if not SRC then print("QQ PONDFIX1 ABORT: the kit has no Model 'pond_ring' - import japan_kit13_pond_ring2.fbx") return end
local KOI = KIT:FindFirstChild("koi_meshy")
if not KOI then print("QQ PONDFIX1 ABORT: the kit has no 'koi_meshy' (Shannon's Meshy koi)") return end
local BB = {min = Vector3.new(-49.2, -0.6, -49.2), max = Vector3.new(49.2, 4.7, 49.2)}            -- out_pond/pieces.json (Roblox axes)
local FLAG = {Wall_Stone = true, Apron_Stone = true}
local COPING = Color3.new(0.66, 0.65, 0.61)                                                        -- the canal's Wall_Coping
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local bak = hb:FindFirstChild("PondReplaced") or Instance.new("Folder"); bak.Name = "PondReplaced"; bak.Parent = hb
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before pondfix1") end)
-- ---------- 1. retire the rock rim and the part koi; a re-run rebuilds ours ----------
local retired = {}
local sc = J:FindFirstChild("BlenderScenery") and J.BlenderScenery:FindFirstChild("Sculpted terrain")
for _, d in ipairs({sc and sc:FindFirstChild("JP_Koi_Pond_Shore"), POND:FindFirstChild("Koi fish")}) do
	if d then d:SetAttribute("PondWasIn", d.Parent:GetFullName()); d.Parent = bak; table.insert(retired, d.Name) end
end
for _, n in ipairs({"PondRing", "PondLife"}) do local o = POND:FindFirstChild(n); if o then o:Destroy() end end
-- ---------- 2. the terrain: flat Slate bed at 0, water cells inside r 37.6, the sand rim cleared ----------
local X0, X1, Y0, Y1, Z0, Z1 = 6268, 6376, -16, 8, -32, 76                                         -- on the 4-grid
local reg = Region3.new(Vector3.new(X0, Y0, Z0), Vector3.new(X1, Y1, Z1))
if not hb:FindFirstChild("PondTerrain_pre1") then
	local tr = T:CopyRegion(Region3int16.new(Vector3int16.new(X0 / 4, Y0 / 4, Z0 / 4), Vector3int16.new(X1 / 4 - 1, Y1 / 4 - 1, Z1 / 4 - 1)))
	tr.Name = "PondTerrain_pre1"; tr:SetAttribute("PasteCorner", Vector3.new(X0 / 4, Y0 / 4, Z0 / 4)); tr.Parent = hb
end
local mats, occ = T:ReadVoxels(reg, 4)
local sx, sy, sz = mats.Size.X, mats.Size.Y, mats.Size.Z
local nbed, nwater, nclear = 0, 0, 0
for i = 1, sx do
	for k = 1, sz do
		local x, z = X0 + (i - 0.5) * 4, Z0 + (k - 0.5) * 4
		local r = math.sqrt((x - CX) ^ 2 + (z - CZ) ^ 2)
		if r < R_CLEAR then
			for j = 1, sy do
				local yb = Y0 + (j - 1) * 4
				if yb < 0 then
					if r < R_BED then mats[i][j][k] = Enum.Material.Slate; occ[i][j][k] = 1; nbed += 1 end
				elseif yb == 0 and r < R_THR then
					mats[i][j][k] = Enum.Material.Water; occ[i][j][k] = WATER / 4; nwater += 1
				else
					if mats[i][j][k] ~= Enum.Material.Air then nclear += 1 end
					mats[i][j][k] = Enum.Material.Air; occ[i][j][k] = 0
				end
			end
		end
	end
end
T:WriteVoxels(reg, 4, mats, occ)
print(string.format("QQ PONDFIX1 terrain: %d bed cells (Slate, top 0), %d water cells (surface %.1f, centres inside r %.1f), %d rim cells cleared; backup HudBackup.PondTerrain_pre1", nbed, nwater, WATER, R_THR, nclear))
-- ---------- 3. the ring ----------
for _, p in ipairs(SRC:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true end end
local m = SRC:Clone(); m.Name = "PondRing"
local cf = m:GetBoundingBox()
m.WorldPivot = CFrame.new(cf.Position - (BB.min + BB.max) / 2)
m:PivotTo(CFrame.new(CX, 0, CZ))
local nflag, ncope, nfid = 0, 0, 0
for _, p in ipairs(m:GetDescendants()) do
	if p:IsA("BasePart") then
		local key = p.Name:gsub("_%d+$", "")
		p.Anchored = true; p.CanCollide = true; p.CanQuery = true; p.CanTouch = false; p.CastShadow = true
		if FLAG[key] then
			p.Material = Enum.Material.Pavement; p.Color = Color3.new(1, 1, 1); pcall(function() p.MaterialVariant = "JM_PhotographicPath" end); nflag += 1
		else
			p.Material = Enum.Material.SmoothPlastic; p.Color = COPING; ncope += 1
		end
		if p:IsA("MeshPart") and pcall(function() p.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition end) then nfid += 1 end
	end
end
m.Parent = POND
local rcf, rs = m:GetBoundingBox()
print(string.format("QQ PONDFIX1 ring: PondRing at (%.1f, %.2f, %.1f) %.1f x %.2f x %.1f; %d flagstone pieces (wall + paving), %d coping pieces; precise collision on %d",
	rcf.X, rcf.Y, rcf.Z, rs.X, rs.Y, rs.Z, nflag, ncope, nfid))
-- ---------- 4. the koi ----------
local LF = Instance.new("Folder"); LF.Name = "PondLife"
local rnd = Random.new(1017)
local nkoi = 0
for i = 1, KOI_N do
	local k = KOI:Clone(); k.Name = "Koi" .. i
	for _, p in ipairs(k:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false end end
	local kcf, ksz = k:GetBoundingBox()
	local long = math.max(ksz.X, ksz.Y, ksz.Z)
	if long > 0 then pcall(function() k:ScaleTo(KOI_LONG / long) end) end
	kcf, ksz = k:GetBoundingBox()
	k.WorldPivot = CFrame.new(kcf.Position)                                                        -- the Meshy koi's head is its -Z (as in the canal)
	k.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local R = 8 + (i - 1) * 1.8 + rnd:NextNumber(-0.8, 0.8)                                         -- 8..25: spread over the pond
	local a1 = math.min(rnd:NextNumber(2, 3.5), 28.5 - R - 1.2)                                     -- the koi (2.4 long) stay 3.5 off the r 32 face
	local a2 = math.min(rnd:NextNumber(0.6, 1.2), 28.5 - R - a1)
	k:SetAttribute("PondCX", CX); k:SetAttribute("PondCZ", CZ); k:SetAttribute("PondR", R)
	k:SetAttribute("PondA1", a1); k:SetAttribute("PondA2", a2)
	k:SetAttribute("PondP1", rnd:NextNumber(0, 6.28)); k:SetAttribute("PondP2", rnd:NextNumber(0, 6.28))
	k:SetAttribute("PondSpeed", (i % 2 == 0 and 1 or -1) * rnd:NextNumber(1.0, 1.8) / R)                -- 1.0..1.8 studs a second round the ring
	k:SetAttribute("PondPhase", rnd:NextNumber(0, 6.28)); k:SetAttribute("PondBob", 0.04)
	k:SetAttribute("PondY", WATER - KOI_TOP_UNDER - ksz.Y / 2)
	local th = k:GetAttribute("PondPhase")
	k:PivotTo(CFrame.new(CX + R * math.cos(th), WATER - KOI_TOP_UNDER - ksz.Y / 2, CZ + R * math.sin(th)))
	k.Parent = LF; nkoi += 1
end
local ls = Instance.new("Script"); ls.Name = "PondLifeScript"; ls.RunContext = Enum.RunContext.Client
ls.Source = [==[
-- the koi circle the palace pond in slow meanders (Pond* attributes on each Model): theta = phase + t speed,
-- r = R + A1 sin(3 theta + p1) + A2 sin(7 theta + p2); the nose follows the way, the heading eased; client-side, synced by server time
local RunService = game:GetService("RunService")
local folder = script.Parent
local yaws = {}
RunService.Heartbeat:Connect(function(dt)
	local t = workspace:GetServerTimeNow()
	for _, m in ipairs(folder:GetChildren()) do
		if m:IsA("Model") and m:GetAttribute("PondR") then
			local cx, cz, R = m:GetAttribute("PondCX"), m:GetAttribute("PondCZ"), m:GetAttribute("PondR")
			local a1, a2 = m:GetAttribute("PondA1") or 0, m:GetAttribute("PondA2") or 0
			local p1, p2 = m:GetAttribute("PondP1") or 0, m:GetAttribute("PondP2") or 0
			local sp, ph = m:GetAttribute("PondSpeed"), m:GetAttribute("PondPhase")
			local th = ph + t * sp
			local r = R + a1 * math.sin(3 * th + p1) + a2 * math.sin(7 * th + p2)
			local dr = (3 * a1 * math.cos(3 * th + p1) + 7 * a2 * math.cos(7 * th + p2)) * sp
			local c, s = math.cos(th), math.sin(th)
			local dx, dz = dr * c - r * s * sp, dr * s + r * c * sp
			local bob = math.sin(t * 1.3 + ph * 3) * (m:GetAttribute("PondBob") or 0)
			local pos = Vector3.new(cx + r * c, m:GetAttribute("PondY") + bob, cz + r * s)
			local want = yaws[m]
			if dx * dx + dz * dz > 1e-8 then want = math.atan2(-dx, -dz) end                     -- the yaw whose -Z points along (dx, dz)
			if want then
				local cur = yaws[m] or want
				local diff = (want - cur + math.pi) % (2 * math.pi) - math.pi
				cur = cur + diff * math.min(1, dt * 3)                                             -- eased: gentle turns
				yaws[m] = cur
				m:PivotTo(CFrame.new(pos) * CFrame.Angles(0, cur, 0) * CFrame.Angles(0, 0, 0.06 * bob))
			end
		end
	end
end)
]==]
ls.Parent = LF
LF.Parent = POND
print(string.format("QQ PONDFIX1 koi: %d Meshy koi in PondLife (Atomic, tops %.1f under the surface, rings r 8..25), PondLifeScript (client)", nkoi, KOI_TOP_UNDER))
-- ---------- 5. the canal's teal water round the pond too ----------
local sps = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
local wa = sps and sps:FindFirstChild("JapanWaterAppearance")
local ANCHOR = [==[p.Position.Z>-230 and p.Position.Z<110 --[[CANALWATER1: clear water over the canal's dark bed]]]==]
local water = "not patched"
if not (wa and wa:IsA("LuaSourceContainer")) then
	water = "JapanWaterAppearance not found - NOT patched"
elseif wa.Source:find("PONDWATER1", 1, true) then
	water = "already patched (PONDWATER1)"
else
	local src = wa.Source
	local n, pos = 0, 1
	while n < 10 do local f = src:find(ANCHOR, pos, true); if not f then break end; n += 1; pos = f + #ANCHOR end
	if n ~= 1 then
		water = string.format("anchor found %d times (want 1) - NOT patched", n)
	else
		local f = src:find(ANCHOR, 1, true)
		local out = src:sub(1, f + #ANCHOR - 1) .. [==[ or (inside and p.Position.X>6262 and p.Position.X<6382 and p.Position.Z>-38 and p.Position.Z<81) --[[PONDWATER1: the palace pond too]] ]==] .. src:sub(f + #ANCHOR)
		local chk = Instance.new("ModuleScript"); chk.Source = "return function()\n" .. out .. "\nend"   -- compiles it without running it
		local ok, err = pcall(require, chk)
		if not ok then
			water = "the patched script does not compile (" .. tostring(err) .. ") - NOT patched"
		else
			local bk = wa:Clone(); bk.Name = "JapanWaterAppearance_pre_pondwater1"; bk.Disabled = true; bk.Parent = hb
			wa.Source = out
			water = string.format("patched %d -> %d bytes (teal 40,104,112 / 0.68 / 0.2 inside x 6262..6382, z -38..81); backup HudBackup.JapanWaterAppearance_pre_pondwater1", #src, #out)
		end
	end
end
print("QQ PONDFIX1 water look: " .. water)
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after pondfix1") end)
print(string.format("QQ PONDFIX1 DONE: retired %s -> HudBackup.PondReplaced; publish, then restart servers (the water look is a StarterPlayerScripts change)",
	#retired > 0 and table.concat(retired, ", ") or "nothing (already retired)"))
