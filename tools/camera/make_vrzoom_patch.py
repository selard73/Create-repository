#!/usr/bin/env python3
"""Builds the second camera patch (Oct 9 2026): VR zoom + viewfinder, and photos with ground, sea and far subjects.

Shannon: "the new camera feature allows aim, however it does not allow to zoom out or zoom in, if you could make the
right controller stick for zoom in or zoom out; and the pictures its taking are only picking up certain things in the
environment, the whale picture only got the water spray, not the whale or the ocean; the picture of the treasure hunter
got the squirrel but not the beach or water or anything around him."

Reads italy/camera/CameraClient_v3.lua as left by make_vraim_patch.py (60574 chars = Studio after job 6), takes the OLD
blocks from exact markers, pairs them with the NEW blocks, and writes:
  italy/camera/CameraClient_v3.lua      the patched local copy
  tools/camera/vrzoom_patch.lua         the Studio patch (exact-string finds on workspace.PhotoGame.CameraClient.Source,
                                        backup ServerStorage.HudBackup.CameraClient_v3_pre_vrzoom, compile check, then set)
  tools/camera/vrzoom_selftest.lua      the same finds under the luau CLI, prints the result (must equal the local copy)
Run from the repo root: python3 tools/camera/make_vrzoom_patch.py
"""
import pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "italy/camera/CameraClient_v3.lua"
ORIG_LEN = 60574

text = SRC.read_text(encoding="utf-8")
if len(text) != ORIG_LEN:
    sys.exit(f"CameraClient_v3.lua is {len(text)} chars, expected {ORIG_LEN}: run make_vraim_patch.py first, or already patched")

def between(start_marker, end_marker, include_end=True):
    a = text.index(start_marker)
    b = text.index(end_marker, a)
    assert text.count(start_marker) == 1, start_marker
    return text[a:b + (len(end_marker) if include_end else 0)]

pairs = []

# 1. the VR zoom level, declared before inFrame() and shoot() use it
old1 = "local holding, raised = false, false\n"
assert text.count(old1) == 1
new1 = ("local holding, raised = false, false\n"
        "local vrFov = 50   -- VR zoom (Oct 9): the shot's field of view, right stick up/down; 50 was the fixed value before\n")
pairs.append((old1, new1))

# 2. the VR shot cone follows the zoom (22 degrees at the old fixed 50)
old2 = "\t\treturn ang < 22, ang / 22\n"
assert text.count(old2) == 1
new2 = "\t\tlocal lim = vrFov * 0.44\n\t\treturn ang < lim, ang / lim\n"
pairs.append((old2, new2))

