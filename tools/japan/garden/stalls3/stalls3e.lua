-- stalls3e (Oct 23 2026): her "no, that still looks weird, have them on 2 serving trays 4 to a tray in rows of 2". The three
-- served sets (4 cups merged into one mesh each) can't make a 2x2, so: two square wooden trays (the set's board, stretched), each
-- with four single striped cups (copies of the straw cup KG_CupTex from kakigori_a, at the served cups' size) in two rows of two,
-- each cup with its ice heap (copies of the recoloured mounds):
--   tray 1: back matcha, mango; front strawberry (+ cream), blue        tray 2: back grape, melon; front rainbow bear (face to the
--   customer), peach (+ cream); a little stack of three empty cups at the far end. The three old sets -> HudBackup.Stalls3eOriginals.
-- Heights as the old sets: heap 0.275 inside the rim. Guarded by the stall attribute Stalls3e. "QQ STALLS3E".
local SS = game:GetService("ServerStorage")
local ice = workspace.JapanMap["Outdoor market revision"]["Shaved ice stall"]
if ice:GetAttribute("Stalls3e") then return "QQ STALLS3E already done" end
local src = ice:FindFirstChild("kakigori_b")
local A = ice:FindFirstChild("kakigori_a")
if not (src and A and ice:FindFirstChild("kakigori_b2") and ice:FindFirstChild("kakigori_b3")) then return "QQ STALLS3E ABORT: the served sets are not as expected" end
local MAP = {
	blue = "rbxassetid://105519777114505", strawberry = "rbxassetid://103604310008321", mango = "rbxassetid://85964280077006",
	matcha = "rbxassetid://88766334570206", melon = "rbxassetid://120470485138148", grape = "rbxassetid://127649436006571",
	orange = "rbxassetid://90247942182554", peach = "rbxassetid://92898390622500",
}
local pv = ice:GetPivot()
local function flat(v) return Vector3.new(v.X, 0, v.Z).Unit end
local right, look = flat(pv.RightVector), flat(pv.LookVector)
local counter = ice["Service counter"]
local TOP = counter.Position.Y + counter.Size.Y / 2
local CUP = Vector3.new(0.64, 0.47, 0.64)
local BOARD = Vector3.new(1.98, 0.07, 1.98)                              -- (fix-ups: 1.62 x 0.04 hid under the cups)
local STEP = 0.72                                                        -- cup centres in a tray: +-STEP/2 each way
local srcCup = A.KG_CupTex
local mBlue, mStraw, mBear, cream = src.KG_MoundBlue, src.KG_MoundStraw, src.KG_MoundBear, src.KG_Cream
local face = {src["KG_FaceSnow.001"], src.KG_Choco, src.KG_Pink, src.KG_Cookie}
local function at(a, d, y) return Vector3.new(pv.Position.X, y, pv.Position.Z) + right * a + look * d end
local root = Instance.new("Model"); root.Name = "Served kakigori trays"
root:SetAttribute("Stalls3eAdded", true)
local function piece(p, parent)
	local c = p:Clone()
	for _, k in ipairs({"Stalls3cWasColorMap", "Stalls3cWasRoughnessMap", "Stalls3cWasColor", "Stalls2WasScale"}) do c:SetAttribute(k, nil) end
	c.Anchored = true; c.CanCollide = false; c.CanTouch = false; c.CanQuery = false
	c.Parent = parent
	return c
end
local yawN = 0
local function cupAt(parent, pos, yLift)
	yawN += 1
	local c = piece(srcCup, parent)
	c.Name = "Kakigori cup"
	c.Size = CUP
	c.CFrame = CFrame.new(pos + Vector3.new(0, CUP.Y / 2 + (yLift or 0), 0)) * CFrame.Angles(0, math.rad(37 * yawN), 0) * srcCup.CFrame.Rotation
	return c
end
local function heap(parent, kind, flavour, cupTop, pos)
	local s = (kind == "bear" and mBear) or (kind == "straw" and mStraw) or mBlue
	local h = piece(s, parent)
	h.Name = "Kakigori ice (" .. flavour .. ")"
	h:SetAttribute("Flavour", flavour)
	local centre = Vector3.new(pos.X, cupTop - 0.275 + s.Size.Y / 2, pos.Z)
	local turn = 0
	if kind == "bear" then                                                 -- turn the bear so its face looks at the customer
		local dir = flat(face[1].Position - mBear.Position)
		turn = math.atan2(dir:Cross(look).Y, dir:Dot(look))
	end
	h.CFrame = CFrame.new(centre) * CFrame.Angles(0, turn, 0) * s.CFrame.Rotation
	local sa = h:FindFirstChildOfClass("SurfaceAppearance")
	if kind ~= "bear" and sa then sa.ColorMap = MAP[flavour] end
	if kind == "bear" then
		for _, f in ipairs(face) do local c = piece(f, parent); c.CFrame = h.CFrame * (mBear.CFrame:Inverse() * f.CFrame) end
	elseif kind == "straw" and cream then
		local c = piece(cream, parent); c.CFrame = h.CFrame * (mStraw.CFrame:Inverse() * cream.CFrame)
	end
end
-- (3f, her "move the 2 trays right and the empty bowl should be to the left of them": along = the customer's LEFT, so the trays
-- sit at the negative end and the empty cups between them and the shaver)
local TRAYS = {
	{along = -5.6, depth = 4.45, cups = {{"blue", "matcha"}, {"blue", "mango"}, {"straw", "strawberry"}, {"blue", "blue"}}},
	{along = -2.3, depth = 4.55, cups = {{"blue", "grape"}, {"blue", "melon"}, {"bear", "rainbow"}, {"straw", "peach"}}},
}
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before stalls3e") end)
for i, t in ipairs(TRAYS) do
	local tray = Instance.new("Model"); tray.Name = "Serving tray " .. i; tray.Parent = root
	local centre = at(t.along, t.depth, TOP + BOARD.Y / 2)
	-- the shaver set's plain rimmed tray in dark lacquered wood (the set's own board has handles: a cross once stretched square)
	local b = piece(A.KG_Tray, tray); b.Name = "Serving tray board"; b.Size = BOARD; b.CFrame = CFrame.lookAt(centre, centre + look)
	b.Material = Enum.Material.Wood; b.Color = Color3.fromRGB(92, 52, 34)
	local cupBase = TOP + BOARD.Y
	-- rows of two: [1] back left, [2] back right, [3] front left, [4] front right (back = towards the vendor)
	local spots = {{-1, -1}, {1, -1}, {-1, 1}, {1, 1}}
	for k, c in ipairs(t.cups) do
		local p = at(t.along + spots[k][1] * STEP / 2, t.depth + spots[k][2] * STEP / 2, cupBase)
		cupAt(tray, p)
		heap(tray, c[1], c[2], cupBase + CUP.Y, p)
	end
end
-- a little stack of three empty cups at the far end of the counter
do
	local stack = Instance.new("Model"); stack.Name = "Stacked empty cups"; stack.Parent = root
	local p = at(1.0, 4.1, TOP)                                              -- (3f) between the shaver and the trays
	for k = 0, 2 do cupAt(stack, p, k * 0.09) end
end
root.Parent = ice
-- the three old sets out to the backup
local hb = SS:FindFirstChild("HudBackup")
local bk = hb:FindFirstChild("Stalls3eOriginals") or Instance.new("Folder"); bk.Name = "Stalls3eOriginals"; bk.Parent = hb
for _, n in ipairs({"kakigori_b", "kakigori_b2", "kakigori_b3"}) do local m = ice[n]; m:SetAttribute("Stalls3eFrom", m:GetFullName()); m.Parent = bk end
ice:SetAttribute("Stalls3e", "2026-10-23")
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after stalls3e") end)
return "QQ STALLS3E two serving trays (4 cups each, rows of 2) + a stack of 3 empty cups; old sets -> HudBackup.Stalls3eOriginals - EDIT INSTALLED; NOT PUBLISHED"
