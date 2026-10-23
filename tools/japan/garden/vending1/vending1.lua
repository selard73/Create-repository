-- vending1.lua (Oct 22 2026): the drinks vending machine by Lantern Street station.
-- Shannon: the old "Blue vending machine" (a part-built blue box) "is floating and it is way too basic, it needs to look more
-- realistic with more details and sit on the ground" -> "build a realistic Japanese drinks vending machine at that spot, sitting
-- on the ground beside the path". Kit japan_kit37_vending1.fbx (vending1/gen_vending1.py): vending_machine + recycle_bin.
--  1. a loose Import 3D of the kit in workspace is anchored and moved into ServerStorage.JapanGardenKit (as the other kits)
--  2. the old machine moves whole to ServerStorage.HudBackup.BlueVendingMachine_pre_vending1
--  3. JapanMap.LanternStreet.DrinksVendingMachine: the machine on its pad just north of the stepping-stone path (Path5, z ~80),
--     front to the path; the bin at its left as you face it; ground found by ray; colours/materials per mesh; header and bin
--     words as SurfaceGuis; a soft light in the display
-- Re-runnable: DrinksVendingMachine is rebuilt; the backup is made once. Output "QQ VENDING1".
local SS = game:GetService("ServerStorage")
local J = workspace:FindFirstChild("JapanMap")
local LS = J and J:FindFirstChild("LanternStreet")
local KIT = SS:FindFirstChild("JapanGardenKit")
local hb = SS:FindFirstChild("HudBackup")
if not (J and LS and KIT and hb) then return "QQ VENDING1 ABORT: JapanMap.LanternStreet, JapanGardenKit or HudBackup missing" end
local out = {}
local function say(s) table.insert(out, "QQ VENDING1 " .. s) end
local function key(p) return (p.Name:gsub("%.%d+$", "")) end
local function find(m, name) for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") and key(d) == name then return d end end end

-- 1. adopt a loose import
local function findLoose(name)
	for _, top in ipairs(workspace:GetChildren()) do
		if top:IsA("Model") and top ~= J then
			if top.Name == name then return top end
			local m = top:FindFirstChild(name, true)
			if m and m:IsA("Model") then return m, top end
		end
	end
end
for _, n in ipairs({"vending_machine", "recycle_bin"}) do
	if not KIT:FindFirstChild(n) then
		local m, wrapper = findLoose(n)
		if not m then return "QQ VENDING1 ABORT: no '" .. n .. "' in JapanGardenKit or workspace - import japan_kit37_vending1.fbx first" end
		for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true end end
		m.Parent = KIT
		if wrapper and #wrapper:GetDescendants() == 0 then wrapper:Destroy() end
		say("kit: " .. n .. " anchored and stored in ServerStorage.JapanGardenKit")
	end
end
for _, n in ipairs({"vending_machine", "recycle_bin"}) do
	for _, part in ipairs({"VM_Flap", "VM_Header", "VM_Backlight", "VM_Pad", "BIN_Label"}) do
		if (n == "vending_machine") == (part:sub(1, 3) == "VM_") and not find(KIT[n], part) then
			return "QQ VENDING1 ABORT: kit piece " .. n .. " has no " .. part
		end
	end
end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before vending1") end)

-- 2. the old machine to the backup, whole
local old = LS:FindFirstChild("Blue vending machine")
if old then
	old:SetAttribute("Vending1From", old:GetFullName())
	old.Name = "BlueVendingMachine_pre_vending1"
	old.Parent = hb
	say("old blue box kept whole in ServerStorage.HudBackup.BlueVendingMachine_pre_vending1")
end
local prev = LS:FindFirstChild("DrinksVendingMachine"); if prev then prev:Destroy() end

