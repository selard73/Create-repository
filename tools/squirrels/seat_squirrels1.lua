-- squirrels/seat_squirrels1: EDIT mode. With DRY = true it is READ-ONLY. Shannon, Oct 9: "the diver squirrel is floating,
-- his feet are not on the surface of the ground". For every model tagged "Squirrel" in Porto (and the France maps if
-- ALL_MAPS), measures the gap between the bottom of its bounding box and the ground straight below its pivot (parts or
-- terrain, the squirrel itself ignored). Models floating by more than LIFT_MIN, or sunk by more than SINK_MAX, are moved
-- straight down/up so the bottom sits on the ground (+ SINK, a hair in, so feet never hover). Nothing else moves; facing
-- is kept. Each moved model gets attr SeatOct9OrigCF (its pivot before). Output lines start with "QQ SEAT".

local DRY = true
local LIFT_MIN = 0.15    -- floating by more than this = seat it
local SINK_MAX = 0.6     -- sunk by more than this = lift it (bigger = probably on purpose, left alone and reported)
local SINK = 0.05        -- how far into the ground the bottom goes
local ALL_MAPS = false   -- false = only Porto (x 250..800, z -1250..-500)
local ONLY = nil         -- e.g. "snorkel" to do one squirrel by name (lower-case substring); nil = list all, move none
                         -- (a squirrel is only MOVED when ONLY names it: rigged meshes can read as floating when they are not)

if game:GetService("RunService"):IsRunning() then warn("QQ SEAT ABORT - Play mode") return end
local CS = game:GetService("CollectionService")
local function inPorto(p) return p.X >= 250 and p.X <= 800 and p.Z >= -1250 and p.Z <= -500 end

local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude; params.IgnoreWater = true
local function bottomOf(m)
	local cf, size = m:GetBoundingBox()
	return cf.Position.Y - size.Y / 2, size
end
-- in Edit mode most squirrels do not carry the "Squirrel" tag (the game adds it when it runs), so go by name as well
local cands, seen = {}, {}
local function consider(m)
	if m:IsA("Model") and not seen[m] and m:IsDescendantOf(workspace) and m:FindFirstChildWhichIsA("BasePart", true) then
		local twins = workspace:FindFirstChild("SquirrelTwins")
		if not (twins and m:IsDescendantOf(twins)) then seen[m] = true; table.insert(cands, m) end
	end
end
for _, m in ipairs(CS:GetTagged("Squirrel")) do consider(m) end
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("Model") and d.Name:lower():find("squirrel", 1, true) and not d:FindFirstChildWhichIsA("Model") then consider(d) end
end
local rows, moved, floating, sunk = {}, 0, 0, 0
for _, m in ipairs(cands) do
	do
		local pivot = m:GetPivot()
		if (ALL_MAPS or inPorto(pivot.Position)) then
			local bottom, size = bottomOf(m)
			local ex = {m}
			local twins = workspace:FindFirstChild("SquirrelTwins"); if twins then table.insert(ex, twins) end
			params.FilterDescendantsInstances = ex
			-- from just above the model's bottom, straight down: the ground under its feet
			local hit = workspace:Raycast(Vector3.new(pivot.X, bottom + 1, pivot.Z), Vector3.new(0, -30, 0), params)
			if not hit then
				table.insert(rows, string.format("QQ SEAT ?? %-28s no ground within 30 below @ (%.1f,%.2f,%.1f)", m.Name, pivot.X, pivot.Y, pivot.Z))
			else
				local gap = bottom - hit.Position.Y          -- + floating, - sunk
				local what = ""
				if gap > LIFT_MIN then floating += 1; what = "FLOATING"
				elseif gap < -SINK_MAX then sunk += 1; what = "sunk (left alone)"
				elseif gap < -0.15 then what = "a little sunk (fine)" else what = "ok" end
				local doMove = gap > LIFT_MIN and ONLY ~= nil and m.Name:lower():find(ONLY:lower(), 1, true) ~= nil
				local line = string.format("QQ SEAT %-8s %-28s gap %+.2f  bottom %.2f ground %.2f (%s) @ (%.1f,%.2f,%.1f)",
					what, m.Name, gap, bottom, hit.Position.Y, hit.Instance == workspace.Terrain and ("terrain " .. hit.Material.Name) or hit.Instance.Name, pivot.X, pivot.Y, pivot.Z)
				if doMove and not DRY then
					m:SetAttribute("SeatOct9OrigCF", pivot)
					m:PivotTo(pivot - Vector3.new(0, gap + SINK, 0))
					moved += 1
					line = line .. string.format("  -> moved down %.2f", gap + SINK)
				elseif doMove then
					line = line .. string.format("  -> would move down %.2f", gap + SINK)
				elseif gap > LIFT_MIN then
					line = line .. "  (name it in ONLY to seat it)"
				end
				table.insert(rows, line)
			end
		end
	end
end
table.sort(rows)
for _, r in ipairs(rows) do print(r) end
print(string.format("QQ SEAT DONE: %d squirrels checked, %d floating, %d sunk, %d moved%s", #rows, floating, sunk, moved, DRY and " (dry run)" or ""))
