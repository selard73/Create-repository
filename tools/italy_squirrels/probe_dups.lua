-- Oct 5 2026 read-only: every copy of the gelato / fishmonger models anywhere
for _,d in ipairs(game:GetDescendants()) do
	if d:IsA('Model') and (d.Name:find('gelato_squirrel') or d.Name:find('fishmonger_squirrel')) then
		local cm=d:FindFirstChild('Squirrel')
		warn('QD2@',d:GetFullName(),cm and cm.Position,cm and cm:GetAttribute('ColorTexture') and 'hasAttr' or 'noAttr', cm and cm.TextureID)
	end
end
warn('QD2@CAM',workspace.CurrentCamera.CFrame.Position)