-- 3. the new machine
local C = Color3.fromRGB
local SP, MET = Enum.Material.SmoothPlastic, Enum.Material.Metal
local LOOK = {
	VM_Body = {SP, C(41, 92, 168), true}, VM_Frame = {SP, C(237, 240, 242), true}, VM_Header = {SP, C(248, 248, 250), true},
	VM_Backlight = {SP, C(250, 250, 247), false}, VM_Glass = {SP, C(205, 230, 242), true}, VM_Shelf = {SP, C(214, 217, 222), false},
	VM_StripBlue = {SP, C(38, 97, 191), false}, VM_StripRed = {SP, C(204, 38, 33), false}, VM_PriceTag = {SP, C(250, 250, 242), false},
	VM_Button = {SP, C(158, 191, 219), false}, VM_Kick = {SP, C(64, 66, 71), true}, VM_Pad = {Enum.Material.Concrete, C(158, 156, 148), true},
	VM_PortDark = {SP, C(20, 20, 23), false}, VM_Flap = {SP, C(56, 64, 71), false}, VM_Chrome = {MET, C(191, 196, 204), false},
	VM_Trim = {MET, C(140, 145, 153), false}, VM_LED = {SP, C(15, 15, 18), false}, VM_LEDDigits = {Enum.Material.Neon, C(230, 38, 26), false},
	VM_SlotGreen = {Enum.Material.Neon, C(51, 217, 102), false}, VM_ICPad = {SP, C(115, 184, 235), false},
	VM_Graphic = {SP, C(89, 166, 230), false}, VM_GraphicWave = {SP, C(247, 250, 255), false}, VM_SideStripe = {SP, C(247, 250, 255), false},
	D_Silver = {MET, C(204, 207, 212), false}, D_Brown = {SP, C(77, 46, 28), false}, D_Gold = {SP, C(209, 161, 66), false},
	D_Red = {SP, C(204, 31, 28), false}, D_Orange = {SP, C(247, 140, 31), false}, D_Purple = {SP, C(115, 56, 140), false},
	D_Yellow = {SP, C(245, 212, 64), false}, D_Blue = {SP, C(46, 115, 217), false}, D_White = {SP, C(245, 245, 240), false},
	D_Green = {SP, C(56, 133, 61), false}, D_Tea = {SP, C(163, 179, 77), false}, D_Amber = {SP, C(199, 128, 46), false},
	D_Water = {SP, C(204, 232, 247), false}, D_Cream = {SP, C(230, 204, 158), false},
	BIN_Body = {SP, C(240, 242, 245), true}, BIN_Lid = {SP, C(41, 92, 168), true}, BIN_Hole = {SP, C(18, 18, 20), false},
	BIN_Label = {SP, C(252, 252, 250), false},
}
local unknown = {}
local function dress(m)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			local k = key(p)
			local d = LOOK[k]
			if not d then unknown[k] = true; d = {SP, C(200, 200, 200), false} end
			p.Anchored = true; p.CanTouch = false; p.CastShadow = true
			p.Material = d[1]; p.Color = d[2]; p.CanCollide = d[3]; p.CanQuery = d[3]
			if p:IsA("MeshPart") then p.DoubleSided = false end
			if k == "VM_Glass" then p.Transparency = 0.88; p.Reflectance = 0.06; p.CastShadow = false end
		end
	end
end
local function faceToward(part, dir)
	local v = part.CFrame:VectorToObjectSpace(dir)
	local ax, ay, az = math.abs(v.X), math.abs(v.Y), math.abs(v.Z)
	if ax >= ay and ax >= az then return v.X > 0 and Enum.NormalId.Right or Enum.NormalId.Left end
	if az >= ay then return v.Z > 0 and Enum.NormalId.Back or Enum.NormalId.Front end
	return v.Y > 0 and Enum.NormalId.Top or Enum.NormalId.Bottom
end
local function label(parent, text, colour, pos, size, align)
	local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.Position = pos; t.Size = size
	t.Font = Enum.Font.GothamBold; t.TextScaled = true; t.TextColor3 = colour; t.Text = text
	t.TextXAlignment = align or Enum.TextXAlignment.Center; t.Parent = parent
	return t
end
local F = Instance.new("Model"); F.Name = "DrinksVendingMachine"
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {F, KIT}
local function ground(x, z)
	local o = Vector3.new(x, 60, z)
	for _ = 1, 8 do
		local h = workspace:Raycast(o, Vector3.new(0, -100, 0), rp)
		if not h then return nil end
		if h.Instance == workspace.Terrain or h.Instance.CanCollide then return h.Position.Y, h.Instance end
		o = h.Position - Vector3.new(0, 0.05, 0)
	end