# 3. the photo scene: a box along the line of sight instead of three spheres (far subjects like the whale were falling
#    between them), stand-in ground and sea tiles coloured like the terrain, and extra(world, list)
old3 = between("local function buildWorld(cf, fov, extra, ignore)\n", "\treturn world, #arr\nend\n")
assert old3.endswith("\treturn world, #arr\nend\n")
new3 = '''-- terrain can't be copied into a scene, so the ground and the sea in the shot are stood in for by flat tiles coloured
-- and textured like the terrain under them (Oct 9, Shannon: "the whale picture only got the water spray, not the whale
-- or the ocean; the treasure hunter got the squirrel but not the beach or water or anything around him").
local tparams = RaycastParams.new(); tparams.FilterType = Enum.RaycastFilterType.Include
tparams.FilterDescendantsInstances = {workspace.Terrain}; tparams.IgnoreWater = false
local PART_MAT = {Sand = Enum.Material.Sand, Grass = Enum.Material.Grass, LeafyGrass = Enum.Material.Grass, Rock = Enum.Material.Slate,
	Slate = Enum.Material.Slate, Ground = Enum.Material.Ground, Mud = Enum.Material.Ground, Cobblestone = Enum.Material.Cobblestone,
	Limestone = Enum.Material.Limestone, Pavement = Enum.Material.Pavement, Basalt = Enum.Material.Basalt, Sandstone = Enum.Material.Sandstone,
	Snow = Enum.Material.Snow, Ice = Enum.Material.Ice, Salt = Enum.Material.Salt, Asphalt = Enum.Material.Asphalt, Concrete = Enum.Material.Concrete,
	Brick = Enum.Material.Brick, WoodPlanks = Enum.Material.WoodPlanks, CrackedLava = Enum.Material.CrackedLava, Glacier = Enum.Material.Glacier}
local function terrainTiles(world, cf, fov)
	local T = workspace.Terrain
	if not T then return end
	local look, right = cf.LookVector, cf.RightVector
	local flat = Vector3.new(look.X, 0, look.Z)
	local side = Vector3.new(right.X, 0, right.Z)
	if flat.Magnitude < 0.05 or side.Magnitude < 0.05 then return end
	flat, side = flat.Unit, side.Unit
	local half = math.tan(math.rad(math.min(fov, 80) / 2)) * 1.25
	local r, n = 3, 0
	while r < 300 and n < 240 do
		local stepR = math.max(2.5, r * 0.28)
		local width = r * half * 2 + 6
		local across = math.clamp(math.ceil(width / stepR), 3, 13)
		local sp = width / across
		for k = 0, across - 1 do
			local x = cf.Position + flat * r + side * ((k - (across - 1) / 2) * sp)
			local hit = workspace:Raycast(Vector3.new(x.X, cf.Y + 60, x.Z), Vector3.new(0, -260, 0), tparams)
			if hit then
				local mat = hit.Material
				local t = Instance.new("Part"); t.Anchored = true; t.CanCollide = false; t.CastShadow = false
				t.Size = Vector3.new(sp * 1.08, 0.3, stepR * 1.12)
				local at = hit.Position - Vector3.new(0, 0.15, 0)
				t.CFrame = CFrame.lookAt(at, at + flat)
				if mat == Enum.Material.Water then
					t.Color = T.WaterColor; t.Material = Enum.Material.Glass; t.Transparency = 0.15; t.Reflectance = 0.1
				else
					local okc, col = pcall(T.GetMaterialColor, T, mat)
					t.Color = okc and col or C(150, 140, 120); t.Material = PART_MAT[mat.Name] or Enum.Material.SmoothPlastic
				end
				t.Parent = world
				n += 1
			end
		end
		r += stepR
	end
end
local function buildWorld(cf, fov, extra, ignore)
	local world = Instance.new("WorldModel"); world.Name = "Scene"
	local look = cf.LookVector
	local params = OverlapParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude; params.MaxParts = 4000
	local ex = {workspace.CurrentCamera, workspace.Terrain}
	if player.Character then table.insert(ex, player.Character) end
	for _, x in ipairs(ignore or {}) do table.insert(ex, x) end
	params.FilterDescendantsInstances = ex
	local cosLim = math.cos(math.rad(math.min(80, fov * 0.9)))
	local list = {}
	-- everything in a box along the line of sight (0..320 studs, as wide as the field of view needs), then the ones in the cone
	local half = math.tan(math.rad(math.min(fov, 80) / 2))
	local boxCF = CFrame.lookAt(cf.Position, cf.Position + look) * CFrame.new(0, 0, -160)
	local boxSize = Vector3.new(math.min(640, 320 * half * 2 + 40), math.min(400, 320 * half * 2 + 40), 320)
	for _, p in ipairs(workspace:GetPartBoundsInBox(boxCF, boxSize, params)) do
		if not list[p] and p.Transparency < 0.95 then
			local d = p.Position - cf.Position
			local dist = d.Magnitude
			if dist < 320 and (dist < p.Size.Magnitude * 0.6 or look:Dot(d.Unit) > cosLim) then list[p] = dist end
		end
	end
	local arr = {}
	for p, d in pairs(list) do table.insert(arr, {p, d}) end
	table.sort(arr, function(a, b) return a[2] < b[2] end)
	for i = 1, math.min(600, #arr) do local c = stripCopy(arr[i][1]); if c then c.Parent = world end end
	pcall(terrainTiles, world, cf, fov)
	if extra then pcall(extra, world, list) end
	return world, #arr
end
'''
pairs.append((old3, new3))

# 4. the whale itself is always in a whale photo, not just its spout
old4 = "\t\textra = function(world) local _, mesh = whaleMesh(); spoutBalls(world, whaleSpoutBase(mesh)) end\n"
assert text.count(old4) == 1
new4 = ("\t\textra = function(world, list)\n"
        "\t\t\tlocal _, mesh = whaleMesh()\n"
        "\t\t\tif mesh and not (list and list[mesh]) then local c = stripCopy(mesh); if c then c.Parent = world end end\n"
        "\t\t\tspoutBalls(world, whaleSpoutBase(mesh))\n"
        "\t\tend\n")
pairs.append((old4, new4))

