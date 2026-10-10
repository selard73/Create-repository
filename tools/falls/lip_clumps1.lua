-- lip_clumps1.lua (Studio EDIT mode; re-runnable). Job 85: the blue bulge at the top right corner of the falls.
-- Shannon (Oct 10): "the blue bulge at the right corner of the top of the falls; the fix last time was adding clumps on top of
-- it; it worked on the left side but not on the right, you might just need some more clumps". The clumps are the two lip
-- boulders (SouthGorge.LipRocks.LipRockW / LipRockE); the blue is the river's terrain water showing round the west corner
-- (the right, seen from Porto). This LOOKS from the foot of the falls at the corner, finds every spot where terrain water
-- is the first thing seen, sets a smaller clone of LipRockW on that spot, and looks again - up to twelve clumps, until no
-- water shows from any of the viewpoints. Clumps: SouthGorge.LipRocks.LipClump_N, anchored, no collision (the corner is
-- beside the boat's line, not on it). Undo: delete the LipClump_* parts. No publish.
local SG = workspace:FindFirstChild("SouthGorge"); local LR = SG and SG:FindFirstChild("LipRocks")
local tpl = LR and LR:FindFirstChild("LipRockW")
if not tpl then print("QQ LIPCLUMP ABORT: SouthGorge.LipRocks.LipRockW not found") return end
local Terrain = workspace.Terrain
for _, c in ipairs(LR:GetChildren()) do if c.Name:sub(1, 8) == "LipClump" then c:Destroy() end end
-- where to look from (Porto side, the foot and the pool, the far right) and what to look at (the corner box)
local VIEWS = {Vector3.new(176, -44, -585), Vector3.new(176, -12, -566), Vector3.new(185, -32, -655), Vector3.new(150, -30, -600), Vector3.new(160, -46, -570), Vector3.new(190, -20, -600)}
local BOX = {x0 = 156, x1 = 170, y0 = -11, y1 = 4, z0 = -553, z1 = -539}
local SHEET_X0 = 167.4   -- the Body sheet's west edge at the top (36 wide about x 185.4): water behind the sheet is not the bulge
-- the water sheet is beams, which stop no rays, and the LipPlate answers none: a stand-in for both while we look (removed after)
local standin = Instance.new("Part"); standin.Name = "LipSheetStandIn"; standin.Anchored = true; standin.CanCollide = false; standin.Transparency = 1
standin.Size = Vector3.new(36, 54, 0.6); standin.CFrame = CFrame.new(185.4, -27.5, -549.1); standin.Parent = workspace
local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances = {}
local function exposed()
	local pts = {}
	for _, v in ipairs(VIEWS) do
		for x = BOX.x0, BOX.x1, 1 do
			for y = BOX.y0, BOX.y1, 1 do
				for z = BOX.z0, BOX.z1, 2 do
					local target = Vector3.new(x, y, z)
					local dir = target - v
					local hit = workspace:Raycast(v, dir.Unit * (dir.Magnitude + 2), params)
					if hit and hit.Instance == Terrain and hit.Material == Enum.Material.Water then
						local p = hit.Position
						if p.X >= BOX.x0 - 2 and p.X < SHEET_X0 + 0.2 and p.Y >= BOX.y0 - 2 and p.Y <= BOX.y1 + 2 and p.Z >= BOX.z0 - 2 and p.Z <= BOX.z1 + 2 then
							table.insert(pts, {p = p, v = v})
						end
					end
				end
			end
		end
	end
	return pts
end
local function v3(v) return string.format("(%.1f,%.1f,%.1f)", v.X, v.Y, v.Z) end
local before = exposed()
local placed = {}
local rng = Random.new(7)
local n = 0
while n < 12 do
	local pts = exposed()
	if #pts == 0 then break end
	-- the densest spot: the point with the most neighbours within 2.5 studs
	local best, bestCount = nil, -1
	for i, a in ipairs(pts) do
		local c = 0
		for _, b in ipairs(pts) do if (a.p - b.p).Magnitude < 2.5 then c += 1 end end
		if c > bestCount then best, bestCount = a, c end
	end
	-- the cluster's centre, and the direction it was seen from
	local sum, cnt, vsum = Vector3.zero, 0, Vector3.zero
	for _, b in ipairs(pts) do if (best.p - b.p).Magnitude < 2.5 then sum += b.p; cnt += 1; vsum += (b.v - b.p).Unit end end
	local centre = sum / cnt
	local toward = (vsum / cnt); toward = toward.Magnitude > 0.01 and toward.Unit or Vector3.new(0, 0, -1)
	n += 1
	local c = tpl:Clone(); c.Name = "LipClump_" .. n
	for _, d in ipairs(c:GetDescendants()) do if d:IsA("LuaSourceContainer") then d:Destroy() end end
	local s = 0.45 + 0.12 * rng:NextNumber(0, 1) + math.min(0.25, bestCount * 0.01)
	c.Size = tpl.Size * s
	c.CFrame = CFrame.new(centre + toward * (c.Size.Magnitude * 0.22) - Vector3.new(0, 0.15, 0)) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6.28), rng:NextNumber(-0.4, 0.4))
	c.Anchored = true; c.CanCollide = false; c.CanQuery = true; c.CanTouch = false
	c.Parent = LR
	table.insert(placed, string.format("%d %s size %.1f (%d pts)", n, v3(c.Position), c.Size.Magnitude, bestCount))
end
local after = exposed()
standin:Destroy()
print(string.format("QQ LIPCLUMP DONE: water showing at the right corner from %d viewpoints: %d sightings before, %d after; %d clumps: %s", #VIEWS, #before, #after, n, #placed > 0 and table.concat(placed, "; ") or "none"))
if #after > 0 then
	local s = {} for i = 1, math.min(8, #after) do table.insert(s, v3(after[i].p)) end
	print("QQ LIPCLUMP left: " .. table.concat(s, " "))
end
