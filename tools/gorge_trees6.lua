-- gorge_trees6: CHANGES THE PLACE: repairs the trees after gorge_trees5, which measured every tree by its model
-- pivot - and these kit clones' pivots are NOT at the trees (gorge_trees1 turned each one about its middle, which
-- swung the pivot 1 to 150 studs away). So trees5 re-seated 186 trees to wrong heights and removed the wrong ones.
-- This rebuilds the set from the ORIGINAL placement list (gorge_trees1.lua's own table): the current
-- trees all go, and the 220 listed trees whose spot is north of the ridge's crest line (+6) are placed again exactly
-- as trees1 did (same kit, scale, yaw, colours; measured onto the terrain that is there now; the same skip rules,
-- plus trees3's 'nothing lower than 6'). Run gorge_trees2 afterwards to seat them on the rock's top strip where that
-- is higher, then gorge_probe11 to verify by geometry.
local TREES = {{"pine_tall",162.8,-258.0,1.31,19},{"olive_tree",165.4,-265.8,1.01,18},{"pine_tall",157.7,-273.8,1.37,351},{"olive_tree",153.5,-279.5,1.10,177},{"olive_tree",148.4,-287.8,1.07,317},{"pine_tall",147.1,-295.0,1.55,82},{"cypress",137.9,-304.4,0.96,0},{"cypress",128.1,-310.7,0.88,117},{"pine_tall",121.0,-319.1,1.48,161},{"pine_tall",113.6,-326.3,1.33,288},{"pine_tall",108.8,-333.8,1.21,336},{"olive_tree",104.7,-339.5,1.09,342},{"pine_tall",93.7,-347.8,1.30,267},{"cypress",86.2,-354.9,0.92,80},{"olive_tree",75.4,-362.4,1.16,136},{"pine_tall",64.6,-371.4,1.36,287},{"pine_tall",71.1,-400.2,1.58,357},{"olive_tree",83.4,-407.1,1.04,257},{"cypress",97.3,-415.3,0.92,345},{"pine_squat",107.8,-423.3,1.20,151},{"olive_tree",111.6,-429.2,1.08,356},{"cypress",120.5,-437.0,0.87,146},{"pine_tall",127.2,-444.5,1.26,190},{"cypress",133.3,-453.0,0.93,38},{"olive_tree",140.1,-460.7,1.01,1},{"pine_tall",150.6,-468.5,1.57,320},{"pine_squat",153.1,-475.0,1.46,121},{"pine_squat",156.9,-483.3,1.38,265},{"pine_tall",163.7,-489.9,1.20,14},{"olive_tree",169.7,-498.9,1.05,18},{"pine_tall",170.7,-504.3,1.34,132},{"olive_tree",170.4,-512.5,1.20,339},{"cypress",166.6,-521.0,0.97,83},{"olive_tree",162.6,-528.0,1.18,193},{"olive_tree",165.6,-536.8,1.01,191},{"olive_tree",219.3,-257.7,1.06,199},{"olive_tree",222.3,-264.0,1.19,344},{"pine_tall",222.8,-273.2,1.30,17},{"pine_tall",219.2,-279.4,1.27,248},{"pine_tall",218.7,-289.3,1.28,244},{"pine_tall",213.3,-295.6,1.31,176},{"olive_tree",203.6,-303.9,1.18,90},{"pine_tall",192.0,-311.7,1.57,131},{"pine_tall",184.8,-319.5,1.22,77},{"pine_squat",177.8,-324.1,1.47,87},{"olive_tree",174.2,-331.7,1.03,307},{"pine_tall",167.0,-341.0,1.45,183},{"olive_tree",157.7,-347.2,1.21,174},{"pine_tall",155.2,-355.9,1.55,151},{"cypress",152.5,-363.4,0.86,100},{"pine_squat",154.5,-370.4,1.33,9},{"pine_tall",155.5,-399.2,1.25,134},{"cypress",158.3,-408.3,0.97,7},{"pine_tall",152.3,-414.2,1.47,94},{"pine_tall",160.8,-421.8,1.58,26},{"pine_tall",168.3,-431.4,1.36,267},{"pine_tall",177.0,-438.5,1.37,139},{"pine_tall",184.4,-444.6,1.33,159},{"olive_tree",191.7,-451.7,1.13,201},{"pine_squat",199.3,-460.3,1.44,93},{"olive_tree",205.7,-468.0,1.24,50},{"cypress",213.2,-475.6,0.92,317},{"olive_tree",217.5,-483.8,1.09,294},{"olive_tree",225.9,-489.6,1.00,360},{"pine_tall",232.4,-498.9,1.46,68},{"olive_tree",231.3,-506.9,1.02,57},{"olive_tree",230.9,-513.8,1.21,2},{"cypress",230.6,-521.8,0.99,294},{"olive_tree",225.9,-528.8,1.07,210},{"cypress",218.3,-534.1,0.90,206},{"cypress",64.2,-375.4,0.95,236},{"cypress",63.1,-392.6,0.95,94},{"cypress",157.5,-375.4,0.95,109},{"cypress",156.3,-392.6,0.95,186},{"pine_squat",865.1,-382.9,1.38,32},{"pine_tall",881.6,-317.9,1.46,295},{"pine_tall",-222.3,-298.2,1.39,153},{"pine_squat",473.3,-310.2,1.27,165},{"olive_tree",203.1,-384.0,1.10,296},{"pine_tall",-18.7,-355.6,1.57,110},{"pine_tall",-202.0,-285.8,1.38,161},{"pine_tall",374.4,-475.4,1.38,154},{"pine_tall",769.9,-409.1,1.40,293},{"pine_squat",54.9,-359.3,1.45,36},{"cypress",59.5,-345.2,0.87,331},{"pine_tall",196.2,-354.9,1.55,303},{"olive_tree",-49.9,-312.7,1.18,16},{"pine_tall",479.9,-340.1,1.22,13},{"pine_tall",692.5,-310.3,1.52,15},{"pine_squat",788.8,-456.3,1.27,335},{"pine_tall",45.6,-317.0,1.27,167},{"pine_tall",568.7,-562.3,1.24,218},{"pine_squat",897.6,-463.6,1.20,103},{"cypress",756.8,-396.9,1.00,302},{"olive_tree",593.0,-390.0,1.04,318},{"cypress",605.8,-330.9,0.85,57},{"pine_squat",431.0,-290.1,1.41,137},{"olive_tree",708.2,-341.3,1.23,323},{"olive_tree",312.5,-337.1,1.04,135},{"pine_tall",944.2,-459.3,1.35,339},{"cypress",-82.5,-374.1,0.97,284},{"olive_tree",435.3,-289.7,1.09,300},{"cypress",246.2,-491.8,1.00,70},{"pine_tall",334.9,-340.3,1.54,147},{"olive_tree",-93.8,-360.3,1.09,160},{"pine_squat",893.8,-290.1,1.34,24},{"pine_squat",481.9,-560.4,1.21,188},{"pine_tall",779.0,-403.8,1.37,263},{"cypress",-43.5,-407.3,0.92,129},{"olive_tree",230.1,-413.4,1.19,236},{"pine_tall",953.6,-420.6,1.28,75},{"pine_tall",80.5,-295.9,1.41,42},{"pine_squat",111.0,-282.1,1.35,170},{"pine_squat",-14.3,-298.9,1.48,354},{"pine_squat",368.2,-388.2,1.34,28},{"cypress",106.3,-295.1,0.99,290},{"pine_tall",572.5,-390.7,1.53,15},{"pine_tall",958.6,-435.0,1.46,204},{"olive_tree",919.1,-437.2,1.01,285},{"pine_tall",384.1,-311.0,1.22,351},{"cypress",378.7,-354.0,0.93,202},{"pine_squat",498.9,-394.2,1.37,127},{"pine_squat",337.4,-460.0,1.33,39},{"olive_tree",891.9,-539.8,1.15,219},{"pine_tall",-211.3,-294.2,1.56,305},{"cypress",664.3,-315.3,0.95,75},{"pine_tall",446.7,-401.2,1.59,195},{"cypress",708.6,-434.8,0.92,276},{"pine_tall",680.5,-462.9,1.42,348},{"olive_tree",-9.4,-472.6,1.09,115},{"pine_squat",970.2,-389.4,1.35,190},{"olive_tree",403.0,-386.7,1.24,44},{"pine_tall",10.9,-355.5,1.31,212},{"pine_tall",263.0,-338.6,1.53,293},{"pine_tall",-86.1,-356.3,1.38,189},{"pine_tall",31.0,-417.1,1.51,346},{"pine_tall",505.3,-418.5,1.48,229},{"pine_tall",70.0,-413.5,1.48,146},{"pine_tall",561.8,-408.8,1.34,332},{"pine_tall",770.5,-288.9,1.50,58},{"pine_squat",564.7,-547.3,1.29,274},{"olive_tree",788.3,-414.1,1.09,167},{"olive_tree",-3.6,-295.7,1.15,127},{"pine_tall",970.8,-545.2,1.28,219},{"pine_tall",-187.2,-302.4,1.56,77},{"pine_tall",84.2,-257.5,1.29,104},{"olive_tree",516.1,-342.0,1.14,328},{"pine_tall",658.0,-543.3,1.48,53},{"pine_tall",812.2,-296.3,1.40,225},{"pine_squat",386.3,-289.1,1.22,183},{"pine_tall",158.4,-367.1,1.46,359},{"pine_tall",470.8,-442.0,1.58,40},{"pine_tall",834.2,-428.7,1.43,223},{"pine_tall",423.4,-426.7,1.33,8},{"cypress",-171.2,-343.6,0.96,178},{"pine_tall",752.6,-434.4,1.58,274},{"pine_tall",105.6,-305.3,1.49,162},{"pine_tall",198.4,-423.6,1.24,291},{"pine_tall",742.2,-366.4,1.47,289},{"pine_squat",847.4,-340.3,1.25,355},{"pine_tall",-149.4,-322.9,1.46,264},{"pine_squat",1.2,-424.5,1.29,229},{"pine_squat",-69.3,-365.9,1.28,30},{"pine_tall",-92.4,-261.0,1.58,85},{"pine_tall",-199.1,-425.8,1.36,354},{"cypress",888.7,-506.6,0.91,3},{"pine_tall",1.9,-518.6,1.29,331},{"olive_tree",280.9,-554.1,1.12,74},{"pine_tall",594.6,-558.9,1.22,327},{"cypress",78.1,-260.7,0.94,116},{"pine_squat",89.7,-335.0,1.46,328},{"pine_tall",976.0,-389.2,1.49,320},{"pine_squat",247.7,-253.6,1.40,44},{"pine_squat",79.6,-259.8,1.25,175},{"cypress",753.0,-332.9,0.97,295},{"pine_tall",-168.8,-248.8,1.43,147},{"olive_tree",743.9,-333.1,1.13,259},{"olive_tree",-0.2,-261.8,1.17,268},{"olive_tree",624.2,-364.4,1.17,328},{"cypress",829.1,-355.3,0.91,167},{"pine_tall",-36.8,-258.0,1.55,130},{"cypress",771.6,-403.0,0.95,241},{"olive_tree",603.3,-372.7,1.01,93},{"pine_tall",417.9,-411.1,1.33,74},{"pine_squat",711.5,-357.0,1.44,24},{"olive_tree",432.9,-371.1,1.03,237},{"pine_tall",462.0,-345.1,1.52,230},{"cypress",71.9,-250.1,0.95,124},{"pine_tall",-69.8,-250.8,1.51,185},{"pine_tall",958.9,-454.1,1.45,53},{"pine_tall",-50.7,-461.5,1.29,50},{"olive_tree",-44.4,-444.0,1.16,100},{"pine_tall",262.3,-468.4,1.52,11},{"pine_tall",463.5,-474.5,1.20,183},{"pine_tall",-225.9,-449.7,1.32,302},{"pine_tall",569.0,-566.6,1.41,241},{"pine_tall",779.4,-396.7,1.56,196},{"pine_squat",-165.8,-258.6,1.41,40},{"pine_tall",370.9,-337.3,1.24,117},{"cypress",708.0,-351.9,0.93,154},{"pine_tall",640.1,-409.5,1.40,317},{"pine_squat",32.2,-553.9,1.31,279},{"pine_tall",62.1,-289.9,1.30,192},{"pine_tall",587.0,-319.7,1.25,35},{"pine_tall",578.7,-432.1,1.55,350},{"pine_squat",287.3,-237.9,1.36,117},{"pine_tall",177.8,-338.9,1.57,55},{"pine_tall",400.4,-338.5,1.47,182},{"pine_squat",57.9,-400.0,1.26,293},{"pine_tall",-41.8,-277.4,1.55,200},{"pine_tall",786.7,-432.0,1.48,174},{"pine_tall",359.5,-541.8,1.56,32},{"cypress",384.1,-389.2,0.87,2},{"pine_tall",-156.5,-301.0,1.41,260},{"pine_tall",-204.6,-336.3,1.24,294},{"cypress",910.5,-310.6,0.91,130},{"pine_tall",518.7,-537.1,1.28,318},{"pine_tall",578.7,-349.0,1.26,88},{"cypress",852.8,-375.5,0.93,343},{"cypress",603.7,-309.3,0.87,270}}
local C = Color3.fromRGB
local KITS = {pine_tall = "ForestKit", pine_squat = "ForestKit", bush_small = "ForestKit", olive_tree = "DomaineKit", cypress = "DomaineKit", boxwood = "DomaineKit"}
local COLOURS = {
	pine_tall = {Foliage = C(72, 120, 74), Trunk = C(104, 78, 56)}, pine_squat = {Foliage = C(72, 120, 74), Trunk = C(104, 78, 56)},
	olive_tree = {Olive = C(152, 170, 132), OTrunk = C(108, 88, 66)}, cypress = {Cypress = C(54, 88, 58), OTrunk = C(108, 88, 66)},
}
local rng = Random.new(3009)
local G = workspace:FindFirstChild("SouthGorge"); assert(G, "SouthGorge folder missing")
local old = G:FindFirstChild("Trees"); if old then old:Destroy() end
local TF = Instance.new("Folder"); TF.Name = "Trees"; TF.Parent = G
local tp = RaycastParams.new(); tp.FilterType = Enum.RaycastFilterType.Include; tp.FilterDescendantsInstances = {workspace.Terrain}; tp.IgnoreWater = false
local function aabb(m)
	local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, q in ipairs(m:GetDescendants()) do
		if q:IsA("BasePart") then
			local cf, s = q.CFrame, q.Size / 2
			local ext = Vector3.new(
				math.abs(cf.RightVector.X) * s.X + math.abs(cf.UpVector.X) * s.Y + math.abs(cf.LookVector.X) * s.Z,
				math.abs(cf.RightVector.Y) * s.X + math.abs(cf.UpVector.Y) * s.Y + math.abs(cf.LookVector.Y) * s.Z,
				math.abs(cf.RightVector.Z) * s.X + math.abs(cf.UpVector.Z) * s.Y + math.abs(cf.LookVector.Z) * s.Z)
			lo = lo:Min(cf.Position - ext); hi = hi:Max(cf.Position + ext)
		end
	end
	return lo, hi
end
local missing = {}
local function kit(name, x, y, z, scale, yaw)
	local home = workspace:FindFirstChild(KITS[name])
	local src = home and home:FindFirstChild(name)
	if not src and name == "pine_tall" then src = home and home:FindFirstChild("pine_squat"); scale = scale * 1.6 end   -- fallback
	if not src then missing[name] = (missing[name] or 0) + 1 return nil end
	local m = src:Clone()
	if scale and scale ~= 1 then m:ScaleTo(m:GetScale() * scale) end
	local lo, hi = aabb(m)
	local c = (lo + hi) / 2
	m:PivotTo(CFrame.new(c) * CFrame.Angles(0, math.rad(yaw), 0) * CFrame.new(-c) * m:GetPivot())
	lo, hi = aabb(m)
	m:PivotTo(m:GetPivot() + Vector3.new(x - (lo.X + hi.X) / 2, y - lo.Y, z - (lo.Z + hi.Z) / 2))
	local col = COLOURS[name] or {}
	for _, q in ipairs(m:GetDescendants()) do
		if q:IsA("BasePart") then
			q.Anchored = true; q.Transparency = 0; q.CanCollide = false; q.CanQuery = false; q.CanTouch = false
			if col[q.Name] then q.Color = col[q.Name] end
		end
	end
	m.Parent = TF
	return m
end
local placed, skipped = 0, {nohit = 0, water = 0, beach = 0, flat = 0, gorge = 0}
for _, t in ipairs(TREES) do
	local name, x, z, scale, yaw = t[1], t[2], t[3], t[4], t[5]
	local hit = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0), tp)
	if not hit then skipped.nohit += 1
	elseif hit.Material == Enum.Material.Water then skipped.water += 1
	elseif hit.Material == Enum.Material.Sand or hit.Material == Enum.Material.Mud then skipped.beach += 1
	elseif hit.Position.Y < 6.0 then skipped.flat += 1          -- (gorge_trees3 later removed the ones standing lower than 6: keep that rule)
	else
		-- the ground must be about level under the tree (no tree perched on the gorge's cut edge): 4 rays 1.5 studs out
		local ok, y0 = true, hit.Position.Y
		for _, d in ipairs({Vector3.new(1.5, 0, 0), Vector3.new(-1.5, 0, 0), Vector3.new(0, 0, 1.5), Vector3.new(0, 0, -1.5)}) do
			local h2 = workspace:Raycast(Vector3.new(x, 300, z) + d, Vector3.new(0, -600, 0), tp)
			if not h2 or h2.Material == Enum.Material.Water or math.abs(h2.Position.Y - y0) > 2.5 then ok = false break end
		end
		if not ok then skipped.gorge += 1
		else
			if kit(name, x, y0 - 0.15, z, scale, yaw) then placed += 1 end   -- 0.15 into the ground: no gap under the trunk
		end
	end
end
local ms = {}
for k, v in pairs(missing) do ms[#ms + 1] = k .. "=" .. v end
print(string.format("QQ TR6 trees placed %d of %d; skipped: no terrain %d, water %d, beach %d, flat ground %d, uneven/edge %d; kit missing: %s",
	placed, #TREES, skipped.nohit, skipped.water, skipped.beach, skipped.flat, skipped.gorge, #ms > 0 and table.concat(ms, ",") or "none"))
print("QQ TR6 DONE")