# 5. the VR photo uses the zoom
old5 = "\tlocal camFov = vr() and 50 or workspace.CurrentCamera.FieldOfView\n"
assert text.count(old5) == 1
new5 = "\tlocal camFov = vr() and vrFov or workspace.CurrentCamera.FieldOfView\n"
pairs.append((old5, new5))

# 6. the aim loop: right stick up/down zooms, a square viewfinder floats at the aim point sized to the shot
old6 = between("local aimParams = RaycastParams.new(); aimParams.FilterType = Enum.RaycastFilterType.Exclude\n",
               "RunService.RenderStepped:Connect(function()\n", include_end=True)
new6 = '''local aimParams = RaycastParams.new(); aimParams.FilterType = Enum.RaycastFilterType.Exclude
local function aimHit(cf)   -- where the controller points; invisible parts (boundary walls, prompt spots) are looked through
	local ex = {player.Character}
	local origin, left = cf.Position, 80
	for _ = 1, 5 do
		aimParams.FilterDescendantsInstances = ex
		local hit = workspace:Raycast(origin, cf.LookVector * left, aimParams)
		if not hit then return nil end
		if hit.Instance == workspace.Terrain or hit.Instance.Transparency < 1 then return hit.Position end
		table.insert(ex, hit.Instance)
		left -= (hit.Position - origin).Magnitude; origin = hit.Position
		if left <= 0 then return nil end
	end
	return nil
end
-- the frame of the shot, floating at the aim point: a square as wide as the photo will be at that distance (Oct 9)
local frame = Instance.new("BillboardGui"); frame.Name = "CameraFrame"; frame.AlwaysOnTop = true; frame.LightInfluence = 0; frame.ResetOnSpawn = false
frame.Adornee = aimAtt; frame.Enabled = false; frame.Size = UDim2.fromScale(4, 4); frame.Parent = pg
local frameBox = Instance.new("Frame"); frameBox.Size = UDim2.fromScale(1, 1); frameBox.BackgroundTransparency = 1; frameBox.Parent = frame
local frameStroke = stroke(frameBox, GOLD, 2); frameStroke.Transparency = 0.25
-- right stick up / down = zoom in / out (Shannon, Oct 9); left / right stays Roblox's snap turn
local stickY, zoomSaidAt = 0, 0
UIS.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.Thumbstick2 then stickY = input.Position.Y end
end)
RunService.RenderStepped:Connect(function(dt)
	if raised then hideHeld(true) end
	local on = holding and vr()
	aim.Enabled = on; frame.Enabled = on
	if on then
		if math.abs(stickY) > 0.25 then
			local f = math.clamp(vrFov - stickY * dt * 40, 14, 70)
			if f ~= vrFov then
				vrFov = f
				if os.clock() - zoomSaidAt > 0.3 then zoomSaidAt = os.clock(); toast(string.format("Zoom %.1fx", 50 / vrFov), 1.5) end
			end
		end
		local cf = shotCF()
		handAtt.WorldPosition = cf.Position
		local at = aimHit(cf) or (cf.Position + cf.LookVector * 40)
		aimAtt.WorldPosition = at
		local w = 2 * (at - cf.Position).Magnitude * math.tan(math.rad(vrFov) / 2) * 0.9
		frame.Size = UDim2.fromScale(w, w)
		beam.Enabled = vrHandCF() ~= nil
		if os.clock() - aimCheckAt > 0.05 then
			aimCheckAt = os.clock()
			local ok, s = pcall(evaluate, cf)
			local locked = ok and s ~= nil and (player:GetAttribute("Item_photo_" .. s.id) or 0) < 1
			if locked ~= aimLocked then aimLocked = locked; setRing(locked) end
		end
	else
		beam.Enabled = false
		if aimLocked then aimLocked = false; setRing(false) end
	end
end)
'''
# old6 ends with the start of the old RenderStepped block; the rest of that old block must go too: extend old6 to its end
old6_full = between("local aimParams = RaycastParams.new(); aimParams.FilterType = Enum.RaycastFilterType.Exclude\n",
                    "\t\tif aimLocked then aimLocked = false; setRing(false) end\n\tend\nend)\n")
assert old6_full.startswith(old6)
pairs.append((old6_full, new6))

# apply to the local copy
patched = text
for i, (old, new) in enumerate(pairs, 1):
    assert patched.count(old) == 1, f"pair {i}: old text found {patched.count(old)} times"
    assert "]==]" not in old and "]==]" not in new
    patched = patched.replace(old, new)
SRC.write_text(patched, encoding="utf-8")
print(f"patched local copy: {len(patched)} chars (was {ORIG_LEN})")

