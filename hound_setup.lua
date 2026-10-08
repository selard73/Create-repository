-- Old hound: run in the Command Bar with the imported model SELECTED. Safe to run again.
-- Matte fur, glossy nose and eyes, and an idle script: breathing, tail wag, looking around, a howl now and then.
local model = game.Selection:Get()[1] or workspace:FindFirstChild("hound")
assert(model and model:IsA("Model"), "Select the imported hound model first")
for _, p in ipairs(model:GetDescendants()) do
	if p:IsA("BasePart") then
		p.Anchored = true
		p.CanCollide = (p.Name == "HoundBody" or p.Name == "HoundHead")
		if p.Name == "Nose" or p.Name:match("^EyeWhite") or p.Name:match("^Iris") or p.Name:match("^Pupil") then
			p.Material = Enum.Material.Glass; p.Reflectance = 0
		elseif p.Name:match("Pivot") then
			p.Transparency = 1; p.CanCollide = false
		elseif p.Name:match("^Collar") then
			p.Material = Enum.Material.SmoothPlastic
		else
			p.Material = Enum.Material.Fabric
		end
	end
end
local old = model:FindFirstChild("HoundIdle"); if old then old:Destroy() end
local s = Instance.new("Script"); s.Name = "HoundIdle"
s.Source = [[
local model = script.Parent
local RunService = game:GetService("RunService")
local body = model:FindFirstChild("HoundBody")
if not body then return end
local HEAD = {"^HoundHead", "^Nose", "^Tongue", "^Eye", "^Iris", "^Pupil"}
local function isHead(n) for _, k in ipairs(HEAD) do if n:match(k) then return true end end return false end
local rest, head, tail = {}, {}, {}
for _, p in ipairs(model:GetDescendants()) do
	if p:IsA("BasePart") and p ~= body then
		local off = body.CFrame:ToObjectSpace(p.CFrame)
		if p.Name == "HoundTail" then table.insert(tail, {p, off})
		elseif isHead(p.Name) then table.insert(head, {p, off})
		else table.insert(rest, {p, off}) end
	end
end
local home = body.CFrame
local np, tpv = model:FindFirstChild("NeckPivot"), model:FindFirstChild("TailPivot")
local neckPivot = home:ToObjectSpace(CFrame.new(np and np.Position or (body.Position + Vector3.new(1.9, 0.7, 0))))
local tailPivot = home:ToObjectSpace(CFrame.new(tpv and tpv.Position or (body.Position - Vector3.new(2.2, 0, 0))))
local rng = Random.new()
local t, nextHowl, howlT = 0, rng:NextNumber(8, 16), -1
local lookYaw, lookTarget, lookTimer = 0, 0, 0
RunService.Heartbeat:Connect(function(dt)
	t += dt
	local breathe = math.sin(t * 1.0) * 0.03
	local base = home * CFrame.new(0, breathe, 0)
	body.CFrame = base
	for _, e in ipairs(rest) do e[1].CFrame = base * e[2] end
	lookTimer -= dt
	if lookTimer <= 0 then lookTarget = rng:NextNumber(-0.3, 0.3); lookTimer = rng:NextNumber(3, 7) end
	lookYaw += (lookTarget - lookYaw) * math.min(1, dt * 1.5)
	local pitch = 0
	if howlT < 0 and t > nextHowl then howlT = 0 end
	if howlT >= 0 then
		howlT += dt
		local k = math.min(howlT / 3.2, 1)
		pitch = -math.rad(34) * math.sin(k * math.pi) ^ 0.7
		if howlT >= 3.2 then howlT = -1; nextHowl = t + rng:NextNumber(12, 25) end
	end
	local headCF = neckPivot * CFrame.Angles(0, lookYaw, pitch) * neckPivot:Inverse()
	for _, e in ipairs(head) do e[1].CFrame = base * headCF * e[2] end
	local wag = math.sin(t * (howlT >= 0 and 5 or 2)) * math.rad(18)
	local swing = tailPivot * CFrame.Angles(wag, 0, 0) * tailPivot:Inverse()
	for _, e in ipairs(tail) do e[1].CFrame = base * swing * e[2] end
end)
]]
s.Parent = model
model.Name = "OldHound"
print("Old hound: matte fur and idle motion applied")
