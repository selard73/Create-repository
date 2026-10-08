"""One-off patch: add the sitting-pup swap to make_standing_scripts.py."""
from pathlib import Path
import re
p = Path(__file__).parent / "make_standing_scripts.py"
s = p.read_text(encoding="utf-8")

def rep(old, new):
    global s
    assert old in s, old[:60]
    s = s.replace(old, new)

# ---- BRAIN: find the sitting pup ----
rep("""local pivot0 = model:GetPivot()
local rot0 = pivot0.Rotation
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances = {model}""",
"""-- the sitting pup: any other rigged mesh with a Hips bone but no leg bones (the original Meshy sit)
local sitMesh
for _, p in ipairs(workspace:GetDescendants()) do
	if p:IsA("MeshPart") and p ~= mesh and p:FindFirstChild("Hips", true) and not p:FindFirstChild("FrontUpper.L", true)
		and not p:IsDescendantOf(model) then sitMesh = p end
end
local sitModel = sitMesh and (sitMesh:FindFirstAncestorOfClass("Model") or sitMesh)
if sitModel then
	for _, p in ipairs(sitModel:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true end end
	if sitMesh.Size.Y > 20 then sitModel:ScaleTo(sitModel:GetScale() * TARGET_HEIGHT / sitMesh.Size.Y) end
	sitModel:SetAttribute("TractorTarget", false)
	print("PupBrain: sitting pup found:", sitModel:GetFullName())
else
	warn("PupBrain: no sitting pup found in the Workspace; he will only stand and walk")
end
local FADE_TIME = 0.25

local pivot0 = model:GetPivot()
local rot0 = pivot0.Rotation
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances = sitModel and {model, sitModel} or {model}""")

rep("""local fwd0 = Vector3.new(0, 0, -1)
if bones.Hips and bones.Head then
	local f = bones.Head.WorldPosition - bones.Hips.WorldPosition
	f = Vector3.new(f.X, 0, f.Z)
	if f.Magnitude > 0.1 then fwd0 = f.Unit end
end
local yawDelta = 0
""",
"""local fwd0 = Vector3.new(0, 0, -1)
if bones.Hips and bones.Head then
	local f = bones.Head.WorldPosition - bones.Hips.WorldPosition
	f = Vector3.new(f.X, 0, f.Z)
	if f.Magnitude > 0.1 then fwd0 = f.Unit end
end
local yawDelta = 0

-- sitting pup: its own heading and foot height, so it can be dropped in wherever the standing dog is
local sitBones, sitRot0, sitFwd0, sitFoot = {}, nil, Vector3.new(0, 0, -1), 0
local function setVisible(m, alpha, solid)   -- alpha 0 = fully shown, 1 = hidden
	if not m then return end
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then p.Transparency = alpha; p.CanCollide = solid; p.CanQuery = solid; p.CanTouch = solid end
	end
end
if sitModel then
	for _, b in ipairs(sitMesh:GetDescendants()) do if b:IsA("Bone") then sitBones[b.Name] = b end end
	local sp = sitModel:GetPivot()
	sitRot0 = sp.Rotation
	if sitBones.Hips and sitBones.Head then
		local f = sitBones.Head.WorldPosition - sitBones.Hips.WorldPosition
		f = Vector3.new(f.X, 0, f.Z)
		if f.Magnitude > 0.1 then sitFwd0 = f.Unit end
	end
	local sg = groundAt(sp.Position.X, sp.Position.Z, sp.Position.Y) or (sp.Position.Y - 1.75)
	sitFoot = sp.Position.Y - sg
	setVisible(sitModel, 1, false)
end
local fade = 0            -- 0 = standing dog shown, 1 = sitting pup shown
local function placeSitPup(pos, gy)
	if not sitModel then return end
	local nose = CFrame.Angles(0, yawDelta, 0):VectorToWorldSpace(fwd0)
	local turn = math.atan2(sitFwd0.X * nose.Z - sitFwd0.Z * nose.X, sitFwd0.X * nose.X + sitFwd0.Z * nose.Z)
	sitModel:PivotTo(CFrame.new(pos.X, gy + sitFoot, pos.Z) * CFrame.Angles(0, -turn, 0) * sitRot0)
end
""")

rep("""	if bones.Head then top = bones.Head.WorldPosition + Vector3.new(0, 1.4, 0) end
	att.WorldPosition = top""",
"""	if bones.Head then top = bones.Head.WorldPosition + Vector3.new(0, 1.4, 0) end
	if fade > 0.5 and sitBones.Head then top = sitBones.Head.WorldPosition + Vector3.new(0, 1.4, 0) end
	att.WorldPosition = top""")

rep("""	if model:GetAttribute("Moving") ~= moving then model:SetAttribute("Moving", moving) end
end)""",
"""	if model:GetAttribute("Moving") ~= moving then model:SetAttribute("Moving", moving) end
	-- swap: crossfade between the standing dog and the sitting pup
	if sitModel then
		local target = model:GetAttribute("Sitting") and 1 or 0
		local nf = fade + math.clamp(target - fade, -dt / FADE_TIME, dt / FADE_TIME)
		if nf ~= fade or target == 1 then
			local p = model:GetPivot().Position
			if nf > 0 then placeSitPup(p, groundY - footOffset) end
			if nf ~= fade then
				fade = nf
				setVisible(model, fade, fade < 0.5)
				setVisible(sitModel, 1 - fade, fade >= 0.5)
				placeAttachment()
			end
		end
	end
end)""")

