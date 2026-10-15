-- Server-only identity policy. Display names and client attributes never grant access.
local Access = {}
Access.OwnerUserId = 9611145467 -- @CozyGameMode, display name SelBell; confirmed by the owner.
-- JAPANGUEST1_20261015: guests on the private preview (Shannon). Add more in Properties: this module's attribute GuestUserIds, ids comma-separated.
Access.GuestUserIds = {[3121141] = true}   -- Shademade
function Access.IsAllowed(player)
	if player == nil then return false end
	if player.UserId == Access.OwnerUserId or Access.GuestUserIds[player.UserId] then return true end
	local extra = script:GetAttribute("GuestUserIds")
	if type(extra) == "string" then for id in extra:gmatch("%d+") do if tonumber(id) == player.UserId then return true end end end
	return false
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
