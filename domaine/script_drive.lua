-- TractorDrive (server, inside the tractor): seats the player from the prompt, hands the tractor to the driver's client
-- while it is being driven, and parks it (anchored, solid) when they get off. The driving itself is in TractorClient.
local Players = game:GetService("Players")
local model = script.Parent
local seat = model:WaitForChild("DriverSeat")
local chassis = model:WaitForChild("Chassis")
local lift = chassis:WaitForChild("Float")
local home = chassis.CFrame
local parts = {}
for _, p in ipairs(model:GetDescendants()) do
	if p:IsA("BasePart") and p ~= chassis and p ~= seat then table.insert(parts, p) end
end
local prompt = seat:FindFirstChildOfClass("ProximityPrompt")
local lastDriver
local function stepOff()
	-- put the driver on the ground beside the tractor: standing up on the saddle leaves them wedged under the canopy
	local char = lastDriver and lastDriver.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (char and hum and hum.Health > 0 and char:FindFirstChild("HumanoidRootPart")) then return end
	local cf = chassis.CFrame
	local at = cf.Position - cf.RightVector * 4.8 - cf.LookVector * 1.3
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {model, char}
	local hit = workspace:Raycast(at + Vector3.new(0, 8, 0), Vector3.new(0, -40, 0), rp)
	local y = (hit and hit.Position.Y or cf.Position.Y) + 3.2
	local stand = Vector3.new(at.X, y, at.Z)
	char:PivotTo(CFrame.lookAt(stand, stand + Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)))
end
local function park()
	chassis.Anchored = true
	lift.Enabled = false
	for _, p in ipairs(parts) do p.CanCollide = true end
	if prompt then prompt.Enabled = true end
end
if prompt then
	prompt.Triggered:Connect(function(player)
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 and not seat.Occupant and hum.SeatPart == nil then seat:Sit(hum) end
	end)
end
seat:GetPropertyChangedSignal("Occupant"):Connect(function()
	local hum = seat.Occupant
	local player = hum and Players:GetPlayerFromCharacter(hum.Parent)
	if player then
		lastDriver = player
		if prompt then prompt.Enabled = false end
		for _, p in ipairs(parts) do p.CanCollide = false end           -- the body must not fight the ground while it is moved
		chassis.Anchored = false
		lift.Force = Vector3.new(0, chassis.AssemblyMass * workspace.Gravity, 0)   -- hold it up: gravity is not part of the drive
		lift.Enabled = true
		local root = chassis.AssemblyRootPart or chassis
		pcall(function() root:SetNetworkOwner(player) end)
	else
		stepOff()
		park()
	end
end)
task.spawn(function()
	while true do
		task.wait(2)
		if not chassis.Anchored and not seat.Occupant then park() end
		local p = chassis.Position
		if p.Y < home.Position.Y - 40 or (p - home.Position).Magnitude > 700 then     -- lost it somehow: bring it home
			park(); model:PivotTo(home)
		end
	end
end)
