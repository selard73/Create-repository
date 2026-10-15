-- Keep unfinished Japan inaccessible to ordinary players, including forced entry.
local Players = game:GetService('Players')
local Access = require(game.ServerScriptService:WaitForChild('JapanPreviewAccess'))
local function watch(player)
	player:SetAttribute('JapanPreviewAllowed', Access.IsAllowed(player)) -- presentation only
end
Players.PlayerAdded:Connect(watch)
for _,player in ipairs(Players:GetPlayers()) do watch(player) end
while true do
	task.wait(.2)
	for _,player in ipairs(Players:GetPlayers()) do
		local allowed = Access.IsAllowed(player)
		if player:GetAttribute('JapanPreviewAllowed') ~= allowed then player:SetAttribute('JapanPreviewAllowed', allowed) end
		local character = player.Character
		local root = character and character:FindFirstChild('HumanoidRootPart')
		local humanoid = character and character:FindFirstChildOfClass('Humanoid')
		if not allowed and root and Access.IsJapan(root.Position) then
			local spawn = workspace:FindFirstChild('Spawn_'..tostring(player:GetAttribute('Dais') or 'forest')) or workspace:FindFirstChild('Spawn_forest')
			if spawn then
				if humanoid then
					local seat=humanoid.SeatPart
					if seat then local weld=seat:FindFirstChild('SeatWeld');if weld then weld:Destroy() end end
					humanoid.Sit=false
				end
				character:PivotTo(spawn.CFrame+CFrame.new(0,4,0).Position)
				root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
			end
		end
	end
end