# ---- ANIM: standing dog no longer poses a sit ----
rep("	sit += ((sitting and 1 or 0) - sit) * math.min(1, dt * 3)",
    "	sit += ((sitting and 1 or 0) - sit) * math.min(1, dt * 3)\n	local sp = 0        -- the sit pose is handled by swapping to the sitting pup; keep him standing underneath")
a = s.index("ANIM = r'''"); b = s.index("'''", a + 12)
anim = s[a:b]
anim2 = re.sub(r"\* sit\b(?! blend)", "* sp", anim)
s = s[:a] + anim2 + s[b:]

# ---- SITANIM ----
SITANIM_SRC = r'''
SITANIM = r"""
-- SitAnim (client): idle for the sitting pup (breathing, look-around, ears, tail, howl). Runs only while he is shown.
local RunService = game:GetService("RunService")
local function findSit()
	for _, p in ipairs(workspace:GetDescendants()) do
		if p:IsA("MeshPart") and p:FindFirstChild("Hips", true) and not p:FindFirstChild("FrontUpper.L", true) then return p end
	end
end
local mesh = findSit()
local waited = 0
while not mesh and waited < 15 do task.wait(0.5); waited += 0.5; mesh = findSit() end
if not mesh then return end
local standing
for _, p in ipairs(workspace:GetDescendants()) do
	if p:IsA("MeshPart") and p:FindFirstChild("FrontUpper.L", true) then standing = p:FindFirstAncestorOfClass("Model") or p end
end
local bones = {}
for _, b in ipairs(mesh:GetDescendants()) do if b:IsA("Bone") then bones[b.Name] = b end end
local function set(name, cf) local b = bones[name]; if b then b.Transform = cf end end
local rng = Random.new()
local t = 0
local lookYaw, lookTarget, lookTimer = 0, 0, 0
local howlT, nextHowl = -1, rng:NextNumber(10, 20)
local earTwitch, earTimer = 0, rng:NextNumber(2, 5)
RunService.Heartbeat:Connect(function(dt)
	t += dt
	if mesh.Transparency > 0.95 then return end     -- hidden: skip
	local following = standing and standing:GetAttribute("Following") == true
	local breathe = math.sin(t * 1.3) * 0.5
	set("Chest", CFrame.Angles(math.rad(-breathe), 0, 0))
	set("Hips", CFrame.new(0, math.sin(t * 1.3) * 0.02, 0))
	lookTimer -= dt
	if lookTimer <= 0 then lookTarget = following and 0 or rng:NextNumber(-28, 28); lookTimer = rng:NextNumber(3, 6) end
	lookYaw += (lookTarget - lookYaw) * math.min(1, dt * 2)
	local pitch = 0
	if howlT < 0 and t > nextHowl then howlT = 0 end
	if howlT >= 0 then
		howlT += dt
		local k = math.min(howlT / 3.5, 1)
		pitch = -40 * math.sin(k * math.pi) ^ 0.6
		if howlT >= 3.5 then howlT = -1; nextHowl = t + rng:NextNumber(14, 28) end
	end
	set("Neck", CFrame.Angles(math.rad(pitch * 0.4), math.rad(lookYaw * 0.4), 0))
	set("Head", CFrame.Angles(math.rad(pitch * 0.6 + math.sin(t * 0.8) * 2), math.rad(lookYaw * 0.6), 0))
	earTimer -= dt
	if earTimer <= 0 then earTwitch = 1; earTimer = rng:NextNumber(3, 8) end
	earTwitch = math.max(0, earTwitch - dt * 3)
	local sway = math.sin(t * 2.1) * 3
	set("Ear.L", CFrame.Angles(math.rad(-sway - earTwitch * 25), 0, 0))
	set("Ear.R", CFrame.Angles(math.rad(sway + (howlT >= 0 and 15 or 0)), 0, 0))
	local wagSpeed = howlT >= 0 and 7 or 3
	local wag = math.sin(t * wagSpeed)
	set("Tail1", CFrame.Angles(0, 0, math.rad(wag * 22)))
	set("Tail2", CFrame.Angles(0, 0, math.rad(wag * 18)))
end)
print("SitAnim running on client for", mesh:GetFullName())
"""
'''
rep("\ndef script_item(", SITANIM_SRC + "\ndef script_item(")
rep('{script_item("PupBrain", BRAIN, 1, "RBX1")}{script_item("PupAnim", ANIM, 2, "RBX2")}',
    '{script_item("PupBrain", BRAIN, 1, "RBX1")}{script_item("PupAnim", ANIM, 2, "RBX2")}{script_item("SitAnim", SITANIM, 2, "RBX3")}')
p.write_text(s, encoding="utf-8")
print("patched")
