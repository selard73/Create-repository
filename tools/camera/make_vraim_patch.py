#!/usr/bin/env python3
"""Builds the VR aim patch for CameraClient v3 (Oct 9 2026, Shannon: "you can't really aim the shot with the golden circle").

Reads italy/camera/CameraClient_v3.lua (the local copy, byte-identical to Studio: 56602 chars), takes the OLD blocks from
exact line ranges, pairs them with the NEW blocks below, and writes:
  italy/camera/CameraClient_v3.lua         the patched local copy (so local copy = Studio again after the patch is applied)
  tools/camera/vraim_patch.lua             the Studio patch: exact-string finds on workspace.PhotoGame.CameraClient.Source,
                                           backup to ServerStorage.HudBackup.CameraClient_v3_pre_vraim, compile check, then set
  tools/camera/vraim_selftest.lua          runs the same finds on the original text under the luau CLI and prints the result,
                                           so the Lua patch can be proven to give exactly the Python result
Run from the repo root: python3 tools/camera/make_vraim_patch.py
"""
import pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "italy/camera/CameraClient_v3.lua"
ORIG_LEN = 56602

text = SRC.read_text(encoding="utf-8")
if len(text) != ORIG_LEN:
    sys.exit(f"CameraClient_v3.lua is {len(text)} chars, expected {ORIG_LEN}: already patched, or not the Oct 8 copy")
lines = text.split("\n")

def block(first, last):           # 1-based inclusive line range, joined without a trailing newline
    return "\n".join(lines[first - 1:last])

pairs = []

# 1. header: what VR does now
old1 = "VR: aim with the camera in your hand (gold ring); the photo\n-- floats in front of you."
assert old1 in block(7, 8)
new1 = ("VR: point your controller (a gold beam and ring show where;\n"
        "-- the ring fills in while a postcard sight is in the shot) and pull the trigger; the photo floats in front of you.")
pairs.append((old1, new1))

# 2. shotCF: aim from the tracked controller instead of the avatar's hand
old2 = block(196, 204)
assert old2.startswith("local function shotCF()") and old2.endswith("\treturn cam.CFrame\nend"), old2
new2 = """-- VR aim (Oct 9, Shannon: "you can't really aim the shot with the golden circle"): the avatar's hand follows its walking
-- animation, not the player, so the held camera pointed wherever the arm swung. The aim is now the controller itself
-- (its tracked CFrame, in world space), with the wrist's roll removed so photos come out level. Attr VRAimPitch
-- (degrees) tips it: 0 = straight along the controller, negative = down, for a resting grip. Attr VRAimHand "Left" uses
-- the left controller and its trigger. No tracked controller = the headset's view.
local function vrHandCF()
	local cam = workspace.CurrentCamera
	if not cam then return nil end
	local want = G:GetAttribute("VRAimHand") == "Left" and Enum.UserCFrame.LeftHand or Enum.UserCFrame.RightHand
	local other = want == Enum.UserCFrame.LeftHand and Enum.UserCFrame.RightHand or Enum.UserCFrame.LeftHand
	local hand = VRService:GetUserCFrameEnabled(want) and want or (VRService:GetUserCFrameEnabled(other) and other or nil)
	if not hand then return nil end
	local u = VRService:GetUserCFrame(hand)
	local world = cam.CFrame * (u.Rotation + u.Position * cam.HeadScale) * CFrame.Angles(math.rad(num("VRAimPitch", 0)), 0, 0)
	local look = world.LookVector
	return CFrame.lookAt(world.Position, world.Position + look, math.abs(look.Y) > 0.99 and Vector3.zAxis or Vector3.yAxis)
end
local function shotCF()
	local cam = workspace.CurrentCamera
	if vr() then return vrHandCF() or cam:GetRenderCFrame() end
	return cam.CFrame
end"""
pairs.append((old2, new2))

# 3. the equip hint in VR
old3 = 'toast(vr() and "Pull the trigger to take a photo" or touch and "Tap to raise the camera" or "Click to raise the camera", 2.5)'
assert text.count(old3) == 1
new3 = ('toast(vr() and "Aim with the controller. When the ring fills in, pull the trigger."'
        ' or touch and "Tap to raise the camera" or "Click to raise the camera", vr() and 4 or 2.5)')
