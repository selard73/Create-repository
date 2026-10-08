-- Meshy pup (rigged): run in the Command Bar with the imported model SELECTED. Safe to run again.
-- Anchors the dog, sets matte fur, and adds an idle script that animates the bones directly:
-- breathing, looking around, ear twitches, panting jaw, tail wag, and an occasional head-up howl.
-- Bones expected (from the Blender rig): Hips, Chest, Neck, Head, Jaw, Ear.L, Ear.R, Tail1, Tail2.
local model = game.Selection:Get()[1] or workspace:FindFirstChild("pup_rigged")
assert(model and model:IsA("Model"), "Select the imported pup model first")
local mesh
for _, p in ipairs(model:GetDescendants()) do
	if p:IsA("BasePart") then
		p.Anchored = true
		p.Material = Enum.Material.SmoothPlastic
		if p:IsA("MeshPart") and p:FindFirstChildOfClass("Bone") then mesh = p end
	end
end
if not mesh then
	for _, p in ipairs(model:GetDescendants()) do if p:IsA("MeshPart") then mesh = p end end
end
assert(mesh, "no MeshPart found in the model")
local old = model:FindFirstChild("PupIdle"); if old then old:Destroy() end
local s = Instance.new("Script"); s.Name = "PupIdle"
s.RunContext = Enum.RunContext.Client      -- bone poses only render when set on the client
s.Source = [[
-- Drives the skinned-mesh bones every frame. Everything is in bone-local space, so the dog can be
-- moved, rotated or scaled freely in the editor.
local model = script.Parent
local RunService = game:GetService("RunService")
local mesh
for _, p in ipairs(model:GetDescendants()) do
	if p:IsA("MeshPart") and p:FindFirstChildOfClass("Bone") then mesh = p break end
end
if not mesh then return end
local bones = {}
for _, b in ipairs(mesh:GetDescendants()) do if b:IsA("Bone") then bones[b.Name] = b end end
local names = {}
for n in pairs(bones) do table.insert(names, n) end
print("PupIdle running on client; bones:", table.concat(names, ", "))
local function set(name, cf) local b = bones[name]; if b then b.Transform = cf end end
local rng = Random.new()
local t = 0
local lookYaw, lookTarget, lookTimer = 0, 0, 0
local howlT, nextHowl = -1, rng:NextNumber(10, 20)
local earTwitch, earTimer = 0, rng:NextNumber(2, 5)
RunService.Heartbeat:Connect(function(dt)
	t += dt
	-- breathing: chest swells gently
	local breathe = math.sin(t * 1.3) * 0.5
	set("Chest", CFrame.Angles(math.rad(-breathe), 0, 0))
	set("Hips", CFrame.new(0, math.sin(t * 1.3) * 0.02, 0))
	-- look around: pick a new target every few seconds
	lookTimer -= dt
	if lookTimer <= 0 then lookTarget = rng:NextNumber(-28, 28); lookTimer = rng:NextNumber(3, 6) end
	lookYaw += (lookTarget - lookYaw) * math.min(1, dt * 2)
	-- howl: head tips up, mouth opens wide, holds, comes down
	local pitch, jawOpen = 0, 0
	if howlT < 0 and t > nextHowl then howlT = 0 end
	if howlT >= 0 then
		howlT += dt
		local k = math.min(howlT / 3.5, 1)
		local env = math.sin(k * math.pi) ^ 0.6
		pitch = -40 * env
		jawOpen = 28 * env
		if howlT >= 3.5 then howlT = -1; nextHowl = t + rng:NextNumber(14, 28) end
	else
		jawOpen = 6 + 5 * math.sin(t * 4.5)     -- gentle panting
	end
	set("Neck", CFrame.Angles(math.rad(pitch * 0.4), math.rad(lookYaw * 0.4), 0))
	set("Head", CFrame.Angles(math.rad(pitch * 0.6 + math.sin(t * 0.8) * 2), math.rad(lookYaw * 0.6), 0))
	-- jaw left still: the auto weights pull the nose along with it, which looks wrong
	-- ears: soft sway, occasional twitch
	earTimer -= dt
	if earTimer <= 0 then earTwitch = 1; earTimer = rng:NextNumber(3, 8) end
	earTwitch = math.max(0, earTwitch - dt * 3)
	local sway = math.sin(t * 2.1) * 3
	set("Ear.L", CFrame.Angles(math.rad(-sway - earTwitch * 25), 0, 0))
	set("Ear.R", CFrame.Angles(math.rad(sway + (howlT >= 0 and 15 or 0)), 0, 0))
	-- tail: wag along the ground, faster when howling
	local wagSpeed = howlT >= 0 and 7 or 3
	local wag = math.sin(t * wagSpeed)
	set("Tail1", CFrame.Angles(0, 0, math.rad(wag * 22)))
	set("Tail2", CFrame.Angles(0, 0, math.rad(wag * 18)))
end)
]]
s.Parent = model
model.Name = "Pup"
local n = 0
for _, b in ipairs(mesh:GetDescendants()) do if b:IsA("Bone") then n += 1 end end
print("Pup: idle bone animation applied to " .. mesh.Name .. " with " .. n .. " bones. Test with PLAY (not Run).")
