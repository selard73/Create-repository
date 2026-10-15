-- Server-only identity policy. Display names and client attributes never grant access.
local Access = {}
Access.OwnerUserId = 9611145467 -- @CozyGameMode, display name SelBell; confirmed by the owner.
function Access.IsAllowed(player)
	return player ~= nil and player.UserId == Access.OwnerUserId
end
function Access.IsJapan(position)
	return position.X > 4750 and position.X < 7950 and position.Z > -1550 and position.Z < 850
end
function Access.CanUsePrompt(player, prompt, distance)
	if not Access.IsAllowed(player) or not prompt.Enabled then return false end
	local character = player.Character
	local root = character and character:FindFirstChild('HumanoidRootPart')
	local humanoid = character and character:FindFirstChildOfClass('Humanoid')
	local parent = prompt.Parent
	return root ~= nil and humanoid ~= nil and humanoid.Health > 0
		and parent ~= nil and parent:IsA('BasePart') and (root.Position-parent.Position).Magnitude <= distance
end
return Access