pairs.append((old3, new3))

# 4. the aim ring: beam from the controller, ring lights up when a wanted sight is in the shot
old4 = block(914, 929)
assert old4.startswith("-- in VR: a gold ring where the camera in your hand is pointing") and old4.endswith("\nend)"), old4
new4 = """-- in VR: a gold beam from your controller to a gold ring where it points (Oct 9: the ring used to hang off the avatar's
-- hand, which swings with the walking animation, so it could not be aimed). The ring fills in, grows and turns cream
-- while a postcard shot would be accepted right now (the shutter's own test: all of a wanted sight in the cone, in range,
-- in clear view, at the right moment), so you know when to pull the trigger.
local aimAtt = Instance.new("Attachment"); aimAtt.Name = "CameraAimPoint"; aimAtt.Parent = workspace.Terrain
local handAtt = Instance.new("Attachment"); handAtt.Name = "CameraAimHand"; handAtt.Parent = workspace.Terrain
local beam = Instance.new("Beam"); beam.Name = "CameraAimBeam"; beam.Attachment0 = handAtt; beam.Attachment1 = aimAtt
beam.Color = ColorSequence.new(GOLD); beam.Transparency = NumberSequence.new(0.35); beam.Width0 = 0.03; beam.Width1 = 0.3
beam.FaceCamera = true; beam.LightEmission = 0.6; beam.LightInfluence = 0; beam.Enabled = false; beam.Parent = workspace.Terrain
local aim = Instance.new("BillboardGui"); aim.Name = "CameraAim"; aim.Size = UDim2.fromOffset(36, 36); aim.AlwaysOnTop = true; aim.LightInfluence = 0
aim.ResetOnSpawn = false; aim.Adornee = aimAtt; aim.Enabled = false; aim.Parent = pg
local ring = Instance.new("Frame"); ring.Size = UDim2.fromScale(1, 1); ring.BackgroundTransparency = 1; ring.BackgroundColor3 = GOLD; ring.Parent = aim
local ringCorner = Instance.new("UICorner"); ringCorner.CornerRadius = UDim.new(0.5, 0); ringCorner.Parent = ring
local ringStroke = stroke(ring, GOLD, 3)
local aimLocked, aimCheckAt = false, 0
local function setRing(locked)
	aim.Size = locked and UDim2.fromOffset(50, 50) or UDim2.fromOffset(36, 36)
	ring.BackgroundTransparency = locked and 0.5 or 1
	ringStroke.Thickness = locked and 5 or 3
	ringStroke.Color = locked and CREAM or GOLD
end
local aimParams = RaycastParams.new(); aimParams.FilterType = Enum.RaycastFilterType.Exclude
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
RunService.RenderStepped:Connect(function()
	if raised then hideHeld(true) end
	local on = holding and vr()
	aim.Enabled = on
	if on then
		local cf = shotCF()
		handAtt.WorldPosition = cf.Position
		aimAtt.WorldPosition = aimHit(cf) or (cf.Position + cf.LookVector * 40)
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
-- VRAimHand "Left": the left trigger takes the photo too (Tool.Activated only listens to the right one)
UIS.InputBegan:Connect(function(input, gp)
	if gp or not (holding and vr()) then return end
	if input.KeyCode == Enum.KeyCode.ButtonL2 and G:GetAttribute("VRAimHand") == "Left" then shoot() end
end)"""
pairs.append((old4, new4))

# 5. the floating VR sign survives a respawn (BillboardGuis in PlayerGui reset by default)
old5 = "vrSign.AlwaysOnTop = true; vrSign.LightInfluence = 0; vrSign.Parent = pg"
assert text.count(old5) == 1
new5 = "vrSign.AlwaysOnTop = true; vrSign.LightInfluence = 0; vrSign.ResetOnSpawn = false; vrSign.Parent = pg"
pairs.append((old5, new5))

# 6. the postcard markers survive a respawn too (markerFor caches them)
old6 = "m.MaxDistance = 3000; m.Enabled = false; m.Parent = pg"
assert text.count(old6) == 1
new6 = "m.MaxDistance = 3000; m.Enabled = false; m.ResetOnSpawn = false; m.Parent = pg"
pairs.append((old6, new6))