def lua_long(s):
    return "[==[\n" + s + "]==]"

lua = []
lua.append('-- camera/vrzoom_patch: EDIT mode. Second camera patch, Oct 9 2026 (Shannon: VR "does not allow to zoom out or zoom in ...')
lua.append('-- make the right controller stick for zoom"; photos "only picking up certain things ... not the whale or the ocean ... not')
lua.append('-- the beach"). Patches workspace.PhotoGame.CameraClient.Source with exact string finds: right stick up/down zooms the VR')
lua.append('-- shot (14..70 degrees, 50 = before) with a floating square viewfinder sized to the shot; photos gather parts from a box')
lua.append('-- along the line of sight (far subjects like the whale were falling between the old spheres), stand-in ground and sea tiles')
lua.append('-- coloured like the terrain, and the whale itself is always in a whale photo. Desktop / phone photos get the tiles and the')
lua.append(f'-- box too; nothing else changes there. Refuses to run unless the Source is the job 6 text ({ORIG_LEN} chars) and every find')
lua.append('-- hits exactly once. Original -> ServerStorage.HudBackup.CameraClient_v3_pre_vrzoom. Output: "QQ VRZ".')
lua.append('if game:GetService("RunService"):IsRunning() then warn("QQ VRZ ABORT - Play mode") return end')
lua.append('local G = workspace:FindFirstChild("PhotoGame")')
lua.append('local S = G and G:FindFirstChild("CameraClient")')
lua.append('if not (S and S:IsA("LuaSourceContainer")) then warn("QQ VRZ ABORT - workspace.PhotoGame.CameraClient not found") return end')
lua.append("local src = S.Source")
lua.append(f'if #src ~= {ORIG_LEN} then warn("QQ VRZ ABORT - CameraClient.Source is " .. #src .. " chars, expected {ORIG_LEN} (job 6 not applied, or already patched)") return end')
lua.append("local PAIRS = {")
for old, new in pairs:
    lua.append("\t{" + lua_long(old) + ",\n\t" + lua_long(new) + "},")
lua.append("}")
lua.append("""for i, p in ipairs(PAIRS) do
	local a, b = src:find(p[1], 1, true)
	if not a then warn("QQ VRZ ABORT - find " .. i .. " not found; nothing changed") return end
	if src:find(p[1], b + 1, true) then warn("QQ VRZ ABORT - find " .. i .. " matches more than once; nothing changed") return end
end
local out = src
for i, p in ipairs(PAIRS) do
	local a, b = out:find(p[1], 1, true)
	out = out:sub(1, a - 1) .. p[2] .. out:sub(b + 1)
end
local f, err = loadstring(out)
if not f then warn("QQ VRZ ABORT - patched source does not compile: " .. tostring(err) .. "; nothing changed") return end
local SS = game:GetService("ServerStorage")
local hb = SS:FindFirstChild("HudBackup")
if not hb then hb = Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS end
if not hb:FindFirstChild("CameraClient_v3_pre_vrzoom") then
	local bk = S:Clone(); bk.Name = "CameraClient_v3_pre_vrzoom"
	pcall(function() bk.Enabled = false end)
	bk.Parent = hb
end
S.Source = out
print(string.format("QQ VRZ DONE: CameraClient patched, %d -> %d chars, %d finds, backup ServerStorage.HudBackup.CameraClient_v3_pre_vrzoom", #src, #out, #PAIRS))""")
(ROOT / "tools/camera/vrzoom_patch.lua").write_text("\n".join(lua) + "\n", encoding="utf-8")
print("wrote tools/camera/vrzoom_patch.lua")

lvl = "=" * 5
assert ("]" + lvl + "]") not in text
st = ["local src = [" + lvl + "[\n" + text + "]" + lvl + "]", "local PAIRS = {"]
for old, new in pairs:
    st.append("\t{" + lua_long(old) + ",\n\t" + lua_long(new) + "},")
st.append("}")
st.append("""local out = src
for i, p in ipairs(PAIRS) do
	local a, b = out:find(p[1], 1, true)
	assert(a, "find " .. i .. " not found")
	assert(not out:find(p[1], b + 1, true), "find " .. i .. " twice")
	out = out:sub(1, a - 1) .. p[2] .. out:sub(b + 1)
end
print(out)""")
(ROOT / "tools/camera/vrzoom_selftest.lua").write_text("\n".join(st) + "\n", encoding="utf-8")
print("wrote tools/camera/vrzoom_selftest.lua")