end
local WANT = Vector3.new(0, 0, -1)                                -- both face the path, south of them
local function place(name, at, frontName, lineAboveMin)
	local m = KIT[name]:Clone()
	dress(m)
	m.WorldPivot = CFrame.new(m:GetPivot().Position)              -- upright, unturned pivot
	local cf, sz = m:GetBoundingBox()
	m.WorldPivot = CFrame.new(cf.Position.X, cf.Position.Y - sz.Y / 2 + lineAboveMin, cf.Position.Z)
	local marker = find(m, frontName)
	local f = marker.Position - cf.Position; f = Vector3.new(f.X, 0, f.Z).Unit
	local yaw = math.atan2(f:Cross(WANT).Y, f:Dot(WANT))
	yaw = math.rad(math.floor(math.deg(yaw) / 90 + 0.5) * 90)    -- a quarter turn: the drawer marker sits off-centre
	local hx, hz = sz.X / 2 - 0.2, sz.Z / 2 - 0.2
	local gy, gi = -1e9, nil
	for _, o in ipairs({Vector3.new(0, 0, 0), Vector3.new(hx, 0, hz), Vector3.new(-hx, 0, hz), Vector3.new(hx, 0, -hz), Vector3.new(-hx, 0, -hz)}) do
		local y, inst = ground(at.X + o.X, at.Z + o.Z)
		if y and y > gy then gy, gi = y, inst end
	end
	assert(gi, "no ground under " .. name)
	m:PivotTo(CFrame.new(at.X, gy, at.Z) * CFrame.Angles(0, yaw, 0))
	m.Name = name
	m.Parent = F
	return m, gy, gi, math.deg(yaw)
end
local MACHINE_AT = Vector3.new(6027, 0, 83.675)                  -- pad front edge at z ~81.95, just north of the path's edge
local BIN_AT = Vector3.new(6030.53, 0, 82.98)                    -- left of the machine as you face it, fronts in line
local vm, gy1, g1, yaw1 = place("vending_machine", MACHINE_AT, "VM_Flap", 0.30)   -- the pad is sunk 0.30 into the lawn
local bin, gy2, g2, yaw2 = place("recycle_bin", BIN_AT, "BIN_Label", 0.02)
say(string.format("machine on %s at y %.2f (turned %.0f deg), bin on %s at y %.2f (turned %.0f deg)", g1.Name, gy1, yaw1, g2.Name, gy2, yaw2))

-- words + light
local header = find(vm, "VM_Header")
local sg = Instance.new("SurfaceGui"); sg.Name = "Words"; sg.Face = faceToward(header, WANT)
sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 60; sg.LightInfluence = 0.3; sg.Parent = header
local BLUE = C(41, 92, 168)
label(sg, "のみもの", BLUE, UDim2.fromScale(0.05, 0.1), UDim2.fromScale(0.55, 0.8), Enum.TextXAlignment.Left)
label(sg, "DRINKS", BLUE, UDim2.fromScale(0.62, 0.28), UDim2.fromScale(0.33, 0.46), Enum.TextXAlignment.Right)
local plate = find(bin, "BIN_Label")
local sb = Instance.new("SurfaceGui"); sb.Name = "Words"; sb.Face = faceToward(plate, WANT)
sb.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sb.PixelsPerStud = 80; sb.LightInfluence = 0.6; sb.Parent = plate
label(sb, "あきかん・ペットボトル", BLUE, UDim2.fromScale(0.05, 0.08), UDim2.fromScale(0.9, 0.48))
label(sb, "CANS & BOTTLES", C(90, 110, 140), UDim2.fromScale(0.12, 0.6), UDim2.fromScale(0.76, 0.3))
local back = find(vm, "VM_Backlight")
local L = Instance.new("SurfaceLight"); L.Name = "DisplayLight"; L.Face = faceToward(back, WANT)
L.Brightness = 0.8; L.Range = 5; L.Angle = 120; L.Color = C(240, 248, 255); L.Shadows = false; L.Parent = back

-- what the new pieces run into (the lawn and path they stand in excepted)
local op = OverlapParams.new(); op.FilterType = Enum.RaycastFilterType.Exclude; op.FilterDescendantsInstances = {F, KIT, workspace.Terrain}
local hit = {}
for _, p in ipairs(F:GetDescendants()) do
	if p:IsA("BasePart") and p.CanCollide then
		for _, q in ipairs(workspace:GetPartsInPart(p, op)) do
			if q.Transparency < 0.95 and q.Position.Y + q.Size.Y / 2 > math.max(gy1, gy2) + 0.12 then hit[q:GetFullName():sub(-60)] = true end
		end
	end
end
local hits = {}; for k in pairs(hit) do table.insert(hits, k) end
F:SetAttribute("VendingVersion", "vending1")
F.Parent = LS
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after vending1") end)
local unk = {}; for k in pairs(unknown) do table.insert(unk, k) end
if #unk > 0 then say("UNKNOWN mesh names (grey): " .. table.concat(unk, ", ")) end
say(#hits > 0 and ("OVERLAPS " .. table.concat(hits, " | ")) or "no overlaps")
say("DONE: JapanMap.LanternStreet.DrinksVendingMachine - EDIT INSTALLED; NOT PUBLISHED")
return table.concat(out, "\n")