# apply to the local copy
patched = text
for i, (old, new) in enumerate(pairs, 1):
    assert patched.count(old) == 1, f"pair {i}: old text found {patched.count(old)} times"
    patched = patched.replace(old, new)
for old, new in pairs:
    assert "]==]" not in old and "]==]" not in new
SRC.write_text(patched, encoding="utf-8")
print(f"patched local copy: {len(patched)} chars (was {ORIG_LEN})")

def lua_long(s):
    return "[==[\n" + s + "]==]"

# the Studio patch
lua = []
lua.append('-- camera/vraim_patch: EDIT mode. VR aim for the camera (Oct 9 2026, Shannon: "you can\'t really aim the shot with the')
lua.append('-- golden circle"). Patches workspace.PhotoGame.CameraClient.Source with exact string finds: the aim is now the tracked')
lua.append("-- controller (gold beam + ring), the ring fills in when a wanted sight is in the shot, two tuning attrs on PhotoGame")
lua.append("-- (VRAimPitch degrees, VRAimHand \"Left\"). Desktop / phone untouched. Original -> ServerStorage.HudBackup.CameraClient_v3_pre_vraim.")
lua.append(f"-- Refuses to run unless the Source is the Oct 8 v3 text ({ORIG_LEN} chars) and every find hits exactly once. Output: \"QQ VRA\".")
lua.append('if game:GetService("RunService"):IsRunning() then warn("QQ VRA ABORT - Play mode") return end')
lua.append('local G = workspace:FindFirstChild("PhotoGame")')
lua.append('local S = G and G:FindFirstChild("CameraClient")')
lua.append('if not (S and S:IsA("LuaSourceContainer")) then warn("QQ VRA ABORT - workspace.PhotoGame.CameraClient not found") return end')
lua.append("local src = S.Source")
lua.append(f'if #src ~= {ORIG_LEN} then warn("QQ VRA ABORT - CameraClient.Source is " .. #src .. " chars, expected {ORIG_LEN} (already patched, or not the Oct 8 v3)") return end')
lua.append("local PAIRS = {")
for old, new in pairs:
    lua.append("\t{" + lua_long(old) + ",\n\t" + lua_long(new) + "},")
lua.append("}")
lua.append("""for i, p in ipairs(PAIRS) do
	local a, b = src:find(p[1], 1, true)
	if not a then warn("QQ VRA ABORT - find " .. i .. " not found; nothing changed") return end
	if src:find(p[1], b + 1, true) then warn("QQ VRA ABORT - find " .. i .. " matches more than once; nothing changed") return end
end
local out = src
for i, p in ipairs(PAIRS) do
	local a, b = out:find(p[1], 1, true)
	out = out:sub(1, a - 1) .. p[2] .. out:sub(b + 1)
end
local f, err = loadstring(out)
if not f then warn("QQ VRA ABORT - patched source does not compile: " .. tostring(err) .. "; nothing changed") return end
local SS = game:GetService("ServerStorage")
local hb = SS:FindFirstChild("HudBackup")
if not hb then hb = Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS end
if not hb:FindFirstChild("CameraClient_v3_pre_vraim") then
	local bk = S:Clone(); bk.Name = "CameraClient_v3_pre_vraim"
	pcall(function() bk.Enabled = false end)
	bk.Parent = hb
end
S.Source = out
print(string.format("QQ VRA DONE: CameraClient patched, %d -> %d chars, %d finds, backup ServerStorage.HudBackup.CameraClient_v3_pre_vraim", #src, #out, #PAIRS))""")
(ROOT / "tools/camera/vraim_patch.lua").write_text("\n".join(lua) + "\n", encoding="utf-8")
print("wrote tools/camera/vraim_patch.lua")

# self-test for the luau CLI: same finds on the original text, prints the result (compare with the patched local copy)
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
(ROOT / "tools/camera/vraim_selftest.lua").write_text("\n".join(st) + "\n", encoding="utf-8")
print("wrote tools/camera/vraim_selftest.lua")
