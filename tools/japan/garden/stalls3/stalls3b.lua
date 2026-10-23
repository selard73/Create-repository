-- stalls3b (Oct 23 2026): her "there is not enough on the shaved ice table, it looks bare". stalls3's fill found no free stretch
-- wide enough for another served set (gaps 2.3-2.5, the set 2.92), so the counter is re-laid along its length: the shaver set
-- (kakigori_a) to the end it was nearer, then three served sets (kakigori_b + copies kakigori_b2 / b3, b2 turned round about its
-- middle), evenly spaced. Undo: Stalls3bWasPivot on the moved sets; the copies carry Stalls3Added. "QQ STALLS3B".
local ice = workspace.JapanMap["Outdoor market revision"]["Shaved ice stall"]
if ice:FindFirstChild("kakigori_b2") then return "QQ STALLS3B already done" end
local function flat(v) return Vector3.new(v.X, 0, v.Z).Unit end
local function halfAlong(p, n)
	local cf, s = p.CFrame, p.Size
	return (math.abs(cf.RightVector:Dot(n)) * s.X + math.abs(cf.UpVector:Dot(n)) * s.Y + math.abs(cf.LookVector:Dot(n)) * s.Z) / 2
end
local function span(m, origin, n)
	local lo, hi = math.huge, -math.huge
	local list = m:IsA("BasePart") and {m} or m:GetDescendants()
	for _, p in ipairs(list) do
		if p:IsA("BasePart") then local c = (p.Position - origin):Dot(n); local h = halfAlong(p, n); lo = math.min(lo, c - h); hi = math.max(hi, c + h) end
	end
	return lo, hi
end
local pv = ice:GetPivot()
local O, right = pv.Position, flat(pv.RightVector)
local c0, c1 = span(ice["Service counter"], O, right)
local A, S = ice.kakigori_a, ice.kakigori_b
local aLo, aHi = span(A, O, right)
local sLo, sHi = span(S, O, right)
local wA, wS, M = aHi - aLo, sHi - sLo, 0.3
local free = (c1 - c0) - 2 * M - wA - 3 * wS
if free < 0.45 then return string.format("QQ STALLS3B ABORT: no room (counter %.2f, shaver %.2f, 3 x %.2f)", c1 - c0, wA, wS) end
local g = free / 3
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before stalls3b") end)
local shaverRight = (aLo + aHi) / 2 > 0
local function slide(m, lo, hi, newLo)
	if m:GetAttribute("Stalls3bWasPivot") == nil then m:SetAttribute("Stalls3bWasPivot", m:GetPivot()) end
	m:PivotTo(m:GetPivot() + right * (newLo - lo))
end
local starts = {}
if shaverRight then
	slide(A, aLo, aHi, c1 - M - wA)
	for i = 0, 2 do table.insert(starts, c0 + M + i * (wS + g)) end
else
	slide(A, aLo, aHi, c0 + M)
	for i = 0, 2 do table.insert(starts, c0 + M + wA + g + i * (wS + g)) end
end
local mid = S:GetBoundingBox().Position
local sets = {S}
for i = 2, 3 do
	local m = S:Clone(); m.Name = "kakigori_b" .. i
	m:SetAttribute("Stalls3Added", true); m:SetAttribute("Stalls2WasScale", nil); m:SetAttribute("Stalls3bWasPivot", nil)
	m.Parent = ice
	table.insert(sets, m)
end
for i, m in ipairs(sets) do
	if i == 2 then m:PivotTo(CFrame.new(mid) * CFrame.Angles(0, math.pi, 0) * (CFrame.new(mid):Inverse() * m:GetPivot())) end
	if i == 1 then slide(m, sLo, sHi, starts[1]) else m:PivotTo(m:GetPivot() + right * (starts[i] - sLo)) end
end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after stalls3b") end)
local row = {}
for _, m in ipairs({A, sets[1], sets[2], sets[3]}) do local lo, hi = span(m, O, right); table.insert(row, string.format("%s [%.2f, %.2f]", m.Name, lo, hi)) end
return string.format("QQ STALLS3B counter %.2f..%.2f, gaps %.2f: %s - EDIT INSTALLED; NOT PUBLISHED", c0, c1, g, table.concat(row, " "))
