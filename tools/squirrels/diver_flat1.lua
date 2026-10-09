-- squirrels/diver_flat1: EDIT mode. With DRY = true it is READ-ONLY. Shannon, Oct 9: the diver (snorkel squirrel) "just
-- needs to be moved back a little, his flippers are flat but he is sitting on a curved surface; if he is moved back to
-- where it is flat, he will be flush with the ground". Walks back from where he stands (away from the way he faces, i.e.
-- inland), half a stud at a time up to MAX_BACK, measuring the ground slope under his footprint at each spot, and puts him
-- on the first spot flatter than FLAT (or the flattest found), feet seated as seat_squirrels1 does (bottom = ground +
-- typical rig gap 0.41 - 0.05). Facing unchanged. Attr FlatOct9OrigCF = where he was. Output "QQ DIVE".

local DRY = true
local NAME = "snorkel"      -- lower-case part of the model's name
local MAX_BACK = 6          -- studs inland to search
local STEP = 0.5
local FLAT = 0.08           -- max height difference across the footprint that counts as flat
local FOOT = 1.2            -- half-width of the footprint sampled (studs)
local RIG = 0.41 - 0.05     -- bottom of the bounding box above the ground, as the seated squirrels sit

if game:GetService("RunService"):IsRunning() then warn("QQ DIVE ABORT - Play mode") return end
local m
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("Model") and d.Name:lower():find(NAME, 1, true) and d:FindFirstChildWhichIsA("BasePart", true) then m = d break end
end
if not m then warn("QQ DIVE ABORT - no model named *" .. NAME .. "*") return end
local twins = workspace:FindFirstChild("SquirrelTwins")
local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude; params.IgnoreWater = true
params.FilterDescendantsInstances = twins and {m, twins} or {m}
local function groundAt(x, z, y0)
	local r = workspace:Raycast(Vector3.new(x, y0 + 6, z), Vector3.new(0, -30, 0), params)
	return r and r.Position.Y or nil, r
end
local pivot = m:GetPivot()
local bcf, bsize = m:GetBoundingBox()
local bottom = bcf.Position.Y - bsize.Y / 2
local look = pivot.LookVector
local back = -Vector3.new(look.X, 0, look.Z)
if back.Magnitude < 0.1 then warn("QQ DIVE ABORT - he faces straight up/down?") return end
back = back.Unit
local side = Vector3.new(-back.Z, 0, back.X)
print(string.format("QQ DIVE %s at %s, bottom %.2f, facing (%.2f,%.2f); searching inland along (%.2f,%.2f)", m.Name,
	tostring(pivot.Position), bottom, look.X, look.Z, back.X, back.Z))

local best, bestSpread, bestG = nil, 1e9, nil
local chosen
for d = 0, MAX_BACK, STEP do
	local c = pivot.Position + back * d
	local hs, ok = {}, true
	for _, off in ipairs({Vector3.zero, side * FOOT, -side * FOOT, back * FOOT, -back * FOOT}) do
		local g = groundAt(c.X + off.X, c.Z + off.Z, bottom)
		if not g then ok = false break end
		table.insert(hs, g)
	end
	if ok then
		table.sort(hs)
		local spread = hs[#hs] - hs[1]
		local gC = groundAt(c.X, c.Z, bottom)
		print(string.format("QQ DIVE back %.1f: ground %.2f, spread across the feet %.3f%s", d, gC, spread, spread <= FLAT and "  FLAT" or ""))
		if spread < bestSpread then best, bestSpread, bestG = d, spread, gC end
		if spread <= FLAT and not chosen then chosen = {d = d, g = gC, spread = spread} end
	else
		print(string.format("QQ DIVE back %.1f: no ground under part of the footprint", d))
	end
end
if not chosen then
	if not best then warn("QQ DIVE ABORT - no usable spot found") return end
	chosen = {d = best, g = bestG, spread = bestSpread}
	print(string.format("QQ DIVE no spot flatter than %.2f; flattest is %.1f back (spread %.3f)", FLAT, best, bestSpread))
end
local target = pivot.Position + back * chosen.d
local newBottomY = chosen.g + RIG
local dy = newBottomY - bottom
local newPivot = CFrame.new(target.X, pivot.Y + dy, target.Z) * pivot.Rotation
print(string.format("QQ DIVE %s: move %.1f back to (%.1f,%.2f,%.1f), feet from %.2f to %.2f (ground %.2f, spread %.3f)",
	DRY and "would" or "will", chosen.d, newPivot.X, newPivot.Y, newPivot.Z, bottom, newBottomY, chosen.g, chosen.spread))
if DRY then print("QQ DIVE DONE (dry run)") return end
m:SetAttribute("FlatOct9OrigCF", pivot)
m:PivotTo(newPivot)
print("QQ DIVE DONE: moved")
