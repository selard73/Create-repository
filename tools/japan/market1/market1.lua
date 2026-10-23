-- market1 (Oct 22 2026): Japan market fixes Shannon flagged, run once in Edit.
-- 1 lantern lettering painted on the lanterns (Decals, both sides) instead of flat cards hung in front; cards kept in backup
-- 2 cat cafe lantern cream instead of red ("we don't want cat cafe to look like a bar")
-- 3 rice shop: both lanterns hang in front of the noren from the awning's front rail (were hidden behind it)
-- 4 rice shop: the six back crates moved clear of the shelves; the "today's pick" sign moved off the shelf to the clear wall
-- 5 every market back door/window: the dark recess no longer pokes 0.1 through the back wall into the shop (30 pieces)
-- 6 pickle stall: tubs back, tasting plates forward, so the plates sit in front of the tubs instead of inside them
-- Backups: ServerStorage.HudBackup.Market1Originals (clones, each with Market1From = original path).
local jm = workspace:FindFirstChild("JapanMap")
assert(jm, "no JapanMap")
if jm:GetAttribute("Market1") then return "QQ MARKET1 already installed - nothing done" end
local mk = jm["Outdoor market revision"]
local hb = game:GetService("ServerStorage").HudBackup
assert(not hb:FindFirstChild("Market1Originals"), "Market1Originals already exists")
local bk = Instance.new("Folder")
bk.Name = "Market1Originals"
bk.Parent = hb
local out = {}
local function p(s) table.insert(out, s) end
local function keep(inst, tag)
	local c = inst:Clone()
	c:SetAttribute("Market1From", inst:GetFullName())
	c.Name = tag .. "__" .. inst.Name
	c.Parent = bk
end
local function topShop(inst)
	local s = inst
	while s.Parent and s.Parent ~= mk do s = s.Parent end
	return s
end

-- 1 + 2: lantern lettering
local IMG = {
	["喫"] = {"rbxassetid://90216340812751", "喫茶"},
	["米"] = {"rbxassetid://97728418537829", "米"},
	["傘"] = {"rbxassetid://76422318337897", "和傘"},
	["着"] = {"rbxassetid://115573287916919", "着物"},
	["き"] = {"rbxassetid://132180688018801", "きもの"},
	["文"] = {"rbxassetid://113957330213339", "文具"},
	["もち"] = {"rbxassetid://130648709541601", "もち"},
}
local CREAM = Color3.fromRGB(239, 218, 171)
local function faces(part, dir)
	local v = part.CFrame:VectorToObjectSpace(dir)
	local ax, ay, az = math.abs(v.X), math.abs(v.Y), math.abs(v.Z)
	if ax >= ay and ax >= az then
		if v.X > 0 then return Enum.NormalId.Right, Enum.NormalId.Left end
		return Enum.NormalId.Left, Enum.NormalId.Right
	end
	assert(az >= ay, "lantern faces up/down?")
	if v.Z > 0 then return Enum.NormalId.Back, Enum.NormalId.Front end
	return Enum.NormalId.Front, Enum.NormalId.Back
end
local cards = {}
for _, d in ipairs(mk:GetDescendants()) do
	if d:IsA("BasePart") and d.Name == "Handwritten shop sign"
		and math.abs(d.Size.X - 0.8) < 0.05 and math.abs(d.Size.Y - 1.45) < 0.05 then
		local tl = d:FindFirstChildWhichIsA("TextLabel", true)
		if tl and IMG[tl.Text] then table.insert(cards, {card = d, key = tl.Text}) end
	end
