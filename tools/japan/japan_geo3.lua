-- japan_geo3.lua (job 106 round 3): Studio EDIT mode, after japan_geo2 (bee201f). From runner 7's play check of geo2:
-- (1) the HORIZON parts were painted Edit's WaterColor (52,104,78) while JapanWaterAppearance paints the client's water (24,112,151);
--     only 2 of the 7 reached the client (streaming), and the client's fog in Japan is 99999..100000, so from 90 up the streamed terrain
--     sea ended in a stepped silhouette against the sky. Now: a MODEL "Horizon sea" directly under workspace with ModelStreamingMode
--     Persistent (every client holds all its parts, always), its planes starting at the ISLAND'S box (x 5150..7150, z -1300..500) and
--     running under the terrain sea out to x 13000 and z +-6000 (x 4000 on the west, toward France - 3000+ studs from Porto, under its
--     fog), 0.9 under the water's surface so the real water draws over them wherever it is streamed and they carry on where it is not;
--     painted (24,112,151) here and, on each client, the terrain's live WaterColor by a small client script in the model (HorizonSeaClient)
--     - so they match Japan's blue in Japan and France's green anywhere else.
-- (2) the small blue sliver at the weir's west foot: the weir and its lip 2 studs wider each side (x 6084..6118), into the canal's walls.
-- Logged in HudBackup.JapanGeo3_log. Output "QQ GEO3".
if game:GetService("RunService"):IsRunning() then print("QQ GEO3 ABORT - Play mode") return end
local HttpService = game:GetService("HttpService")
local SS = game:GetService("ServerStorage")
local T = workspace.Terrain
local J = workspace:FindFirstChild("JapanMap")
if not J then print("QQ GEO3 ABORT - no workspace.JapanMap") return end
local function say(fmt, ...) print("QQ GEO3 " .. string.format(fmt, ...)) end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before JapanGeo3") end)
local log = {}
local SEA = -6
local JAPAN_WATER = Color3.fromRGB(24, 112, 151)                       -- JapanWaterAppearance's colour on the client
-- ---------- (1) the horizon ----------
local CLIENT = [===[
-- HorizonSeaClient (RunContext Client): the horizon planes wear the terrain's live WaterColor, so they match whatever the water is
-- painted here - Japan's blue in Japan (JapanWaterAppearance), the default green anywhere else.
local T = workspace.Terrain
local M = script.Parent
local function paint()
	local c = T.WaterColor
	for _, p in ipairs(M:GetChildren()) do if p:IsA("BasePart") then p.Color = c end end
end
paint()
T:GetPropertyChangedSignal("WaterColor"):Connect(paint)
M.ChildAdded:Connect(function(p) if p:IsA("BasePart") then p.Color = T.WaterColor end end)
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
local IX1, IX2, IZ1, IZ2 = 5150, 7150, -1300, 500                      -- the island's box (the map's bulk x 5200..7100, z -1270..450)
local WX, EX, SZ, NZ = 4000, 13000, -6000, 6000                        -- the planes' reach
local made = 0
local function plane(x1, z1, x2, z2)                                     -- tiled: a part is at most 2048 studs a side
	local sx, sz = x2 - x1, z2 - z1
	if sx <= 0 or sz <= 0 then return end
	local nx, nz = math.ceil(sx / 2000), math.ceil(sz / 2000)
	local tx, tz = sx / nx, sz / nz
	for i = 0, nx - 1 do
		for j = 0, nz - 1 do
			local p = Instance.new("Part"); p.Name = "HorizonSea"; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
			p.Size = Vector3.new(tx + 0.5, 1, tz + 0.5); p.CFrame = CFrame.new(x1 + tx * (i + 0.5), SEA - 0.9, z1 + tz * (j + 0.5))
			p.Material = Enum.Material.SmoothPlastic; p.Color = JAPAN_WATER; p.Reflectance = 0.35; p.Transparency = 0.05; p.CastShadow = false
			p.Locked = true; p.Parent = M; made += 1
		end
	end
end
plane(WX, IZ2, EX, NZ)                                                  -- north of the island, full width
plane(WX, SZ, EX, IZ1)                                                  -- south, full width
plane(WX, IZ1, IX1, IZ2)                                                -- west strip beside the island
plane(IX2, IZ1, EX, IZ2)                                                -- east strip
local c = Instance.new("Script"); c.Name = "HorizonSeaClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = M
M.Parent = workspace
say("the horizon: %d old parts removed; workspace['Horizon sea'] (Model, Persistent) with %d planes at y %.1f round the island's box x %d..%d z %d..%d, out to x %d..%d z %d..%d, colour (24,112,151) + HorizonSeaClient (%d chars) painting the live WaterColor",
	removed, made, SEA - 0.9, IX1, IX2, IZ1, IZ2, WX, EX, SZ, NZ, #CLIENT)
log.horizon = {planes = made, island = {IX1, IX2, IZ1, IZ2}, reach = {WX, EX, SZ, NZ}, removed = removed}
-- ---------- (2) the weir's west foot ----------
local WF = J:FindFirstChild("Canal weir")
local widened = 0
if WF then
	for _, p in ipairs(WF:GetChildren()) do
		if p:IsA("BasePart") and (p.Name == "Weir" or p.Name == "Weir lip") and p.Size.X < 34 then p.Size = Vector3.new(34, p.Size.Y, p.Size.Z); widened += 1 end
	end
	say("the weir: %d parts widened to 34 (x 6084..6118), into the canal's walls, over the sliver at the west foot", widened)
else
	say("the weir: JapanMap['Canal weir'] not found - nothing widened")
end
log.weir = widened
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local lv = hb:FindFirstChild("JapanGeo3_log") or Instance.new("StringValue"); lv.Name = "JapanGeo3_log"; lv.Parent = hb
lv.Value = HttpService:JSONEncode(log)
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after JapanGeo3") end)
say("DONE: the horizon as a persistent model in the live water colour from the island's edge out; the weir widened (log HudBackup.JapanGeo3_log)")
