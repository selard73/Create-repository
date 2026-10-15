-- japan_geo4.lua (job 106 round 4): Studio EDIT mode, after japan_geo3 (b770974). From runner 7's play check of geo3:
-- (1) 19 of the 34 planes had LocalTransparencyModifier 1 on the client: HideFranceFromPorto / HidePortoFromFrance hide by z and skip
--     ONLY JapanMap's descendants, and geo3 had moved the model out to workspace. The model goes back UNDER workspace.JapanMap, still
--     ModelStreamingMode Persistent (geo3 showed all 34 reach the client).
-- (2) the bare planes read paler than the textured terrain water (sky reflection on a lit flat part): Reflectance 0 and the colour shaded
--     - and TUNABLE in play: the model's attributes Shade (x the water colour, default 0.8) and Reflectance (default 0) are applied by
--     HorizonSeaClient on start and whenever they or Terrain.WaterColor change, so the runner can dial them to the water's look live.
-- (3) a thin dark diagonal seam crossed the far planes: the 0.5-stud tile overlaps were coplanar (z-fighting along the triangles).
--     Now the tiles meet edge to edge, and alternate tiles sit 0.05 lower, so no two coplanar faces overlap.
-- Logged in HudBackup.JapanGeo4_log. Output "QQ GEO4".
if game:GetService("RunService"):IsRunning() then print("QQ GEO4 ABORT - Play mode") return end
local HttpService = game:GetService("HttpService")
local SS = game:GetService("ServerStorage")
local J = workspace:FindFirstChild("JapanMap")
if not J then print("QQ GEO4 ABORT - no workspace.JapanMap") return end
local function say(fmt, ...) print("QQ GEO4 " .. string.format(fmt, ...)) end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before JapanGeo4") end)
local log = {}
local SEA = -6
local JAPAN_WATER = Color3.fromRGB(24, 112, 151)                       -- JapanWaterAppearance's colour on the client
local SHADE, REFL = 0.8, 0
local CLIENT = [===[
-- HorizonSeaClient (RunContext Client): the horizon planes wear the terrain's live WaterColor x the model's Shade attribute, with its
-- Reflectance attribute - Japan's blue in Japan (JapanWaterAppearance), the default green anywhere else. Change the attributes in play to tune.
local T = workspace.Terrain
local M = script.Parent
local function paint()
	local c = T.WaterColor
	local s = tonumber(M:GetAttribute("Shade")) or 1
	local r = tonumber(M:GetAttribute("Reflectance")) or 0
	c = Color3.new(math.clamp(c.R * s, 0, 1), math.clamp(c.G * s, 0, 1), math.clamp(c.B * s, 0, 1))
	for _, p in ipairs(M:GetChildren()) do if p:IsA("BasePart") then p.Color = c; p.Reflectance = r end end
end
paint()
T:GetPropertyChangedSignal("WaterColor"):Connect(paint)
M.AttributeChanged:Connect(paint)
M.ChildAdded:Connect(function(p) if p:IsA("BasePart") then task.defer(paint) end end)
]===]
do
	local ok, f, err = pcall(function() return loadstring(CLIENT) end)
	if ok and not f then say("ABORT: HorizonSeaClient does not compile: %s", tostring(err)) return end
end
local removed = 0
for _, holder in ipairs({J, workspace}) do
	local old = holder:FindFirstChild("Horizon sea")
	if old then removed += #old:GetChildren(); old:Destroy() end
end
local M = Instance.new("Model"); M.Name = "Horizon sea"; M.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
M:SetAttribute("Shade", SHADE); M:SetAttribute("Reflectance", REFL)
local IX1, IX2, IZ1, IZ2 = 5150, 7150, -1300, 500                      -- the island's box (the map's bulk x 5200..7100, z -1270..450)
local WX, EX, SZ, NZ = 4000, 13000, -6000, 6000                        -- the planes' reach
local shaded = Color3.new(JAPAN_WATER.R * SHADE, JAPAN_WATER.G * SHADE, JAPAN_WATER.B * SHADE)
local made, k = 0, 0
local function plane(x1, z1, x2, z2)                                     -- tiled edge to edge: a part is at most 2048 studs a side
	local sx, sz = x2 - x1, z2 - z1
	if sx <= 0 or sz <= 0 then return end
	local nx, nz = math.ceil(sx / 2000), math.ceil(sz / 2000)
	local tx, tz = sx / nx, sz / nz
	for i = 0, nx - 1 do
		for j = 0, nz - 1 do
			k += 1
			local p = Instance.new("Part"); p.Name = "HorizonSea"; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
			p.Size = Vector3.new(tx, 1, tz); p.CFrame = CFrame.new(x1 + tx * (i + 0.5), SEA - 0.9 - (k % 2) * 0.05, z1 + tz * (j + 0.5))
			p.Material = Enum.Material.SmoothPlastic; p.Color = shaded; p.Reflectance = REFL; p.Transparency = 0; p.CastShadow = false
			p.Locked = true; p.Parent = M; made += 1
		end
	end
end
plane(WX, IZ2, EX, NZ)                                                  -- north of the island, full width
plane(WX, SZ, EX, IZ1)                                                  -- south, full width
plane(WX, IZ1, IX1, IZ2)                                                -- west strip beside the island
plane(IX2, IZ1, EX, IZ2)                                                -- east strip
local c = Instance.new("Script"); c.Name = "HorizonSeaClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = M
M.Parent = J
say("the horizon: %d old parts removed; JapanMap['Horizon sea'] (Model, Persistent, Shade %.2f, Reflectance %.2f) with %d planes edge to edge at y %.1f / %.2f round the island's box x %d..%d z %d..%d, out to x %d..%d z %d..%d; HorizonSeaClient %d chars",
	removed, SHADE, REFL, made, SEA - 0.9, SEA - 0.95, IX1, IX2, IZ1, IZ2, WX, EX, SZ, NZ, #CLIENT)
log.horizon = {planes = made, parent = "JapanMap", shade = SHADE, reflectance = REFL, island = {IX1, IX2, IZ1, IZ2}, reach = {WX, EX, SZ, NZ}, removed = removed}
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local lv = hb:FindFirstChild("JapanGeo4_log") or Instance.new("StringValue"); lv.Name = "JapanGeo4_log"; lv.Parent = hb
lv.Value = HttpService:JSONEncode(log)
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after JapanGeo4") end)
say("DONE: the horizon model back under JapanMap (the hide scripts skip it), shaded and tunable, the tiles edge to edge (log HudBackup.JapanGeo4_log)")