end
assert(#cards == 8, "expected 8 lantern cards, found " .. #cards)
for _, c in ipairs(cards) do
	local card, info = c.card, IMG[c.key]
	local shop = topShop(card)
	local best, bestD = nil, 1.6
	for _, q in ipairs(shop:GetDescendants()) do
		if q:IsA("Part") and q.Name == "Paper lantern" and q.Shape == Enum.PartType.Ball then
			local dd = (q.Position - card.Position).Magnitude
			if dd < bestD then best, bestD = q, dd end
		end
	end
	assert(best, "no lantern near the card in " .. shop.Name)
	keep(best, "Lantern")
	local front, back = faces(best, card.CFrame.LookVector)
	for i, f in ipairs({front, back}) do
		local dc = Instance.new("Decal")
		dc.Name = i == 1 and "LanternLettering" or "LanternLetteringBack"
		dc.Texture = info[1]
		dc.Face = f
		dc.Parent = best
	end
	best:SetAttribute("Market1Lettering", info[2])
	if c.key == "喫" then
		best:SetAttribute("Market1WasColor", best.Color)
		best.Color = CREAM
		p("QQ MARKET1 CAFE LANTERN: cream instead of red")
	end
	card:SetAttribute("Market1From", card:GetFullName())
	card.Name = "LanternCard__" .. shop.Name
	card.Parent = bk -- the card itself is kept in the backup, not deleted
	p(string.format("QQ MARKET1 LETTERING: %s %s painted on both sides (%s/%s); card removed", shop.Name, info[2], front.Name, back.Name))
end

-- 3: rice lanterns in front of the noren, hung from the awning rail by a small hook
local rice = mk["Rice and provisions"]
local RAIL_X, LANTERN_X, HOOK_Y = 6009.0, 6008.1, 8.34
local ASSEMBLY = {["Paper lantern"] = true, ["Lantern cap"] = true, ["Paper rib"] = true, ["Lantern cord"] = true}
local lanterns = {}
for _, q in ipairs(rice:GetChildren()) do
	if q:IsA("Part") and q.Name == "Paper lantern" then table.insert(lanterns, q) end
end
assert(#lanterns == 2, "expected 2 rice lanterns")
for _, L in ipairs(lanterns) do
	local L0 = L.Position
	local shift = Vector3.new(LANTERN_X - L0.X, 0, 0)
	local cord
	local n = 0
	for _, q in ipairs(rice:GetChildren()) do
		if q:IsA("BasePart") and ASSEMBLY[q.Name] and math.abs(q.Position.X - L0.X) < 0.9
			and math.abs(q.Position.Z - L0.Z) < 0.9 and q.Position.Y > 5 and q.Position.Y < 9.6 then
			if q ~= L then keep(q, "RiceLantern") end
			q:SetAttribute("Market1WasCFrame", q.CFrame)
			q.CFrame = q.CFrame + shift
			n += 1
			if q.Name == "Lantern cord" then cord = q end
		end
	end
	assert(cord and n >= 12, "rice lantern assembly incomplete: " .. n)
	local top = L.Position.Y + L.Size.Y / 2 - 0.02
	cord:SetAttribute("Market1WasSize", cord.Size)
	cord.Size = Vector3.new(0.04, HOOK_Y - top + 0.02, 0.04)
	cord.CFrame = CFrame.new(LANTERN_X, (top + HOOK_Y + 0.02) / 2, L0.Z)
	local arm = cord:Clone()
	arm.Name = "Lantern hook arm"
	arm.Size = Vector3.new(RAIL_X - LANTERN_X + 0.04, 0.04, 0.04)
	arm.CFrame = CFrame.new((RAIL_X + LANTERN_X) / 2, HOOK_Y, L0.Z)
	arm:SetAttribute("Market1Added", true)
	arm.Parent = rice
	local stub = cord:Clone()
	stub.Name = "Lantern hook stub"
	stub.Size = Vector3.new(0.04, HOOK_Y - 8.09 + 0.02, 0.04)
	stub.CFrame = CFrame.new(RAIL_X, (8.09 + HOOK_Y + 0.02) / 2, L0.Z)
	stub:SetAttribute("Market1Added", true)
	stub.Parent = rice
	p(string.format("QQ MARKET1 RICE LANTERN: z %.1f moved %.2f toward the lane, in front of the noren, hooked to the rail (%d parts)", L0.Z, shift.X, n))
end

-- 4: rice crates clear of the shelves; today's-pick sign off the shelf
local moved = 0
for _, m in ipairs(rice:GetChildren()) do
	if m:IsA("Model") and m.Name == "Produce display" and m:GetPivot().X > 6025 then
		keep(m, "RiceCrate")
		m:SetAttribute("Market1WasPivot", m:GetPivot())
		m:PivotTo(m:GetPivot() + Vector3.new(-2.6, 0, 0))
		moved += 1
	end
end
assert(moved == 6, "expected 6 back crates, moved " .. moved)
p("QQ MARKET1 RICE CRATES: 6 back crates moved 2.6 forward, clear of both shelf units")
local signDone = false
for _, s in ipairs(rice:GetChildren()) do
	local tl = s:IsA("BasePart") and s:FindFirstChildWhichIsA("TextLabel", true)
	if tl and tl.Text:find("本日") then
		keep(s, "RiceSign")
		s:SetAttribute("Market1WasCFrame", s.CFrame)
		s.CFrame = CFrame.new(6032.75, 6.3, -193.26) * s.CFrame.Rotation
		signDone = true
	end
end
assert(signDone, "today's-pick sign not found")
p("QQ MARKET1 RICE SIGN: 本日のおすすめ sign moved off the shelf to the wall between the two shelf units")

-- 5: back-door/window recesses no longer poke into the shops
local function along(q, n)
	local cf, sz = q.CFrame, q.Size
	local c = q.Position:Dot(n)
	local h = (math.abs(cf.RightVector:Dot(n)) * sz.X + math.abs(cf.UpVector:Dot(n)) * sz.Y + math.abs(cf.LookVector:Dot(n)) * sz.Z) / 2
	return c - h, c + h
end
local fixed = 0
for _, m in ipairs(jm.ShopBacks:GetChildren()) do
	local shopName = m.Name:match("^(.-)_[^_]+$")
	local shop = shopName and mk:FindFirstChild(shopName)
	local wall = shop and shop:FindFirstChild("Back wall")
	if wall then
		local axes = {wall.CFrame.RightVector, wall.CFrame.UpVector, wall.CFrame.LookVector}
		local sizes = {wall.Size.X, wall.Size.Y, wall.Size.Z}
		local ti = 1
		for i = 2, 3 do if sizes[i] < sizes[ti] then ti = i end end
		local n = axes[ti]
		local frame = shop:GetAttribute("MarketFrame")
		local centre = typeof(frame) == "CFrame" and frame.Position or shop:GetPivot().Position
		if (centre - wall.Position):Dot(n) < 0 then n = -n end
		local inner = wall.Position:Dot(n) + sizes[ti] / 2
		for _, q in ipairs(m:GetDescendants()) do
			if q:IsA("BasePart") and q.Name:match("Reveal$") then
				local _, hi = along(q, n)
				local rel = wall.CFrame:PointToObjectSpace(q.Position)
				local near = math.abs(rel.X) < wall.Size.X / 2 + 0.5 and math.abs(rel.Y) < wall.Size.Y / 2 + 0.5 and math.abs(rel.Z) < wall.Size.Z / 2 + 0.5
				if near and hi > inner + 0.005 then
					local cut = hi - (inner - 0.03)
					local la = {q.CFrame.RightVector, q.CFrame.UpVector, q.CFrame.LookVector}
					local ai = 1
					for i = 2, 3 do if math.abs(la[i]:Dot(n)) > math.abs(la[ai]:Dot(n)) then ai = i end end
					local s = {q.Size.X, q.Size.Y, q.Size.Z}
					assert(s[ai] - cut > 0.15, "reveal too thin to trim: " .. q:GetFullName())
					keep(q, "Reveal")
					q:SetAttribute("Market1WasSize", q.Size)
					q:SetAttribute("Market1WasCFrame", q.CFrame)
					s[ai] -= cut
					local cf = q.CFrame
					q.Size = Vector3.new(s[1], s[2], s[3])
					q.CFrame = cf - n * (cut / 2)
					fixed += 1
				end
			end
		end
	end
end
p(string.format("QQ MARKET1 BACK RECESSES: %d dark door/window recesses trimmed to stop at the back wall; outside faces unchanged", fixed))

-- 6: pickle stall plates in front of the tubs
local st = mk["Pickle stall"]
local tubs, dishes = st["Tsukemono pickle tubs"], st["Pickle tasting dishes"]
keep(tubs, "Pickle")
keep(dishes, "Pickle")
tubs:SetAttribute("Market1WasPivot", tubs:GetPivot())
dishes:SetAttribute("Market1WasPivot", dishes:GetPivot())
tubs:PivotTo(tubs:GetPivot() + Vector3.new(-0.62, 0, 0))
dishes:PivotTo(dishes:GetPivot() + Vector3.new(0.06, 0, 0))
p("QQ MARKET1 PICKLE PLATES: tubs 0.62 back, plates 0.06 forward - each plate now sits on the counter in front of its tub")

jm:SetAttribute("Market1", "2026-10-22")
p("QQ MARKET1 BACKUP: " .. #bk:GetChildren() .. " originals in ServerStorage.HudBackup.Market1Originals")
p("QQ MARKET1 STATUS: EDIT INSTALLED; NOT PUBLISHED")
return table.concat(out, "\n")
